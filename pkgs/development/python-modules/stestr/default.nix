{ lib
, buildPythonPackage
, isPy27
, fetchPypi
, pbr
, cliff
, testtools
, fixtures
, voluptuous
, subunit
, future
, stestr
, testVersion
}:

buildPythonPackage rec {
  pname = "stestr";
  version = "3.2.0";

  # Since version 3.0.0, stestr doesn't support Python 2.7 anymore.
  disabled = isPy27;

  src = fetchPypi {
    inherit pname version;
    sha256 = "1i1b2z44ja8sbkqhaxyxc2xni6m9hky4x0254s0xdzfkyfyjqjgv";
  };

  propagatedBuildInputs = [ pbr cliff testtools fixtures voluptuous subunit future ];

  # This package needs itself for testing, which is somewhat
  # inconvenient.
  doCheck = false;

  passthru = {
    tests = {
      version = testVersion {
        package = stestr;
      };
    };
  };

  meta = with lib; {
    description = "A parallel Python test runner built around subunit";
    homepage = "https://github.com/mtreinish/stestr";
    license = licenses.asl20;
    maintainers = with maintainers; [ blitz ];
  };
}
