import ./make-test-python.nix ({ pkgs, ... }: let
  inherit (import ./ssh-keys.nix pkgs)
    snakeOilPrivateKey snakeOilPublicKey;

  commonConfig = { pkgs, ... }: {
    virtualisation.emptyDiskImages = [ 2048 ];
    boot.supportedFilesystems = [ "zfs" ];
  };
in {
  name = "znapzend";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ blitz ];
  };

  nodes = {
    source = { ... }: {
      imports = [ commonConfig ];
      networking.hostId = "daa82e91";

      programs.ssh.extraConfig = ''
        UserKnownHostsFile=/dev/null
        StrictHostKeyChecking=no
      '';

      services.znapzend = {
        enable = true;
        debug = true;

        zetup = {
          "pool" = {
            plan = "25h=>1h";
            recursive = true;
            destinations.remote = {
              host = "root@target";
              dataset = "pool/test";
              plan = "1d=>1h,1w=>1d,1m=>1w,1y=>1m,10y=>1y";
            }
          };
        };
      };
    };

    target = { ... }: {
      imports = [ commonConfig ];
      networking.hostId = "dcf39d36";

      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = [ snakeOilPublicKey ];
    };
  };

  testScript = ''
    source.succeed(
        "mkdir /tmp/mnt",
        "zpool create pool /dev/vdb",
        "zfs create -o mountpoint=legacy pool/test",
        "mount -t zfs pool/test /tmp/mnt",
        "udevadm settle",
    )
    target.succeed(
        "zpool create pool /dev/vdb",
        "udevadm settle",
    )

    source.succeed(
        "mkdir -m 700 -p /root/.ssh",
        "cat '${snakeOilPrivateKey}' > /root/.ssh/id_ecdsa",
        "chmod 600 /root/.ssh/id_ecdsa",
    )

    source.succeed("touch /tmp/mnt/test.txt")
    target.wait_for_open_port(22)

    source.systemctl("start --wait znapzend.service")

    target.succeed(
        "mkdir /tmp/mnt",
        "zfs set mountpoint=legacy pool/test",
        "mount -t zfs pool/test /tmp/mnt",
    )
    target.succeed("cat /tmp/mnt/test.txt")
  '';
})
