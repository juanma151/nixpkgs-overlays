# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
final: prev: {
    mk-icon-apple = import ./. {
        lib = prev.lib;
        stdenvNoCC = prev.stdenvNoCC;
        makeWrapper = prev.makeWrapper;
        zsh = prev.zsh;
        coreutils = prev. ;
        file = prev.file;
        pythonPkg = prev.python313;
    };
}
