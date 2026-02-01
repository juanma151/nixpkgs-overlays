# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
{
  stdenv,
  media-downloader,
}:
stdenv.mkDerivation {
  pname = "media-downloader-macwrapp";
  version = "1.0.0";

  dontUnpack = true;

  installPhase = ''
    ## Create the Applications folder
    mkdir -p $out/Applications

    ## Copy the package
    cp -a "${media-downloader}"/*.app $out/Applications/
  '';
}
