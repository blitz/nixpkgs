{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.journal-remote;
in {

  options = {

    services.journal-remote = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Enables receive systemd journals from remote systems.
        '';
      };
      listenHttp = mkOption {
        default = null;
        description = ''
          A <ip>:<port> pair to open an HTTP endpoint on. This understands the systemd
          ListenStream= format. To listen on a port, just specify the port number.
        '';
      };
      splitMode = mkOption {
        default = "host";
        description = ''
          Specify what split mode journal-remote should use. The default is to split
          logs into one logfile per host.
        '';
      };
      trust = mkOption {
        default = null;
        description = ''
          Path to CA certificate in PEM format or 'all' to accept any client.
        '';
      };
      key = mkOption {
        default = null;
        description = ''
          TUDO
        '';
      };
      cert = mkOption {
        default = null;
        description = ''
          TODO
        '';
      };
      extraConfig = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra config options for systemd journal-remote. See
          <link xlink:href="https://www.freedesktop.org/software/systemd/man/journal-remote.conf.html">
          journal-remote.conf(5)</link> for available options.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.listenHttp != null;
        message = ''
          You must define at least one of the `services.journal-upload.listen` options.
        '';
      }
      {
        assertion = cfg.trust != null;
        message = ''
          You must specify `services.journal-upload.trust` to configure who can submit logs.
        '';
      }
    ];

    # This gives us the default unit file shipped with systemd that is
    # not, because we have to override lots of things.
    #
    # systemd.additionalUpstreamSystemUnits = [
    #   "systemd-journal-remote.service" ];

    systemd.services.systemd-journal-remote = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      restartTriggers =
        [ config.environment.etc."systemd/journal-remote.conf".source ];

      serviceConfig = {
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-journal-remote --output=/var/lib/journal-remote"
                    + " --split-mode=${cfg.splitMode} --trust=${cfg.trust}"
                    + optionalString (cfg.key != null) " --key=${cfg.key}"
                    + optionalString (cfg.cert != null) " --cert=${cfg.cert}"
                    + optionalString (cfg.listenHttp != null) " --listen-http=${cfg.listenHttp}";

        DynamicUser = true;
        StateDirectory = "journal-remote";
        Restart = "always";

        # This group is required for accessing journald.
        SupplementaryGroups = "systemd-journal";
      };
    };

    environment.etc."systemd/journal-remote.conf".text = ''
      [Remote]
      ${cfg.extraConfig}
    '';
  };

}
