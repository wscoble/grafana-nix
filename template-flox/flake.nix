{
  description = "Simple Flox environment for Grafana Stack";

  inputs = {
    grafana-nix.url = "github:wscoble/grafana-nix";
    nixpkgs.follows = "grafana-nix/nixpkgs";
  };

  outputs = { self, grafana-nix, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      # Re-export for Flox consumption
      packages.${system}.default = grafana-nix.packages.${system}.grafana-nix;

      # Development shell with tools
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = [
          grafana-nix.packages.${system}.grafana-nix
          nixpkgs.legacyPackages.${system}.curl
          nixpkgs.legacyPackages.${system}.jq
        ];
      };
    };
}