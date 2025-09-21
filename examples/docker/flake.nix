{
  description = "Docker deployment example for Grafana stack";

  inputs = {
    grafana-nix.url = "https://flakehub.com/f/OWNER/grafana-nix";
    nixpkgs.follows = "grafana-nix/nixpkgs";
  };

  outputs = { self, grafana-nix, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        # Individual Docker images
        grafana-image = grafana-nix.packages.${system}.grafana-docker-image;
        prometheus-image = grafana-nix.packages.${system}.prometheus-docker-image;
        loki-image = grafana-nix.packages.${system}.loki-docker-image;
        tempo-image = grafana-nix.packages.${system}.tempo-docker-image;

        # Complete Docker Compose setup
        docker-compose = grafana-nix.lib.buildDockerCompose {
          # Compose configuration
          version = "3.8";

          services = {
            grafana = {
              build = { context = "${self.packages.${system}.grafana-image}"; };
              ports = [ "3000:3000" ];
              environment = {
                GF_SECURITY_ADMIN_PASSWORD = "admin";
                GF_USERS_ALLOW_SIGN_UP = "false";
              };
              volumes = [
                "grafana-data:/var/lib/grafana"
                "./config/grafana:/etc/grafana/provisioning"
              ];
              depends_on = [ "prometheus" "loki" "tempo" ];
            };

            prometheus = {
              build = { context = "${self.packages.${system}.prometheus-image}"; };
              ports = [ "9090:9090" ];
              command = [
                "--config.file=/etc/prometheus/prometheus.yml"
                "--storage.tsdb.path=/prometheus"
                "--web.console.libraries=/etc/prometheus/console_libraries"
                "--web.console.templates=/etc/prometheus/consoles"
                "--storage.tsdb.retention.time=30d"
                "--web.enable-lifecycle"
              ];
              volumes = [
                "prometheus-data:/prometheus"
                "./config/prometheus:/etc/prometheus"
              ];
            };

            loki = {
              build = { context = "${self.packages.${system}.loki-image}"; };
              ports = [ "3100:3100" ];
              command = [ "-config.file=/etc/loki/local-config.yaml" ];
              volumes = [
                "loki-data:/loki"
                "./config/loki:/etc/loki"
              ];
            };

            tempo = {
              build = { context = "${self.packages.${system}.tempo-image}"; };
              ports = [
                "3200:3200"   # Tempo
                "4317:4317"   # OTLP gRPC
                "4318:4318"   # OTLP HTTP
                "14268:14268" # Jaeger HTTP
              ];
              command = [ "-config.file=/etc/tempo/tempo.yaml" ];
              volumes = [
                "tempo-data:/tmp/tempo"
                "./config/tempo:/etc/tempo"
              ];
            };

            # Optional: Node exporter for system metrics
            node-exporter = {
              image = "prom/node-exporter:latest";
              ports = [ "9100:9100" ];
              command = [
                "--path.procfs=/host/proc"
                "--path.rootfs=/rootfs"
                "--path.sysfs=/host/sys"
                "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
              ];
              volumes = [
                "/proc:/host/proc:ro"
                "/sys:/host/sys:ro"
                "/:/rootfs:ro"
              ];
            };
          };

          volumes = {
            grafana-data = {};
            prometheus-data = {};
            loki-data = {};
            tempo-data = {};
          };

          networks = {
            grafana-network = {
              driver = "bridge";
            };
          };
        };

        # Configuration files
        config = pkgs.stdenv.mkDerivation {
          name = "grafana-stack-config";
          src = ./.;

          installPhase = ''
            mkdir -p $out
            cp -r config $out/
          '';
        };

        # Default: Docker Compose setup
        default = self.packages.${system}.docker-compose;
      };

      apps.${system} = {
        # Start with Docker Compose
        default = {
          type = "app";
          program = pkgs.writeShellScript "start-docker-stack" ''
            set -e
            echo "🐳 Starting Grafana Stack with Docker Compose..."

            # Create config directory
            mkdir -p config/{grafana,prometheus,loki,tempo}

            # Generate docker-compose.yml
            ${self.packages.${system}.docker-compose}/bin/generate-compose > docker-compose.yml

            # Start the stack
            ${pkgs.docker-compose}/bin/docker-compose up -d

            echo "✅ Stack started!"
            echo ""
            echo "📊 Access points:"
            echo "  Grafana:    http://localhost:3000 (admin/admin)"
            echo "  Prometheus: http://localhost:9090"
            echo "  Loki:       http://localhost:3100"
            echo "  Tempo:      http://localhost:3200"
            echo ""
            echo "🔧 Management:"
            echo "  docker-compose logs -f        # View logs"
            echo "  docker-compose down           # Stop stack"
            echo "  docker-compose down -v        # Stop and remove volumes"
          '';
        };

        # Stop the stack
        stop = {
          type = "app";
          program = pkgs.writeShellScript "stop-docker-stack" ''
            echo "🛑 Stopping Grafana Stack..."
            ${pkgs.docker-compose}/bin/docker-compose down
            echo "✅ Stack stopped!"
          '';
        };

        # View logs
        logs = {
          type = "app";
          program = pkgs.writeShellScript "docker-stack-logs" ''
            ${pkgs.docker-compose}/bin/docker-compose logs -f
          '';
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          docker
          docker-compose
          curl
          jq
        ];

        shellHook = ''
          echo "🐳 Docker Grafana Stack Development Environment"
          echo "==============================================="
          echo ""
          echo "🚀 Commands:"
          echo "  nix run .              # Start the complete stack"
          echo "  nix run .#stop         # Stop the stack"
          echo "  nix run .#logs         # View logs"
          echo ""
          echo "🛠️  Docker commands:"
          echo "  docker-compose ps      # View running containers"
          echo "  docker-compose pull    # Update images"
          echo "  docker-compose restart # Restart services"
          echo ""
          echo "📦 Build individual images:"
          echo "  nix build .#grafana-image"
          echo "  nix build .#prometheus-image"
          echo ""
          echo "⚠️  Prerequisites:"
          echo "  - Docker daemon must be running"
          echo "  - Current user must be in docker group"
        '';
      };
    };
}