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

  # Docker images
  grafana-image = (grafanaLib.buildStack { }).grafana-image;
  prometheus-image = (grafanaLib.buildStack { }).prometheus-image;
  loki-image = (grafanaLib.buildStack { }).loki-image;
  tempo-image = (grafanaLib.buildStack { }).tempo-image;
  alloy-image = (grafanaLib.buildStack { }).alloy-image;

  # Deployment packages
  docker-compose = (grafanaLib.buildStack { }).docker-compose;
  kubernetes-manifests = (grafanaLib.buildStack { }).kubernetes-manifests;

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
