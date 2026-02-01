# vim: filetype=nix: tabstop=2: shiftwidth=2: expandtab:
let
  pkgs = (import <nixpkgs>) {};

  jdk-def = pkgs.openjdk25 or pkgs.zulu25 or pkgs.jdk25 or pkgs.openjdk or pkgs.zulu or pkgs.jdk;

  mkiconapple-flake = builtins.getFlake "github:juanma151/mk-icon-apple";
in
  {
    system ? pkgs.system,
    stdenvNoCC ? pkgs.stdenvNoCC,
    netbeans ? pkgs.netbeans,
    mkiconapple ? mkiconapple-flake.out.packages.system.mkiconapple,
    jdkPkg ? jdk-def,
  }: let
    jdk-version = builtins.replaceStrings ["."] ["_"] jdkPkg.version;

    jdk-simple-version_arr = builtins.match "[^A-Za-z0-9]*([A-Za-z0-9]+).*" jdkPkg.version;

    jdk-simple-version =
      if (builtins.length jdk-simple-version_arr > 0)
      then builtins.head jdk-simple-version_arr
      else "XX";

    version = "${netbeans.version}-jdk${jdk-version}";

    iconRoot = "${netbeans}/share/icons/hicolor";
  in
    stdenvNoCC.mkDerivation {
      pname = "netbeans-macwrapp";
      inherit version;

      dontUnpack = true;

      nativeBuildInputs = [
        mkiconapple
      ];

      buildPhase = ''
        set -euo pipefail

        mkdir -p "build/icon"

        # Generate the .icns file
        ${mkiconapple}/bin/mkiconapple \
          --out      "build/NetBeans.icns" \
          --workdir  "${iconRoot}"  \
          --regex    "([0-9]##)x" \
          --globpath "*/apps/*.png"
      '';

      installPhase = ''
            set -euo pipefail

            app="$out/Applications/NetBeans-JDK25.app"
            mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

            # Launcher: force the runtime JDK to openjdk25 from nixpkgs
            cat > "$app/Contents/MacOS/netbeans" <<'SH'
        #!/usr/bin/env bash
        set -euo pipefail
        exec "${netbeans}/bin/netbeans" --jdkhome "${jdkPkg}" "$@"
        SH

            chmod +x "$app/Contents/MacOS/netbeans"

            # Copy icon generated during buildPhase
            cp "build/NetBeans.icns" "$app/Contents/Resources/NetBeans.icns"

            # Minimal Info.plist + icon reference
            cat > "$app/Contents/Info.plist" <<'PLIST'
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        <key>CFBundleName</key>
        <string>NetBeans</string>

        <key>CFBundleDisplayName</key>
        <string>NetBeans (JDK ${jdk-simple-version})</string>

        <key>CFBundleIdentifier</key>
        <string>org.apache.netbeans.nix.jdk${jdk-simple-version}</string>

        <key>CFBundleExecutable</key>
        <string>netbeans</string>

        <key>CFBundlePackageType</key>
        <string>APPL</string>

        <key>CFBundleIconFile</key>
        <string>NetBeans</string>

        <!-- Adjust if needed for your macOS version -->
        <key>LSMinimumSystemVersion</key>
        <string>14.0</string>
        </dict>
        </plist>
        PLIST
      '';
    }
