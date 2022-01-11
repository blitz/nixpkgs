{ stdenv, lib, fetchFromGitHub, cmake, pkg-config
, obs-studio, onnxruntime, opencv
}:

stdenv.mkDerivation rec {
  pname = "obs-backgroundremoval";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "royshil";
    repo = "obs-backgroundremoval";
    rev = "v${version}";
    sha256 = "TI1FlhE0+JL50gAZCSsI+g8savX8GRQkH3jYli/66hQ=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ obs-studio onnxruntime opencv ];

  postPatch = ''
    # See https://github.com/royshil/obs-backgroundremoval/issues/71
    substituteInPlace CMakeLists.txt \
      --replace 'version_from_git()' 'set(VERSION ${version})'

    # substituteInPlace src/background-filter.cpp \
    #     --replace 'defined(__APPLE__)' '1'
    
    # head src/background-filter.cpp
    #   --replace 'onnxruntime_cxx_api.h' 'onnxruntime/core/session/onnxruntime_cxx_api.h' \
    #   --replace 'cpu_provider_factory.h' 'onnxruntime/core/providers/cpu/cpu_provider_factory.h' \
  '';

  NIX_CFLAGS_COMPILE = "-I${onnxruntime.dev}/include/onnxruntime/core/session -I${onnxruntime.dev}/include/onnxruntime/core/providers/cpu";

  meta = with lib; {
    description = "OBS Studio plugin that removes video backgrounds";
    license = licenses.mit;
    maintainers = with maintainers; [ blitz ];
    platforms = [ "x86_64-linux" ];
  };
}
