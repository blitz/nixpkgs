{ lib, stdenv, fetchFromGitHub,  gnumake, elfutils, bashInteractive }:
stdenv.mkDerivation (finalAttrs: {
  pname = "kpatch";
  version = "0.9.9";

  src = fetchFromGitHub {
    owner = "dynup";
    repo = "kpatch";
    rev = "v${finalAttrs.version}";
    hash = "sha256-D3hCcjT0kHMmBHgMFFmFyP5hQrJJnLghoKbJ7chOZfs=";
  };

  nativeBuildInputs = [
    gnumake
  ];

  makeFlags = [
    "CC=${stdenv.cc.targetPrefix}cc"
    "INSTALL=install"
    "PREFIX=$(out)"

    # The upstart files are not useful, but it's easier to install
    # them somewhere where they are ignored than patching the source.
    "UPSTARTDIR=$out/etc/upstart"
  ];

  buildInputs = [
    elfutils

    # We want kpatch-build to be wrapped in this bash. This is
    # important, because kpatch-build uses compgen, which is not
    # available in normal bash.
    bashInteractive
  ];

  enableParallelBuilding = true;

  outputs = [ "out" "man" ];

  postPatch = ''
    substituteInPlace kpatch-build/kpatch-build \
      --replace 'die "Unsupported distribution"' 'echo "WARN: Skipping distro check..."'
  '';

  postInstall = ''
    # Unused upstart service.
    rm -rf $out/etc

    # Unused systemd service.
    rm -rf $out/lib
  '';

  meta = with lib; {
    description = "Dynamic kernel patching utilities";
    homepage = "https://github.com/dynup/kpatch";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ blitz ];
    mainProgram = "kpatch";
    platforms = lib.platforms.linux;
  };
})
