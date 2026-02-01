# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
{
  description = "nixpkgs unstable with overlays from ./overlays (julia-bin checks disabled)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }: let
    overlays = import ./overlays;

    # Si ./overlays devuelve una lista de overlays, los aplicamos tal cual.
    mkPkgs = system:
      import ./. {
        nixpkgsPure = nixpkgs;
        inherit system;
      };

    systems = [
      "x86_64-darwin"
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];
  in
    flake-parts.lib.mkFlake {inherit inputs;}
    {
      inherit systems;

      # Re-export de overlays (por comodidad)
      flake.overlays.default = (
        final: prev:
          nixpkgs.lib.foldl' (acc: ov: acc // (ov final prev)) {} overlays
      );

      # Export “tipo nixpkgs”: todo dentro de legacyPackages.<system>
      flake.legacyPackages = builtins.listToAttrs (map (system: {
          name = system;
          value = mkPkgs system;
        })
        systems);

      # (Opcional) Para que flake-parts use este pkgs internamente
      perSystem = {system, ...}: {
        _module.args.pkgs = mkPkgs system;
      };
    };
}
