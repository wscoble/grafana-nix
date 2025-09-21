{ lib, pkgs }:

rec {
  # Configuration generators
  generators = import ./generators.nix { inherit lib pkgs; };

  # Docker utilities (Linux only)
  docker =
    if pkgs.stdenv.isLinux
    then import ./docker.nix { inherit lib pkgs; }
    else {
      buildImage = args: pkgs.writeShellScriptBin "docker-image-unsupported" ''
        echo "⚠️  Docker images are only supported on Linux platforms" >&2
        echo "💡 Try running this on a Linux system or use the Docker deployment examples" >&2
        exit 1
      '';
      buildCompose = args: pkgs.writeShellScriptBin "docker-compose-unsupported" ''
        echo "⚠️  Docker Compose is only supported on Linux platforms" >&2
        echo "💡 Try running this on a Linux system" >&2
        exit 1
      '';
      buildLayeredImage = args: pkgs.writeShellScriptBin "docker-layered-image-unsupported" ''
        echo "⚠️  Docker layered images are only supported on Linux platforms" >&2
        echo "💡 Try running this on a Linux system" >&2
        exit 1
      '';
      baseImage = pkgs.writeShellScriptBin "docker-base-image-unsupported" ''
        echo "⚠️  Docker base image is only supported on Linux platforms" >&2
        echo "💡 Try running this on a Linux system" >&2
        exit 1
      '';
    };

  # Kubernetes utilities (Linux only)
  kubernetes =
    if pkgs.stdenv.isLinux
    then import ./kubernetes.nix { inherit lib pkgs; }
    else {
      buildManifests = args: pkgs.writeShellScriptBin "k8s-manifests-unsupported" ''
        echo "⚠️  Kubernetes manifests are only supported on Linux platforms" >&2
        echo "💡 Try running this on a Linux system" >&2
        exit 1
      '';
    };

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
