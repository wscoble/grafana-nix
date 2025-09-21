{
  description = "Custom Grafana stack configuration example";

  inputs = {
    grafana-nix.url = "https://flakehub.com/f/wscoble/grafana-nix";
    nixpkgs.follows = "grafana-nix/nixpkgs";
  };

  outputs = { self, grafana-nix, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        # Custom stack with overridden configuration
        default = grafana-nix.lib.buildStack {
          # Grafana customization
          grafana = {
            adminPassword = "secure-password-change-me";
            port = 3000;
            theme = "dark";
            orgName = "My Organization";

            # Custom data sources
            datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                url = "http://localhost:9090";
                isDefault = true;
              }
              {
                name = "Loki";
                type = "loki";
                url = "http://localhost:3100";
              }
              {
                name = "Tempo";
                type = "tempo";
                url = "http://localhost:3200";
              }
            ];

            # Custom dashboards
            dashboards = [
              ./dashboards/system-overview.json
              ./dashboards/application-metrics.json
            ];
          };

          # Prometheus customization
          prometheus = {
            port = 9090;
            retention = "30d";
            evaluationInterval = "15s";
            scrapeInterval = "15s";

            # Custom scrape configs
            scrapeConfigs = [
              {
                job_name = "prometheus";
                static_configs = [
                  { targets = [ "localhost:9090" ]; }
                ];
              }
              {
                job_name = "grafana";
                static_configs = [
                  { targets = [ "localhost:3000" ]; }
                ];
              }
              {
                job_name = "node-exporter";
                static_configs = [
                  { targets = [ "localhost:9100" ]; }
                ];
              }
            ];

            # Alert rules
            alertingRules = [
              ./alerts/critical.yml
              ./alerts/warnings.yml
            ];
          };

          # Loki customization
          loki = {
            port = 3100;
            retentionPeriod = "744h"; # 31 days

            # Custom schema config
            schemaConfig = {
              configs = [{
                from = "2023-01-01";
                store = "boltdb-shipper";
                object_store = "filesystem";
                schema = "v11";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }];
            };
          };

          # Tempo customization
          tempo = {
            port = 3200;
            retentionDuration = "240h"; # 10 days

            # Distributor config
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
          };
        };

        # Export individual components with custom configs
        grafana = self.packages.${system}.default.grafana;
        prometheus = self.packages.${system}.default.prometheus;
        loki = self.packages.${system}.default.loki;
        tempo = self.packages.${system}.default.tempo;
      };

      # Custom apps
      apps.${system} = {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/grafana-stack";
        };

        # Individual service apps
        grafana = {
          type = "app";
          program = "${self.packages.${system}.grafana}/bin/grafana-server";
        };

        prometheus = {
          type = "app";
          program = "${self.packages.${system}.prometheus}/bin/prometheus";
        };
      };

      # Enhanced development shell
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Core observability stack
          grafana
          prometheus
          loki
          tempo

          # Exporters and tools
          node_exporter
          blackbox_exporter
          alertmanager

          # Development and debugging tools
          curl
          jq
          yq
          dig
          netcat
          htop

          # Testing tools
          k6
          apache-bench
        ];

        shellHook = ''
          echo "🔧 Custom Grafana Stack Development Environment"
          echo "=============================================="
          echo ""
          echo "🚀 Quick start:"
          echo "  nix run .                    # Start custom stack"
          echo "  nix run .#grafana           # Start only Grafana"
          echo "  nix run .#prometheus        # Start only Prometheus"
          echo ""
          echo "🔍 URLs (after starting):"
          echo "  Grafana:    http://localhost:3000 (admin/secure-password-change-me)"
          echo "  Prometheus: http://localhost:9090"
          echo "  Loki:       http://localhost:3100"
          echo "  Tempo:      http://localhost:3200"
          echo ""
          echo "🛠️  Available tools:"
          echo "  prometheus --help           # Prometheus CLI"
          echo "  grafana-cli --help          # Grafana CLI"
          echo "  curl, jq, yq               # HTTP and data tools"
          echo "  k6, ab                     # Load testing"
          echo ""
          echo "📊 Example queries:"
          echo "  curl http://localhost:9090/api/v1/query?query=up"
          echo "  curl http://localhost:3100/ready"
        '';
      };
    };
}
