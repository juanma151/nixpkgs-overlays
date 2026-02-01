# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
{
  description = "Apache NetBeans macOS .app wrapper (nixpkgs-25.11-darwin) forcing openjdk25 + app icon via icnsify";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mkiconapple.url = "github:juanma151/mk-icon-apple";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    mkiconapple,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        pkgs,
        system,
        ...
      }: let
        netbeans-macwrapp = pkgs.callPackage ./default.nix {
          inherit system;
          mkiconapple = inputs.mkiconapple.packages."${system}".mkiconapple;
          jdkPkg = pkgs.openjdk25;
        };
      in {
        packages = {
          inherit netbeans-macwrapp;
          default = netbeans-macwrapp;
        };
      };
    };
}
