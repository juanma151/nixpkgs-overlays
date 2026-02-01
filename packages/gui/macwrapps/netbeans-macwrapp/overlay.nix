# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:

final: prev: {
  netbeans-macwrapp = import ./. {
    system = prev.stdenv.hostPlatform.system;
    stdenvNoCC = prev.stdenvNoCC;
    netbeans = prev.netbeans;
    mkiconapple = prev.mkiconapple;
    jdkPkg = prev.openjdk25;
  };
}
