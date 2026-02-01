# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
final: prev: {
  julia-bin = prev.julia-bin.overrideAttrs (old: {
    doCheck = false;
    doInstallCheck = false;

    checkPhase = "true";
    installCheckPhase = "true";
  });
}
