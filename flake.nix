{
  description = "Complete Grafana observability stack for development and production";

  # Comprehensive metadata for the flake
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = nixpkgs.lib;

          # Import our custom lib
          grafanaLib = import ./lib { inherit lib pkgs; };

          # Import packages
          packages = import ./packages { inherit lib pkgs grafanaLib; };

          # Import modules
          modules = import ./modules { inherit lib pkgs grafanaLib; };

        in
        {
          # Core packages - optimized for Flox consumption
          packages = {
            # Main Flox entry point - complete observability stack
            default = packages.grafana-stack;
            grafana-nix = packages.grafana-stack; # Explicit name for flox install

            # Individual components for granular installation
            inherit (packages)
              grafana
              prometheus
              loki
              tempo
              alloy
              grafana-stack;

            # Docker images (fail gracefully on non-Linux)
            inherit (packages)
              grafana-image
              prometheus-image
              loki-image
              tempo-image
              alloy-image;

            # Deployment artifacts (fail gracefully on non-Linux)
            inherit (packages)
              docker-compose
              kubernetes-manifests;

            # Pre-configured stacks for different use cases
            inherit (packages)
              minimal-stack
              production-stack
              dev-stack;
          };

          # Applications that can be run with `nix run`
          apps = {
            # Run the complete stack locally
            default = {
              type = "app";
              program = "${packages.grafana-stack}/bin/grafana-stack";
              meta = {
                description = "Complete Grafana observability stack with Grafana, Prometheus, Loki, Tempo, and Alloy";
                longDescription = ''
                  Starts a complete observability stack including:
                  - Grafana dashboard (port 3000)
                  - Prometheus metrics (port 9090)
                  - Loki logs (port 3100)
                  - Tempo traces (port 3200)
                  - Alloy agent (port 12345)

                  Perfect for development environments and local testing.
                '';
                homepage = "https://github.com/wscoble/grafana-nix";
                license = lib.licenses.mit;
                platforms = lib.platforms.unix;
              };
            };

            # Individual components
            grafana = {
              type = "app";
              program = "${packages.grafana}/bin/grafana-server";
              meta = {
                description = "Grafana visualization and dashboarding server";
                longDescription = "Start Grafana server for creating beautiful dashboards and visualizations";
                homepage = "https://grafana.com/";
                license = lib.licenses.agpl3Only;
                platforms = lib.platforms.unix;
              };
            };

            prometheus = {
              type = "app";
              program = "${packages.prometheus}/bin/prometheus";
              meta = {
                description = "Prometheus monitoring system and time series database";
                longDescription = "Start Prometheus server for metrics collection and monitoring";
                homepage = "https://prometheus.io/";
                license = lib.licenses.asl20;
                platforms = lib.platforms.unix;
              };
            };

            loki = {
              type = "app";
              program = "${packages.loki}/bin/loki";
              meta = {
                description = "Loki log aggregation system";
                longDescription = "Start Loki server for log aggregation and querying";
                homepage = "https://grafana.com/oss/loki/";
                license = lib.licenses.agpl3Only;
                platforms = lib.platforms.unix;
              };
            };

            tempo = {
              type = "app";
              program = "${packages.tempo}/bin/tempo";
              meta = {
                description = "Tempo distributed tracing backend";
                longDescription = "Start Tempo server for distributed tracing and trace storage";
                homepage = "https://grafana.com/oss/tempo/";
                license = lib.licenses.agpl3Only;
                platforms = lib.platforms.unix;
              };
            };

            alloy = {
              type = "app";
              program = "${packages.alloy}/bin/alloy";
              meta = {
                description = "Alloy (Grafana Agent) telemetry collector";
                longDescription = "Start Alloy agent for collecting and forwarding metrics, logs, and traces";
                homepage = "https://grafana.com/docs/alloy/";
                license = lib.licenses.asl20;
                platforms = lib.platforms.unix;
              };
            };

            # Deployment helpers (fail gracefully on non-Linux)
            docker-up = {
              type = "app";
              program = "${packages.docker-compose}/bin/docker-up";
              meta = {
                description = "Deploy Grafana stack using Docker Compose";
                longDescription = "Start the complete observability stack using Docker containers";
                homepage = "https://github.com/wscoble/grafana-nix";
                license = lib.licenses.mit;
                platforms = lib.platforms.unix;
              };
            };

            k8s-apply = {
              type = "app";
              program = "${packages.kubernetes-manifests}/bin/k8s-apply";
              meta = {
                description = "Deploy Grafana stack to Kubernetes";
                longDescription = "Apply Kubernetes manifests for production deployment of the observability stack";
                homepage = "https://github.com/wscoble/grafana-nix";
                license = lib.licenses.mit;
                platforms = lib.platforms.unix;
              };
            };
          };

          # Development shells for different use cases
          devShells = {
            # Main development shell for project contributors
            default = pkgs.mkShell {
              name = "grafana-nix-dev";

              buildInputs = with pkgs; [
                # Nix development tools
                nil # Nix LSP
                nixpkgs-fmt # Nix formatter
                nix-tree # Dependency visualization

                # Observability stack for testing
                grafana
                prometheus
                loki
                grafana-alloy
                tempo

                # Development and testing tools
                curl # HTTP client
                jq # JSON processor
                yq-go # YAML processor
                httpie # User-friendly HTTP client

                # Container tools
                docker
                docker-compose
                kubectl

                # Documentation tools
                mdbook # Documentation generator

                # Git and development
                git
                gh # GitHub CLI
              ];

              shellHook = ''
                echo "🚀 Grafana Nix Stack - Development Environment"
                echo "=============================================="
                echo ""
                echo "You're now in the development environment for the"
                echo "Grafana Nix Stack project itself."
                echo ""
                echo "💡 Want to use the observability stack in YOUR project?"
                echo "   Try: flox install github:wscoble/grafana-nix"
                echo ""
                echo "🛠️  Development Commands:"
                echo "  nix run .                     # Test the stack locally"
                echo "  nix flake check              # Validate all code"
                echo "  nix flake show               # Show all outputs"
                echo "  nixpkgs-fmt *.nix lib/**    # Format Nix files"
                echo ""
                echo "📦 Build & Test Commands:"
                echo "  nix build .#grafana-stack    # Main package"
                echo "  nix build .#alloy-image      # Docker image"
                echo "  nix build .#docker-compose   # Docker setup"
                echo "  nix build .#kubernetes-manifests  # K8s manifests"
                echo ""
                echo "🧪 Template Testing:"
                echo "  cd /tmp && nix flake init -t \$PWD#flox"
                echo ""
                echo "🔧 Available Tools: grafana, prometheus, loki, alloy, tempo,"
                echo "   curl, jq, yq, httpie, docker, kubectl, mdbook, git, gh"
                echo ""
                echo "📚 Documentation: https://github.com/wscoble/grafana-nix"
              '';

              # Environment variables for development
              GRAFANA_DEV_MODE = "true";
              NIX_FLAKE_PROJECT = "grafana-nix";
            };

            # Minimal shell for users who just want to try the stack
            minimal = pkgs.mkShell {
              name = "grafana-nix-minimal";

              buildInputs = with pkgs; [
                curl
                jq
              ];

              shellHook = ''
                echo "🚀 Grafana Nix Stack - Minimal Environment"
                echo "=========================================="
                echo ""
                echo "Quick commands:"
                echo "  nix run .                 # Start the stack"
                echo "  curl http://localhost:3000  # Test Grafana"
                echo ""
                echo "For full development environment: nix develop"
              '';
            };
          };

          # Library functions for external use
          lib = grafanaLib;

          # Checks run by `nix flake check`
          checks = {
            # Ensure all packages build
            inherit (packages) grafana prometheus loki tempo alloy grafana-stack;

            # Format check
            format-check = pkgs.runCommand "format-check"
              { buildInputs = [ pkgs.nixpkgs-fmt ]; } ''
              cd ${./.}
              nixpkgs-fmt --check *.nix lib modules packages
              touch $out
            '';
          };

          # NixOS/home-manager modules (these need to be outside eachDefaultSystem)
          # Moved to bottom of file
        }) // {
      # Cross-system outputs

      # Templates for easy project setup
      templates = {
        default = {
          path = ./template;
          description = "Basic Grafana observability stack setup";
          welcomeText = ''
            🚀 Welcome to Grafana Nix Stack!

            You've initialized a basic observability stack with:
            - Grafana (dashboards)
            - Prometheus (metrics)
            - Loki (logs)
            - Tempo (traces)
            - Alloy (data collection)

            Quick start:
              nix run .          # Start the complete stack
              nix develop        # Enter development shell

            Access points:
              http://localhost:3000  (Grafana - admin/admin)
              http://localhost:9090  (Prometheus)

            Documentation: https://github.com/wscoble/grafana-nix
          '';
        };

        custom = {
          path = ./template-custom;
          description = "Customizable Grafana stack with advanced configuration";
          welcomeText = ''
            🔧 Custom Grafana Stack Template

            This template provides advanced customization options for:
            - Custom retention policies
            - Additional data sources
            - Custom dashboards
            - Production-ready configuration

            Edit flake.nix to customize your stack configuration.
          '';
        };

        flox = {
          path = ./template-flox;
          description = "Flox environment with complete observability stack";
          welcomeText = ''
            🦊 Flox + Grafana Stack Template

            Perfect for development teams! This provides:
            - Complete observability stack as Flox services
            - Development-optimized configuration
            - Team-shareable environment
            - Automatic service discovery

            Quick start:
              flox activate
              flox services start observability

            All team members get identical observability!
          '';
        };

      };

      # NixOS/home-manager modules
      nixosModules.default = import ./modules/nixos.nix;
      homeModules.default = import ./modules/home-manager.nix;

      # Overlays for customizing nixpkgs
      overlays = {
        default = final: prev: {
          # Main observability stack with default configuration
          grafana-stack = (import ./lib { lib = final.lib; pkgs = final; }).buildStack { };

          # Individual configured components
          grafana-observability = (import ./lib { lib = final.lib; pkgs = final; }).buildStack { }.grafana;
          prometheus-observability = (import ./lib { lib = final.lib; pkgs = final; }).buildStack { }.prometheus;
          loki-observability = (import ./lib { lib = final.lib; pkgs = final; }).buildStack { }.loki;
          tempo-observability = (import ./lib { lib = final.lib; pkgs = final; }).buildStack { }.tempo;
          alloy-observability = (import ./lib { lib = final.lib; pkgs = final; }).buildStack { }.alloy;

          # Convenience functions for custom stacks
          buildGrafanaStack = config: (import ./lib { lib = final.lib; pkgs = final; }).buildStack config;
        };

        # Development overlay with additional tools
        dev = final: prev: {
          inherit (self.overlays.default final prev) grafana-stack buildGrafanaStack;

          # Development-specific utilities
          grafana-dev-tools = final.symlinkJoin {
            name = "grafana-dev-tools";
            paths = with final; [
              curl
              jq
              yq-go
              httpie
            ];
          };
        };
      };

      # Formatter for `nix fmt`
      formatter = flake-utils.lib.eachDefaultSystemMap (system:
        nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );
    };
}
