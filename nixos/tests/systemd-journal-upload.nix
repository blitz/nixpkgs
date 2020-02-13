# Regression test for systemd-timesync having moved the state directory without
# upstream providing a migration path. https://github.com/systemd/systemd/issues/12131

import ./make-test-python.nix ({ pkgs, ... } : let

  runWithOpenSSL = file: cmd: pkgs.runCommand file {
    buildInputs = [ pkgs.openssl ];
  } cmd;

  makeRsaKey = name: runWithOpenSSL name "openssl genrsa -out $out 2048";

  ca_key = makeRsaKey "ca.key";
  ca_pem = runWithOpenSSL "ca.pem" "openssl req -x509 -nodes -key=${ca_key} -out=$out -subj '/CN=Certificate authority/'";

  openssl_cnf = pkgs.writeText "openssl.cnf" ''
    [ ca ]
    default_ca = this

    [ this ]
    certificate = ${ca_pem}
    private_key = ${ca_key}
    default_days = 3650
    default_md = default
    policy = policy_anything

    [ policy_anything ]
    countryName             = optional
    stateOrProvinceName     = optional
    localityName            = optional
    organizationName        = optional
    organizationalUnitName  = optional
    commonName              = supplied
    emailAddress            = optional
  '';

  server_key = makeRsaKey "server.key";
  server_csr = runWithOpenSSL "server.csr" "openssl req -key ${server_key} -nodes -out $out -subj /CN=Server/";
  server_crt = runWithOpenSSL "server.crt" "openssl x509 -req -in ${server_csr} -CA ${ca_pem} -CAkey ${ca_key} -out $out";

  common = { lib, ... }: {
  };
  mkVM = conf: { imports = [ conf common ]; };
in {
  name = "systemd-journal-upload";
  nodes = {
    server = mkVM {

      services.journal-remote = {
        enable = true;
        listenHttp = "19531";
        trust = "all";

        #key = ca_key;

      };

      networking.firewall.allowedTCPPorts = [ 19531 ];
    };

    client = mkVM {
      services.journal-upload.enable = true;
      services.journal-upload.url = "http://server:19531";
    };
  };

  # TODO The server currently fails to write logs:
  # client # [    6.700533] systemd-journal-upload[794]: Upload to http://server:19531/upload failed with code 500: Unknown error -13
  # server # [   55.511352] ...-unit-script-systemd-journal-remote-start[737]: Failed to open output journal /var/log/journal/remote/remote-192.168.1.1.journal: Permission denied
  # server # [   55.512903] ...-unit-script-systemd-journal-remote-start[737]: Failed to get writer for source 192.168.1.1: Permission denied
  #
  # Maybe we should set the output to the state directory.
  #
  # Also we need to autorestart journal-upload and journal-reload

  testScript = ''
    server.start()
    server.wait_for_unit("systemd-journal-remote.service")

    client.start()
    client.wait_for_unit("systemd-journal-upload.service")
  '';
})
