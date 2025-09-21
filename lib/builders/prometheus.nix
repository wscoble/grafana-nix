{ lib, pkgs, generators }:

config:
let
  cfg = generators.prometheusConfig config;
in
pkgs.prometheus
