{ config, pkgs, lib, ... }:

let
  cfg = config.services.grafana-stack;
  grafanaLib = import ../lib { inherit lib pkgs; };
in
{
  options.services.grafana-stack = {
    enable = lib.mkEnableOption "Grafana observability stack";

    package = lib.mkOption {
      type = lib.types.package;
      default = grafanaLib.buildStack cfg.config;
      description = "The Grafana stack package to use";
    };

    config = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Configuration for the Grafana stack";
      example = {
        grafana.adminPassword = "secure-password";
        prometheus.retention = "30d";
      };
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "grafana-stack";
      description = "User to run the services as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "grafana-stack";
      description = "Group to run the services as";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/grafana-stack";
      description = "Directory to store data";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    # Systemd services
    systemd.services = {
      grafana-stack = {
        description = "Grafana Observability Stack";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "forking";
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${cfg.package}/bin/grafana-stack ${cfg.dataDir}";
          Restart = "always";
          RestartSec = "10s";

          # Security settings
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ cfg.dataDir ];
        };

        preStart = ''
          mkdir -p ${cfg.dataDir}/{grafana,prometheus,loki,tempo}
          chown -R ${cfg.user}:${cfg.group} ${cfg.dataDir}
        '';
      };
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [
      3000 # Grafana
      9090 # Prometheus
      3100 # Loki
      3200 # Tempo
    ];
  };
}
