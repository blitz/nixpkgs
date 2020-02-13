{ config, lib, ... }:

with lib;

let cfg = config.services.journal-upload;
in {

  options = {

    services.journal-upload = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Enables uploading the systemd journal to a remote system.
        '';
      };
      url = mkOption {
        default = null;
        description = ''
          The server to send the journal to. This is the URL= parameter in journal-upload.conf.
        '';
      };
      extraConfig = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra config options for systemd journal-upload. See
          <link xlink:href="https://www.freedesktop.org/software/systemd/man/journal-upload.conf.html">
          journal-upload.conf(5)</link> for available options.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    assertions = [{
      assertion = cfg.url != null;
      message = ''
        You must define `services.journal-upload.url` to set a target for the journal upload.
      '';
    }];

    # TODO Replace this with a custom service script.
    systemd.additionalUpstreamSystemUnits =
      [ "systemd-journal-upload.service" ];

    systemd.services.systemd-journal-upload = {
      wantedBy = [ "multi-user.target" ];
      restartTriggers =
        [ config.environment.etc."systemd/journal-upload.conf".source ];

      scriptArgs = "--save-state --follow";

      serviceConfig = {
        DynamicUser = true;
        StateDirectory = "journal-upload";

        # journal-upload will die when the remote end goes down. Just
        # keep restarting it in a non-aggressive manner.
        Restart = "always";
        RestartSec = "5min";

        # This group is required for accessing journald.
        SupplementaryGroups = "systemd-journal";
      };
    };

    environment.etc."systemd/journal-upload.conf".text = ''
      [Upload]
      URL=${cfg.url}
      ${cfg.extraConfig}
    '';
  };

}
