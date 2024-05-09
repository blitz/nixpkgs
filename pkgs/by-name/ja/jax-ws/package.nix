{ lib, fetchFromGitHub, jre, makeWrapper, maven, git }:

maven.buildMavenPackage rec {
  pname = "jaxws-ri";
  version = "3.0.2";

  src = fetchFromGitHub {
    owner = "eclipse-ee4j";
    repo = "metro-jax-ws";
    rev = "${version}";
    hash = "sha256-j4SvANQVwn17oBMPp90vuzr0E0wn7Qj4gzLJzcazh/o=";
  };

  sourceRoot = "source/jaxws-ri";

  # Tests take a long time and are flaky.
  mvnParameters = "-Dmaven.test.skip=true -DskipTests";

  mvnHash = "";

  nativeBuildInputs = [ makeWrapper git ];
  buildInputs = [ jre ];

  preInstall = ''
    find
  '';

  # installPhase = ''
  #   #mkdir -p $out/bin $out/share/jd-cli
  #   #install -Dm644 jd-cli/target/jd-cli.jar $out/share/jd-cli

  #   makeWrapper ${jre}/bin/java $out/bin/jd-cli \
  #     --add-flags "-jar $out/share/jd-cli/jd-cli.jar"
  # '';

  meta = with lib; {
    description = "Tooling around implementing XML-Based Web Services, provides wsimport";
    homepage = "https://github.com/jakartaee/jax-ws-api";
    license = licenses.bsd3;
    maintainers = with maintainers; [ blitz ];
  };
}
