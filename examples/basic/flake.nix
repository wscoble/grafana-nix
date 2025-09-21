{
  description = "Basic Grafana stack example";

  inputs = {
    # Use the latest version from FlakeHub
    grafana-nix.url = "https://flakehub.com/f/wscoble/grafana-nix";
    nixpkgs.follows = "grafana-nix/nixpkgs";
  };

  outputs = { self, grafana-nix, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Basic stack with default settings
      packages.${system} = {
        default = grafana-nix.packages.${system}.grafana-stack;

        # Individual components
        grafana = grafana-nix.packages.${system}.grafana;
        prometheus = grafana-nix.packages.${system}.prometheus;
        loki = grafana-nix.packages.${system}.loki;
        tempo = grafana-nix.packages.${system}.tempo;
      };

      # Run the complete stack
      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/grafana-stack";
      };

      # Development shell
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Observability tools
          prometheus
          grafana
          # Development tools
          curl
          jq
          # Documentation
          mdbook
        ];

        shellHook = ''
          echo "🚀 Welcome to the Grafana Nix Stack development environment!"
          echo ""
          echo "Available commands:"
          echo "  nix run .                 # Start the complete stack"
          echo "  prometheus --help         # Prometheus CLI"
          echo "  grafana-cli --help        # Grafana CLI"
          echo ""
          echo "Quick start:"
          echo "  1. Run: nix run ."
          echo "  2. Open: http://localhost:3000 (admin/admin)"
          echo "  3. Explore: http://localhost:9090 (Prometheus)"
        '';
      };
    };
}