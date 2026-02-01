# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
let
  pkgs = (import <nixpkgs>) {};
in
  {
    lib ? pkgs.lib,
    stdenvNoCC ? pkgs.stdenvNoCC,
    makeWrapper ? pkgs.makeWrapper,
    zsh ? pkgs.zsh,
    coreutils ? pkgs.coreutils,
    file ? pkgs.file,
    pythonPkg ? pkgs.python313,
  }: let
    pythonEnv = pythonPkg.withPackages (ps: [
      ps.icnsutil
    ]);

    pname = "mk-icon-apple";
    src = ./src;
    baseName = "mkiconapple";
    scriptName = "${baseName}.zsh";
    exeName = baseName;
  in
    stdenvNoCC.mkDerivation {
      inherit pname src;

      version = "3.0.0";

      nativeBuildInputs = [
        makeWrapper
      ];

      # it doesn't compile anything, just install and wrap
      dontBuild = true;
      dontConfigure = true;

      installPhase = ''
        runHook preInstall

        # 1) Install the real script
        mkdir -p "$out/share/${pname}"
        install -m 0755 "${src}/${scriptName}" "$out/share/${pname}/${scriptName}"

        # 2) New folder with synlinks to the bin tools
        mkdir -p "$out/libexec/${pname}/bin"

        ln -sf "${zsh}/bin/zsh"                 "$out/libexec/${pname}/bin/zsh"
        ln -sf "${coreutils}/bin/ln"            "$out/libexec/${pname}/bin/ln"
        ln -sf "${coreutils}/bin/mktemp"        "$out/libexec/${pname}/bin/mktemp"
        ln -sf "${file}/bin/file"               "$out/libexec/${pname}/bin/file"
        ln -sf "${pythonEnv}/bin/icnsutil"      "$out/libexec/${pname}/bin/icnsutil"

        # 3) Final wrapper: fix PATH and execute the zsh script with nix's zsh
        mkdir -p "$out/bin"

        makeWrapper "${zsh}/bin/zsh" "$out/bin/${exeName}" \
          --prefix PATH : "$out/libexec/${pname}/bin" \
          --add-flags "$out/share/${pname}/${scriptName}"

        runHook postInstall
      '';

      meta = with lib; {
        description = "Wrapper zsh to generate Apple icons using icnsutil, with fixed PATH tools";
        license = licenses.mit;
        platforms = platforms.unix;
        mainProgram = exeName;
      };
    }
