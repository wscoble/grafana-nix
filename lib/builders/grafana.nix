{ lib, pkgs, generators }:

config:
let
  cfg = generators.grafanaConfig config;
in
pkgs.grafana.overrideAttrs (old: {
  buildInputs = (old.buildInputs or [ ]) ++ (config.plugins or [ ]);
  meta = old.meta // {
    description = "Grafana with Nix configuration";
  };
})
