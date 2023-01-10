{ stdenv, lib, requireFile, fetchpatch, kernel }:

stdenv.mkDerivation rec {
  pname = "decklink";
  major = "12.4.1";
  version = "${major}a15";

  src = requireFile {
    name = "Blackmagic_Desktop_Video_Linux_${major}.tar.gz";
    url = "https://www.blackmagicdesign.com/support/download/17722a6d499b4431a31f29b32a937656/Linux";
    sha256 = "d5363b15d305e5484fa62af16b1bd11a296746442dc82c4481d5b193bbbabf3e";
  };

  KERNELDIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
  INSTALL_MOD_PATH = placeholder "out";

  nativeBuildInputs =  kernel.moduleBuildDependencies;

  setSourceRoot = ''
    tar xf Blackmagic_Desktop_Video_Linux_${major}/other/x86_64/desktopvideo-${version}-x86_64.tar.gz
    sourceRoot=$NIX_BUILD_TOP/desktopvideo-${version}-x86_64/usr/src
  '';

  buildPhase = ''
    runHook preBuild

    make -C $sourceRoot/blackmagic-${version} -j$NIX_BUILD_CORES
    make -C $sourceRoot/blackmagic-io-${version} -j$NIX_BUILD_CORES

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    make -C $KERNELDIR M=$sourceRoot/blackmagic-${version} modules_install
    make -C $KERNELDIR M=$sourceRoot/blackmagic-io-${version} modules_install

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://www.blackmagicdesign.com/support/family/capture-and-playback";
    maintainers = [ maintainers.hexchen ];
    license = licenses.unfree;
    description = "Kernel module for the Blackmagic Design Decklink cards";
    platforms = platforms.linux;
  };
}
