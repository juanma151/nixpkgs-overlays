# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
let
  inherit (builtins) getFlake throw isNull getEnv;
in
  args @ {nixpkgsPure ? null, ...}: let

    ## get the original nixpkgs
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


    ## build the overlay list
    oldOverlays = args.overlays or [];

    newOverlays = import ./packages;


    ## build the nixpkgs args
    newArgs = args // {overlays = oldOverlays ++ newOverlays;};

  in
    (import nixpkgs) newArgs
