{ stdenv, lib, fetchFromGitHub, cmake, pkg-config
, obs-studio,
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
  buildInputs = [ obs-studio ];

  postPatch = ''
    # See https://github.com/royshil/obs-backgroundremoval/issues/71
    substituteInPlace CMakeLists.txt \
      --replace 'version_from_git()' 'set(VERSION ${version})'
  '';

  meta = with lib; {
    description = "OBS Studio plugin that removes video backgrounds";
    license = licenses.mit;
    maintainers = with maintainers; [ blitz ];
    platforms = [ "x86_64-linux" ];
  };
}
