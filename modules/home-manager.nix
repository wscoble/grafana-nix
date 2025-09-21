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
}
