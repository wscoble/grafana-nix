{ lib }:

with lib.types;

rec {
  # Port number type
  port = addCheck int (x: x > 0 && x < 65536);

  # Duration type (for Prometheus/Loki retention)
  duration = str;

  # Datasource type for Grafana
  datasource = submodule {
    options = {
      name = mkOption {
        type = str;
        description = "Name of the datasource";
      };

      type = mkOption {
        type = enum [ "prometheus" "loki" "tempo" "influxdb" "elasticsearch" ];
        description = "Type of the datasource";
      };

      url = mkOption {
        type = str;
        description = "URL of the datasource";
      };

      access = mkOption {
        type = enum [ "proxy" "direct" ];
        default = "proxy";
        description = "Access mode for the datasource";
      };

      isDefault = mkOption {
        type = bool;
        default = false;
        description = "Whether this is the default datasource";
      };
    };
  };

  # Scrape config type for Prometheus
  scrapeConfig = submodule {
    options = {
      job_name = mkOption {
        type = str;
        description = "Job name for the scrape config";
      };

      static_configs = mkOption {
        type = listOf (submodule {
          options = {
            targets = mkOption {
              type = listOf str;
              description = "List of targets to scrape";
            };
          };
        });
        default = [ ];
        description = "Static configuration for targets";
      };

      scrape_interval = mkOption {
        type = nullOr duration;
        default = null;
        description = "Scrape interval override";
      };
    };
  };

  # Grafana configuration type
  grafanaConfig = submodule {
    options = {
      port = mkOption {
        type = port;
        default = 3000;
        description = "Port for Grafana to listen on";
      };

      adminPassword = mkOption {
        type = str;
        default = "admin";
        description = "Admin password for Grafana";
      };

      theme = mkOption {
        type = enum [ "dark" "light" ];
        default = "dark";
        description = "Default theme for Grafana";
      };

      datasources = mkOption {
        type = listOf datasource;
        default = [ ];
        description = "List of datasources to configure";
      };

      dashboards = mkOption {
        type = listOf path;
        default = [ ];
        description = "List of dashboard JSON files";
      };

      plugins = mkOption {
        type = listOf package;
        default = [ ];
        description = "List of Grafana plugins to install";
      };
    };
  };

  # Prometheus configuration type
  prometheusConfig = submodule {
    options = {
      port = mkOption {
        type = port;
        default = 9090;
        description = "Port for Prometheus to listen on";
      };

      retention = mkOption {
        type = duration;
        default = "15d";
        description = "Data retention period";
      };

      scrapeInterval = mkOption {
        type = duration;
        default = "15s";
        description = "Default scrape interval";
      };

      evaluationInterval = mkOption {
        type = duration;
        default = "15s";
        description = "Rule evaluation interval";
      };

      scrapeConfigs = mkOption {
        type = listOf scrapeConfig;
        default = [ ];
        description = "List of scrape configurations";
      };

      alertingRules = mkOption {
        type = listOf path;
        default = [ ];
        description = "List of alerting rule files";
      };
    };
  };
}
