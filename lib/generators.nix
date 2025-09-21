{ lib, pkgs }:

rec {
  # Generate Grafana configuration
  grafanaConfig =
    { adminPassword ? "admin"
    , port ? 3000
    , datasources ? [ ]
    , dashboards ? [ ]
    , plugins ? [ ]
    , theme ? "light"
    , orgName ? "Main Org."
    , ...
    }@args:
    let
      cfg = {
        server = {
          http_port = port;
          root_url = "http://localhost:${toString port}";
        };

        security = {
          admin_password = adminPassword;
        };

        users = {
          allow_sign_up = false;
          default_theme = theme;
        };

        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
        };
      } // lib.optionalAttrs (args ? extraConfig) args.extraConfig;

      datasourceConfigs = map
        (ds: {
          name = ds.name;
          type = ds.type;
          url = ds.url;
          access = ds.access or "proxy";
          isDefault = ds.isDefault or false;
        })
        datasources;

    in
    {
      configFile = pkgs.writeText "grafana.ini" (lib.generators.toINI { } cfg);

      provisioningDir = pkgs.runCommand "grafana-provisioning" { } ''
                mkdir -p $out/{datasources,dashboards}

                # Datasources
                cat > $out/datasources/default.yml <<EOF
                apiVersion: 1
                datasources:
                ${lib.generators.toYAML { } datasourceConfigs}
                EOF

                # Dashboards
                ${lib.optionalString (dashboards != [ ]) ''
                  mkdir -p $out/dashboards/default
                  ${lib.concatMapStringsSep "\n"
                    (dashboard: "cp ${dashboard} $out/dashboards/default/")
                    dashboards}

                  # Generate dashboard provider config using Nix
                  cat > $out/dashboards/default.yml <<EOF
        ${lib.generators.toYAML {} {
          apiVersion = 1;
          providers = [{
            name = "default";
            orgId = 1;
            folder = "";
            type = "file";
            options = {
              path = "$out/dashboards/default";
            };
          }];
        }}EOF
                ''}
      '';

      inherit datasources dashboards plugins;
    };

  # Generate Prometheus configuration
  prometheusConfig =
    { port ? 9090
    , retention ? "15d"
    , scrapeInterval ? "15s"
    , evaluationInterval ? "15s"
    , scrapeConfigs ? [ ]
    , alertingRules ? [ ]
    , ...
    }@args:
    let
      globalConfig = {
        scrape_interval = scrapeInterval;
        evaluation_interval = evaluationInterval;
      };

      defaultScrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [{ targets = [ "localhost:${toString port}" ]; }];
        }
      ];

      allScrapeConfigs = defaultScrapeConfigs ++ scrapeConfigs;

      config = {
        global = globalConfig;
        scrape_configs = allScrapeConfigs;
      } // lib.optionalAttrs (alertingRules != [ ]) {
        rule_files = map toString alertingRules;
      };

    in
    {
      configFile = pkgs.writeText "prometheus.yml" (lib.generators.toYAML { } config);
      inherit retention scrapeConfigs alertingRules;
    };

  # Generate Loki configuration
  lokiConfig =
    { port ? 3100
    , retentionPeriod ? "744h"
    , # 31 days
      ...
    }@args:
    let
      config = {
        server = {
          http_listen_port = port;
        };

        auth_enabled = false;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore = { store = "inmemory"; };
              replication_factor = 1;
            };
            final_sleep = "0s";
          };
          chunk_idle_period = "5m";
          chunk_retain_period = "30s";
          max_transfer_retries = 0;
        };

        schema_config = {
          configs = [{
            from = "2020-10-24";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "/tmp/loki/boltdb-shipper-active";
            cache_location = "/tmp/loki/boltdb-shipper-cache";
            shared_store = "filesystem";
          };

          filesystem = {
            directory = "/tmp/loki/chunks";
          };
        };

        limits_config = {
          enforce_metric_name = false;
          reject_old_samples = true;
          reject_old_samples_max_age = retentionPeriod;
        };

        chunk_store_config = {
          max_look_back_period = retentionPeriod;
        };

        table_manager = {
          retention_deletes_enabled = true;
          retention_period = retentionPeriod;
        };
      };

    in
    {
      configFile = pkgs.writeText "loki.yml" (lib.generators.toYAML { } config);
      inherit retentionPeriod;
    };

  # Generate Tempo configuration
  tempoConfig =
    { port ? 3200
    , retentionDuration ? "240h"
    , # 10 days
      ...
    }@args:
    let
      config = {
        server = {
          http_listen_port = port;
        };

        distributor = {
          receivers = {
            jaeger = {
              protocols = {
                thrift_http = {
                  endpoint = "0.0.0.0:14268";
                };
                grpc = {
                  endpoint = "0.0.0.0:14250";
                };
              };
            };
            otlp = {
              protocols = {
                http = {
                  endpoint = "0.0.0.0:4318";
                };
                grpc = {
                  endpoint = "0.0.0.0:4317";
                };
              };
            };
          };
        };

        ingester = {
          trace_idle_period = "10s";
          max_block_bytes = 1048576;
          max_block_duration = "5m";
        };

        compactor = {
          compaction = {
            compaction_window = "1h";
            max_compaction_objects = 1000000;
            block_retention = retentionDuration;
          };
        };

        storage = {
          trace = {
            backend = "local";
            local = {
              path = "/tmp/tempo/traces";
            };
          };
        };
      };

    in
    {
      configFile = pkgs.writeText "tempo.yml" (lib.generators.toYAML { } config);
      inherit retentionDuration;
    };

  # Generate Alloy (Grafana Agent) configuration
  alloyConfig =
    { port ? 12345
    , prometheusUrl ? "http://localhost:9090"
    , lokiUrl ? "http://localhost:3100"
    , tempoUrl ? "http://localhost:3200"
    , scrapeInterval ? "15s"
    , logPaths ? [ "/var/log/*.log" ]
    , ...
    }@args:
    let
      config = ''
        // Prometheus metrics collection
        prometheus.scrape "local_metrics" {
          targets = [
            {"__address__" = "localhost:${toString port}"},
          ]
          scrape_interval = "${scrapeInterval}"
          forward_to = [prometheus.remote_write.default.receiver]
        }

        // Remote write metrics to Prometheus
        prometheus.remote_write "default" {
          endpoint {
            url = "${prometheusUrl}/api/v1/write"
          }
        }

        // Local file discovery for logs
        local.file_match "application_logs" {
          path_targets = [
            ${lib.concatMapStringsSep ",\n    " (path: ''"${path}"'') logPaths}
          ]
        }

        // Process and forward logs to Loki
        loki.source.file "application_logs" {
          targets    = local.file_match.application_logs.targets
          forward_to = [loki.write.default.receiver]
        }

        // Write logs to Loki
        loki.write "default" {
          endpoint {
            url = "${lokiUrl}/loki/api/v1/push"
          }
        }

        // OpenTelemetry receiver for traces
        otelcol.receiver.otlp "default" {
          grpc {
            endpoint = "0.0.0.0:4317"
          }

          http {
            endpoint = "0.0.0.0:4318"
          }

          output {
            traces = [otelcol.exporter.otlp.default.input]
          }
        }

        // Export traces to Tempo
        otelcol.exporter.otlp "default" {
          client {
            endpoint = "${tempoUrl}"
            tls {
              insecure = true
            }
          }
        }

        // HTTP server for Alloy UI
        logging {
          level = "info"
        }
      '';
    in
    {
      configFile = pkgs.writeText "alloy.alloy" config;
      inherit prometheusUrl lokiUrl tempoUrl scrapeInterval logPaths;
    };
}
