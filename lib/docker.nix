{ lib, pkgs }:

rec {
  # Build a Docker image using Nix
  buildImage = args: pkgs.dockerTools.buildImage ({
    created = "now";
    config = {
      Env = [
        "PATH=/bin"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  } // args);

  # Build a Docker Compose configuration
  buildCompose = { version ? "3.8", services ? { }, volumes ? { }, networks ? { }, ... }@args:
    let
      compose = {
        inherit version services;
      } // lib.optionalAttrs (volumes != { }) { inherit volumes; }
      // lib.optionalAttrs (networks != { }) { inherit networks; };

      composeFile = pkgs.writeText "docker-compose.yml" (lib.generators.toYAML { } compose);

    in
    pkgs.runCommand "docker-compose-setup" { } ''
      mkdir -p $out/bin

      # Copy compose file
      cp ${composeFile} $out/docker-compose.yml

      # Create helper scripts
      cat > $out/bin/docker-up <<'EOF'
      #!/usr/bin/env bash
      set -euo pipefail

      cd "$(dirname "$0")/.."

      echo "🐳 Starting Grafana Stack with Docker Compose..."
      ${pkgs.docker-compose}/bin/docker-compose up -d

      echo ""
      echo "✅ Stack started! Access points:"
      echo "  Grafana:    http://localhost:3000"
      echo "  Prometheus: http://localhost:9090"
      echo "  Loki:       http://localhost:3100"
      echo "  Tempo:      http://localhost:3200"
      echo ""
      echo "🔧 Management commands:"
      echo "  docker-compose logs -f    # View logs"
      echo "  docker-compose down       # Stop stack"
      EOF

      cat > $out/bin/docker-down <<'EOF'
      #!/usr/bin/env bash
      cd "$(dirname "$0")/.."
      ${pkgs.docker-compose}/bin/docker-compose down "$@"
      EOF

      cat > $out/bin/docker-logs <<'EOF'
      #!/usr/bin/env bash
      cd "$(dirname "$0")/.."
      ${pkgs.docker-compose}/bin/docker-compose logs "$@"
      EOF

      chmod +x $out/bin/*
    '';

  # Build layered image for better caching
  buildLayeredImage = args: pkgs.dockerTools.buildLayeredImage ({
    created = "now";
    config = {
      Env = [
        "PATH=/bin"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  } // args);

  # Minimal base image
  baseImage = pkgs.dockerTools.buildImage {
    name = "grafana-nix/base";
    tag = "latest";
    copyToRoot = pkgs.buildEnv {
      name = "base-env";
      paths = with pkgs; [
        busybox
        cacert
        tzdata
      ];
      pathsToLink = [ "/bin" "/etc" "/share" ];
    };
    config = {
      Env = [
        "PATH=/bin"
        "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        "TZDIR=/share/zoneinfo"
      ];
      Cmd = [ "/bin/sh" ];
    };
  };
}
