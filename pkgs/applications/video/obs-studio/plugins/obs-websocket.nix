{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, cmake
, qtbase
, qtsvg
, obs-studio
, asio_1_10
, websocketpp
, nlohmann_json
}:

stdenv.mkDerivation rec {
  pname = "obs-websocket";
  version = "5.0.0-alpha3";

  src = fetchFromGitHub {
    owner = "Palakis";
    repo = "obs-websocket";
    rev = version;
    sha256 = "Lr6SBj5rRTAWmn9Tnlu4Sl7SAkOCRCTP6sFWSp4xB+I=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    qtbase
    qtsvg
    obs-studio
    asio_1_10
    websocketpp
    nlohmann_json
  ];

  dontWrapQtApps = true;

  cmakeFlags = [
    "-DLIBOBS_INCLUDE_DIR=${obs-studio.src}/libobs"
  ];

  meta = with lib; {
    description = "Remote-control OBS Studio through WebSockets";
    homepage = "https://github.com/Palakis/obs-websocket";
    maintainers = with maintainers; [ erdnaxe ];
    license = licenses.gpl2Plus;
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
}
