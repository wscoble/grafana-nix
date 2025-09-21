{ lib, pkgs, grafanaLib }:

rec {
  # Default stack with opinionated configuration
  grafana-stack = (grafanaLib.buildStack { }).grafana-stack;

  # Individual components (using nixpkgs packages)
  grafana = pkgs.grafana;
  prometheus = pkgs.prometheus;
  loki = pkgs.grafana-loki;
  tempo = pkgs.tempo;
  alloy = pkgs.grafana-alloy;

  # Custom builds with our configurations
  grafana-configured = (grafanaLib.buildStack { }).grafana;
  prometheus-configured = (grafanaLib.buildStack { }).prometheus;
  loki-configured = (grafanaLib.buildStack { }).loki;
  tempo-configured = (grafanaLib.buildStack { }).tempo;
  alloy-configured = (grafanaLib.buildStack { }).alloy;

} // lib.optionalAttrs pkgs.stdenv.isLinux (let
  stack = grafanaLib.buildStack { };
in {
  # Docker images (Linux only)
  grafana-image = stack.grafana-image or null;
  prometheus-image = stack.prometheus-image or null;
  loki-image = stack.loki-image or null;
  tempo-image = stack.tempo-image or null;
  alloy-image = stack.alloy-image or null;

  # Deployment packages (Linux only)
  docker-compose = stack.docker-compose or null;
  kubernetes-manifests = stack.kubernetes-manifests or null;
}) // {

  # Custom stacks
  minimal-stack = (grafanaLib.buildStack {
    grafana = {
      adminPassword = "admin";
      theme = "light";
    };
    prometheus = {
      retention = "7d";
      scrapeInterval = "30s";
    };
  }).grafana-stack;

  production-stack = (grafanaLib.buildStack {
    grafana = {
      adminPassword = "change-me-in-production";
      theme = "dark";
      plugins = with pkgs; [ ];
    };
    prometheus = {
      retention = "90d";
      scrapeInterval = "15s";
      evaluationInterval = "15s";
    };
    loki = {
      retentionPeriod = "2160h"; # 90 days
    };
    tempo = {
      retentionDuration = "720h"; # 30 days
    };
  }).grafana-stack;

  # Development stack with additional tools
  dev-stack = (grafanaLib.buildStack {
    grafana = {
      adminPassword = "dev";
      theme = "dark";
    };
    prometheus = {
      retention = "24h";
      scrapeInterval = "5s";
      scrapeConfigs = [
        {
          job_name = "node-exporter";
          static_configs = [{ targets = [ "localhost:9100" ]; }];
        }
        {
          job_name = "test-app";
          static_configs = [{ targets = [ "localhost:8080" ]; }];
        }
      ];
    };
  }).grafana-stack;
}
