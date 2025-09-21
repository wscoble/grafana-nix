{
  description = "Basic Grafana stack from template";

  inputs = {
    grafana-nix.url = "github:OWNER/grafana-nix";
    nixpkgs.follows = "grafana-nix/nixpkgs";
  };

  outputs = { self, grafana-nix, nixpkgs }:
    let
      system = "x86_64-linux";
    in
    {
      # Use the default stack
      packages.${system}.default = grafana-nix.packages.${system}.grafana-stack;

      # Quick start app
      apps.${system}.default = grafana-nix.apps.${system}.default;

      # Development shell
      devShells.${system}.default = grafana-nix.devShells.${system}.default;
    };
}