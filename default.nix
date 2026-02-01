# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
let
  inherit (builtins) getFlake throw isNull getEnv;
in
  args @ {nixpkgsPure ? null, ...}: let
    oldOverlays = args.overlays or [];

    newOverlays = import ./overlays;

    newArgs = args // {overlays = oldOverlays ++ newOverlays;};

    nixpkgsImpure = getFlake "nixpkgs-base";

    nixpkgsPureChecked =
      if isNull nixpkgsPure
      then throw "Can't get the nixpkgs flake in a pure environment"
      else nixpkgsPure;

    isImpure = getEnv "HOME" != "";

    nixpkgs =
      if isImpure
      then nixpkgsImpure
      else nixpkgsPureChecked;
  in
    (import nixpkgs) newArgs
