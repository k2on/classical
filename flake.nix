{
  description = "Classical music that is free to download, as one JSON catalogue";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      each = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # `nix build`: result is catalogue.json, what GitHub Pages publishes.
      packages = each (pkgs: rec {
        catalogue = pkgs.writeText "catalogue.json" (import ./catalogue.nix);
        default = catalogue;
      });
      # `nix flake check`: the files read, and every check in catalogue.nix passes.
      checks = each (pkgs: {
        catalogue = pkgs.runCommand "catalogue-check" { } ''
          ${pkgs.jq}/bin/jq -e '.albums | length > 0' ${pkgs.writeText "catalogue.json" (import ./catalogue.nix)} > /dev/null
          touch $out
        '';
      });
    };
}
