{ lib, pkgs }:

rec {
  # Configuration generators
  generators = import ./generators.nix { inherit lib pkgs; };

  # Docker utilities
  docker = import ./docker.nix { inherit lib pkgs; };

  # Kubernetes utilities
  kubernetes = import ./kubernetes.nix { inherit lib pkgs; };

  # Stack builder - the main API
  buildStack = args: import ./stack-builder.nix { inherit lib pkgs generators docker kubernetes; } args;

  # Component builders
  buildGrafana = import ./builders/grafana.nix { inherit lib pkgs generators; };
  buildPrometheus = import ./builders/prometheus.nix { inherit lib pkgs generators; };
  buildLoki = import ./builders/loki.nix { inherit lib pkgs generators; };
  buildTempo = import ./builders/tempo.nix { inherit lib pkgs generators; };

  # Configuration schemas/types
  types = import ./types.nix { inherit lib; };

  # Utility functions
  utils = {
    # Merge configurations with proper precedence
    mergeConfigs = configs: lib.foldr lib.recursiveUpdate { } configs;

    # Generate secure passwords
    generatePassword = length: pkgs.runCommand "password"
      { buildInputs = [ pkgs.openssl ]; } ''
      openssl rand -base64 ${toString length} | tr -d '\n' > $out
    '';

    # Port validation
    validatePort = port:
      assert lib.isInt port;
      assert port > 0 && port < 65536;
      port;

    # Create systemd service
    mkSystemdService = { name, description, execStart, user ? "grafana-stack", ... }@args:
      let
        serviceArgs = removeAttrs args [ "name" "description" "execStart" ];
      in
      {
        inherit description;
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          ExecStart = execStart;
          User = user;
          Restart = "always";
          RestartSec = "10s";
        } // serviceArgs.serviceConfig or { };
      };
  };
}
