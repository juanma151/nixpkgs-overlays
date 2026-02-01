# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
{
  description = "";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/ebe4301cbd8f81c4f8d3244b3632338bbeb6d49c?narHash=sha256-5RJTdUHDmj12Qsv7XOhuospjAjATNiTMElplWnJE9Hs%3D";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {pkgs, ...}: let
        mediaDownloaderMacwrapp = pkgs.callPackage ./default.nix {};
      in {
        packages = {
          inherit mediaDownloaderMacwrapp;
          default = mediaDownloaderMacwrapp;
        };
      };
    };
}
