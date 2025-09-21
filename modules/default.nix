{ lib, pkgs, grafanaLib }:

{
  # NixOS module for system-wide installation
  nixos = { config, pkgs, ... }:
    let
      cfg = config.services.grafana-stack;
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
    };

  # Home Manager module for user installations
  home-manager = { config, pkgs, ... }:
    let
      cfg = config.services.grafana-stack;
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
        };

        dataDir = lib.mkOption {
          type = lib.types.str;
          default = "${config.xdg.dataHome}/grafana-stack";
          description = "Directory to store data";
        };

        autoStart = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to start the stack automatically";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        # Create data directory
        home.file."${cfg.dataDir}/.keep".text = "";

        # Systemd user service
        systemd.user.services.grafana-stack = lib.mkIf cfg.autoStart {
          Unit = {
            Description = "Grafana Observability Stack";
            After = [ "graphical-session.target" ];
          };

          Install = {
            WantedBy = [ "default.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/grafana-stack ${cfg.dataDir}";
            Restart = "always";
            RestartSec = "10s";
          };
        };

        # Shell aliases
        programs.bash.shellAliases = {
          grafana-stack = "${cfg.package}/bin/grafana-stack ${cfg.dataDir}";
          grafana-stop = "pkill -f grafana-stack";
        };

        programs.zsh.shellAliases = {
          grafana-stack = "${cfg.package}/bin/grafana-stack ${cfg.dataDir}";
          grafana-stop = "pkill -f grafana-stack";
        };
      };
    };

  # Note: Flox integration is handled through flake packages and manifest.toml
  # See examples/flox/ for Flox environment configuration
}
