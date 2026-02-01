# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:

builtins.map ( p: import p ) [

  ./terminal/julia/overlay.nix
  ./gui/macwrapps/netbeans-macwrapp/overlay.nix

]
