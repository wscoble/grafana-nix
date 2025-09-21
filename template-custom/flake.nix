{
  description = "Customizable Grafana stack from template";

  inputs = {
    grafana-nix.url = "github:OWNER/grafana-nix";
    nixpkgs.follows = "grafana-nix/nixpkgs";
  };

  outputs = { self, grafana-nix, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      # Custom stack configuration
      packages.${system}.default = grafana-nix.lib.buildStack {
        # Customize Grafana
        grafana = {
          adminPassword = "my-secure-password";
          theme = "dark";
          # Add your own dashboards
          dashboards = [
            # ./dashboards/my-dashboard.json
          ];
        };

        # Customize Prometheus
        prometheus = {
          retention = "30d";
          scrapeConfigs = [
            {
              job_name = "my-app";
              static_configs = [{ targets = [ "localhost:8080" ]; }];
            }
          ];
        };

        # Customize Loki
        loki = {
          retentionPeriod = "744h"; # 31 days
        };

        # Customize Tempo
        tempo = {
          retentionDuration = "240h"; # 10 days
        };
      };

      # Apps using custom configuration
      apps.${system} = {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/grafana-stack";
        };

        docker = {
          type = "app";
          program = "${self.packages.${system}.default.docker-compose}/bin/docker-up";
        };

        k8s = {
          type = "app";
          program = "${self.packages.${system}.default.kubernetes-manifests}/bin/k8s-apply";
        };
      };

      # Enhanced development shell
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          # Your custom tools
          curl
          jq
          # Add more development tools as needed
        ];

        shellHook = ''
          echo "🔧 Custom Grafana Stack Development Environment"
          echo "=============================================="
          echo ""
          echo "Available commands:"
          echo "  nix run .           # Start custom stack"
          echo "  nix run .#docker    # Deploy with Docker"
          echo "  nix run .#k8s       # Deploy to Kubernetes"
        '';
      };
    };
}