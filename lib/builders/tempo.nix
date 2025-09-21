{ lib, pkgs, generators }:

config:
let
  cfg = generators.tempoConfig config;
in
pkgs.tempo
