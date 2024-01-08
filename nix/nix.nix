{
  pkgs,
  lib,
  filter,
}: let
  name = "nix";

  # Filter source files to make sure the formatter derivation is cached and
  # is not rebuilt when nothing changes.
  src = filter {
    root = ../.;
    include = with filter; [
      (or_ (inDirectory "nix") (matchExt "nix"))
    ];
  };

  nix-format = pkgs.runCommand "${name}-format" {} ''
    ${pkgs.alejandra}/bin/alejandra --check ${src}
    touch $out
  '';

  nix-statix = pkgs.runCommand "${name}-statix" {} ''
    ${pkgs.statix}/bin/statix check ${src}
    touch $out
  '';
in {
  checks = {inherit nix-format nix-statix;};
}
