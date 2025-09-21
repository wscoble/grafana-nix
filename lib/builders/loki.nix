{ lib, pkgs, generators }:

config:
let
  cfg = generators.lokiConfig config;
in
pkgs.grafana-loki
