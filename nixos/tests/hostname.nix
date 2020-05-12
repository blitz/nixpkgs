{ system ? builtins.currentSystem,
  config ? {},
  pkgs ? import ../.. { inherit system config; }
}:

with import ../lib/testing-python.nix { inherit system pkgs; };
with pkgs.lib;

let
  makeHostNameTest = hostName: domain:
    let
      fqdn = hostName + (optionalString (domain != null) ".${domain}");
    in
      makeTest {
        name = "hostname-${fqdn}";

        machine = { lib, ... }: {
          networking.hostName = hostName;
          networking.domain = domain;

          environment.systemPackages = with pkgs; [
            inetutils
          ];
        };
        
        testScript = ''
          start_all()

          machine = ${hostName}

          machine.wait_for_unit("network.target")
          assert "${fqdn}" == machine.succeed("hostname --fqdn").strip()
          assert "${optionalString (domain != null) domain}" == machine.succeed("dnsdomainname").strip()
          assert (
              "${fqdn}"
              == machine.succeed(
                  'hostnamectl status | grep "Static hostname" | cut -d: -f2'
              ).strip()
          )
        '';
      };
    
in
{
  noExplicitDomain = makeHostNameTest "ahost" null;

  # Fails due to #10183
  # explicitDomain = makeHostNameTest "ahost" "adomain";
}

