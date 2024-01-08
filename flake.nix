{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nix-filter,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;

        overlays = [
          (import ./nix/elixir_overlay.nix)
          (final: prev: rec {
            nodejs = prev.nodejs_20;
            yarn = prev.yarn.override {inherit nodejs;};
          })
        ];
      };

      nix = pkgs.callPackage ./nix/nix.nix {filter = nix-filter.lib;};

      devShell = pkgs.callPackage ./nix/dev.nix {};
    in {
      checks = nix.checks;

      devShells.default = devShell;

      formatter = pkgs.alejandra;
    });
}
