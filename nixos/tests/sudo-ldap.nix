let
  bindDn = "cn=root,dc=example";
  bindPw = "notapassword";
  userPassword = "insecurePassword";
in
import ./make-test-python.nix {
  name = "sudo-ldap";

  nodes = {
    server = { pkgs, ... }: {

      # LDAP port
      networking.firewall.allowedTCPPorts = [ 389 ];

      services.openldap = {
        enable = true;
        suffix = "dc=example";
        rootdn = bindDn;
        rootpw = bindPw;
        database = "bdb";
        extraDatabaseConfig = ''
          directory /var/db/openldap
        '';
        declarativeContents = ''
          dn: dc=example
          objectClass: domain
          dc: example

          dn: ou=users,dc=example
          objectClass: organizationalUnit
          ou: users

          dn: uid=adam,ou=users,dc=example
          objectClass: top
          objectClass: account
          objectClass: posixAccount
          objectClass: shadowAccount
          cn: adam
          uid: adam
          uidNumber: 16859
          gidNumber: 100
          homeDirectory: /home/adam
          loginShell: /bin/sh
          gecos: adam
          userPassword: ${userPassword}
          shadowLastChange: 0
          shadowMax: 0
          shadowWarning: 0
        '';
      };
    };

    client = { pkgs, ... }: {

      # Don't do this for a real LDAP client, because it makes the
      # password world readable.
      environment.etc."ldap.pw".text = bindPw;

      # Enable LDAP Login
      users.ldap = {
        enable = true;
        base = "dc=example";
        server = "ldap://server/";

        bind = {
          distinguishedName = bindDn;
          passwordFile = "/etc/ldap.pw";
        };

        extraConfig = ''
          # tls_cacertfile /etc/ssl/certs/ca-certificates.crt
          ldap_version 3
          pam_lookup_policy yes
          pam_password exop
        '';
      };

      # Tools
      environment.systemPackages = [ pkgs.openldap pkgs.bash ];

    };

  };

  testScript = ''
    server.wait_for_unit("openldap.service")
    client.wait_for_unit("multi-user.target")
  '';
}
