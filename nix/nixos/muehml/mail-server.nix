{ config, ... }:
{
  mailserver = {
    enable = true;
    fqdn = "mail.${config.networking.fqdn}";
    domains = [ config.networking.fqdn ];

    loginAccounts = {
      "lars@muehml.eu" = {
        hashedPasswordFile = config.sops.secrets.emailHashedPassword.path;
        aliases = [ "@muehml.eu" ];
        catchAll = [ "muehml.eu" ];
      };
    };
    certificateScheme = "acme-nginx";
    stateVersion = 3;
  };

  sops.secrets.emailHashedPassword = { };
}
