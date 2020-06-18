# Test whether a failover setup of the ISC dhcp server works as
# intended.
#
# The test is adapted from this blog post:
# https://kb.isc.org/docs/aa-00502

let
  dhcpIf = "eth1";

  dhcpServer = ipAddr: dhcpExtraConfig:
    { config, pkgs, ... }: {
      virtualisation.vlans = [ 1 ];

      networking = {
        firewall.enable = false;

        interfaces.eth1 = {
          useDHCP = false;
          ipv4.addresses = [{
            address = ipAddr;
            prefixLength = 24;
          }];
        };
      };

      services.dhcpd4 = {
        enable = true;
        interfaces = [ dhcpIf ];

        extraConfig = dhcpExtraConfig;
      };
    };

  omapiConfig = ''
    omapi-port 7911;
    omapi-key omapi_key;

    key omapi_key {
      algorithm hmac-md5;
      secret Ofakekeyfakekeyfakekey==;
    }
  '';

  subnetConfig = ''
    subnet 10.0.0.0 netmask 255.255.255.0 {
      pool {
        failover peer "failover-partner";
        range 10.0.0.20 10.0.0.150;
      }
    }
  '';

  dhcpPrimary = ipAddr: peerAddr:
    dhcpServer ipAddr ''
      ${omapiConfig}

      failover peer "failover-partner" {
        primary;
        address ${ipAddr};
        port 519;
        peer address ${peerAddr};
        peer port 520;
        max-response-delay 60;
        max-unacked-updates 10;
        mclt 3600;
        split 128;
        load balance max seconds 3;
      }

      ${subnetConfig}
    '';

  dhcpSecondary = ipAddr: peerAddr:
    dhcpServer ipAddr ''
      ${omapiConfig}

      failover peer "failover-partner" {
        secondary;
        address ${ipAddr};
        port 520;
        peer address ${peerAddr};
        peer port 519;
        max-response-delay 60;
        max-unacked-updates 10;
        load balance max seconds 3;
      }

      ${subnetConfig}
    '';

  dhcpClient = { config, pkgs, ... }: {
    virtualisation.vlans = [ 1 ];
    networking.interfaces.eth1.useDHCP = true;
  };

in import ./make-test-python.nix ({ pkgs, ... }: {
  name = "dhcpd-failover";
  meta = with pkgs.stdenv.lib.maintainers; { maintainers = [ blitz ]; };
  nodes = {

    router = dhcpPrimary "10.0.0.1" "10.0.0.2";
    routerFailover = dhcpSecondary "10.0.0.2" "10.0.0.1";

    client1 = dhcpClient;
    client2 = dhcpClient;
    client3 = dhcpClient;
  };

  testScript = { ... }: ''
    import shlex

    # Wait until the DHCP daemon log matches the given regex.
    #
    # Beware that it also matches all old entries!
    def wait_until_log(s, regex):
        s.wait_until_succeeds(
            "journalctl --boot -u dhcpd4 -g {}".format(shlex.quote(regex))
        )


    router.start()
    router.wait_for_unit("network-online.target")

    routerFailover.start()
    routerFailover.wait_for_unit("network-online.target")

    wait_until_log(router, "Both servers normal")

    # Start the first client in the happy case where both DHCP servers are available.
    client1.start()
    client1.wait_for_unit("network-online.target")
    client1.wait_until_succeeds("ping -c 5 10.0.0.1")

    # Take down the primary and wait until the secondary notices. This takes a bit.
    router.block()
    wait_until_log(routerFailover, "I move from normal to communications-interrupted")

    # Start the second client in the degraded case where the primary is gone.
    client2.start()
    client2.wait_for_unit("network-online.target")
    client2.wait_until_succeeds("ping -c 5 10.0.0.2")

    # Bring back the primary and check whether both servers go back to normal.
    router.unblock()
    wait_until_log(router, "peer moves from communications-interrupted to normal")

    client3.start()
    client3.wait_for_unit("network-online.target")
    client3.wait_until_succeeds("ping -c 5 10.0.0.1")
  '';
})
