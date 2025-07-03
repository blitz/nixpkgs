{ lib,
  stdenvNoCC,
  rpmextract,
  fetchurl,
  autoPatchelfHook,
  alsa-lib,
  freetype,
  fontconfig,
  xorg,
  zlib,
  makeWrapper,
  jre
}:


stdenvNoCC.mkDerivation {
  pname = "configuradorfnmt";
  version = "4.0.6";

  src = fetchurl {
    url = "https://descargas.cert.fnmt.es/Linux/configuradorfnmt-4.0.6-0.x86_64.rpm";
    hash = "sha256-osVk3cH16HscR6/BlqfvHWtIROWfyLFc2CglDcnUPwM=";
  };

  nativeBuildInputs = [
    rpmextract
  ];

  buildInputs = [
  ];

  unpackPhase = ''
    rpmextract $src
  '';

  installPhase = ''
    runHook preInstall

    mv usr $out

    # We don't need the prepackaged JRE.
    find $out
    rm -r $out/lib64/configuradorfnmt/jre

    runHook postInstall
  '';

  postFixup = ''

    substituteInPlace $out/bin/configuradorfnmt \
      --replace-fail /usr/lib64/configuradorfnmt/jre ${jre} \
      --replace-fail /usr $out

    substituteInPlace $out/share/applications/configuradorfnmt.desktop \
      --replace-fail /usr $out
  '';

  meta = {
    description = "blub";
    maintainers = with lib.maintainers; [ blitz ];
    # sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    # license = lib.licenses.unfree;
    # homepage = "https://myroom.hpe.com";
    # # TODO: A Darwin binary is available upstream
    # platforms = [ "x86_64-linux" ];
    # mainProgram = "hpmyroom";
    # broken = true; # requires libpng15
  };

}
