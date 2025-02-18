{
  bubblewrap,
  unzip,
  stdenv,
  ...
}: {
  mkPackage = {
    software,
    version,
    url,
    sha256,
    ...
  }:
    stdenv.mkDerivation {
      pname = software;
      inherit version;

      src = builtins.fetchurl {
        inherit url sha256;
      };

      nativeBuildInputs = [unzip bubblewrap];

      dontInstall = true;

      unpackPhase = ''
        unzip $src
      '';

      buildPhase = ''
        set -x

        INSTALL_TARGET="$(mktemp -d)"

        mkdir -p $INSTALL_TARGET/{.sdm,bin,.bin,etc/sysconfig,etc/init.d}

        bwrap \
          --ro-bind /etc/passwd /etc/passwd \
          --ro-bind /nix/store /nix/store \
          --bind /build /build \
          --bind $INSTALL_TARGET/etc/sysconfig /etc/sysconfig \
          --bind $INSTALL_TARGET/etc/init.d /etc/init.d \
          --bind $INSTALL_TARGET/bin /opt/strongdm/bin \
          --bind $INSTALL_TARGET/.bin /usr/local/bin \
          --proc /proc \
          --dev /dev \
          --uid 0 \
            /build/sdm install --user nixbld --nostart --nologin

        mkdir -p $out/bin
        cp -a $INSTALL_TARGET/bin $out

        rm -rf $out/.bin

        find .sdm/

        set +x
      '';
    };
}
