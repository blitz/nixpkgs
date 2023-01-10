{ gcc7Stdenv, requireFile, lib,
  libcxx, libcxxabi
}:

let
  libcxx7 = libcxx.override {
    stdenv = gcc7Stdenv;
  };

  libcxxabi7 = libcxxabi.override {
    stdenv = gcc7Stdenv;
  };

in
gcc7Stdenv.mkDerivation rec {
  pname = "blackmagic-desktop-video";
  major = "12.4.1";
  version = "${major}a15";

  buildInputs = [
    libcxx7 libcxxabi7
  ];

  src = requireFile {
    name = "Blackmagic_Desktop_Video_Linux_${major}.tar.gz";
    url = "https://www.blackmagicdesign.com/support/download/17722a6d499b4431a31f29b32a937656/Linux";
    sha256 = "d5363b15d305e5484fa62af16b1bd11a296746442dc82c4481d5b193bbbabf3e";
  };

  setSourceRoot = ''
    tar xf Blackmagic_Desktop_Video_Linux_${major}/other/x86_64/desktopvideo-${version}-x86_64.tar.gz
    sourceRoot=$NIX_BUILD_TOP/desktopvideo-${version}-x86_64
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/doc,lib/systemd/system}
    cp -r $sourceRoot/usr/share/doc/desktopvideo $out/share/doc
    cp $sourceRoot/usr/lib/*.so $out/lib
    cp $sourceRoot/usr/lib/systemd/system/DesktopVideoHelper.service $out/lib/systemd/system
    cp $sourceRoot/usr/lib/blackmagic/DesktopVideo/libgcc_s.so.1 $out/lib/
    cp $sourceRoot/usr/lib/blackmagic/DesktopVideo/DesktopVideoHelper $out/bin/

    substituteInPlace $out/lib/systemd/system/DesktopVideoHelper.service --replace "/usr/lib/blackmagic/DesktopVideo/DesktopVideoHelper" "$out/bin/DesktopVideoHelper"

    runHook postInstall
  '';


  postFixup = ''
    patchelf --set-interpreter ${gcc7Stdenv.cc.bintools.dynamicLinker} \
      --set-rpath "$out/lib:${lib.makeLibraryPath [ libcxx7 libcxxabi7 ]}" \
      $out/bin/DesktopVideoHelper
  '';

  meta = with lib; {
    homepage = "https://www.blackmagicdesign.com/support/family/capture-and-playback";
    maintainers = [ maintainers.hexchen ];
    license = licenses.unfree;
    description = "Supporting applications for Blackmagic Decklink. Doesn't include the desktop applications, only the helper required to make the driver work.";
    platforms = platforms.linux;
  };
}
