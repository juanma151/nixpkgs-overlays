# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:

final: prev: {
  media-downloader-macwrapp = import ./. {
    stdenv = prev.stdenv;
    media-downloader = prev.media-downloader;
  };
}
