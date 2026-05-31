{ config, ... }:
{
  mailserver = {
    enable = true;
    fqdn = "mail.${config.networking.fqdn}";
    domains = [ config.networking.fqdn ];

    accounts = {
      "lars@muehml.eu" = {
        hashedPasswordFile = config.sops.secrets.emailHashedPassword.path;
        aliases = [ "@muehml.eu" ];
        catchAll = [ "muehml.eu" ];
      };
    };
    x509.useACMEHost = config.mailserver.fqdn;
    stateVersion = 3;
  };

  sops.secrets.emailHashedPassword = { };

  services.nginx.virtualHosts.${config.mailserver.fqdn}.enableACME = true;
}
