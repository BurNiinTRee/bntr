{ config, ... }:
let
  subdomain = "vault";
in
{
  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    environmentFile = config.sops.secrets.vaultwarden-env.path;
    config = {
      DOMAIN = "https://${subdomain}.${config.networking.fqdn}";
      SIGNUPS_ALLOWED = false;

      DATABASE_URL = "postgresql:///vaultwarden";

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      ROCKET_LOG = "critical";

      SMTP_HOST = "127.0.0.1";
      SMTP_PORT = 25;
      SMTP_SSL = false;

      SMTP_FROM = "vault@muehml.eu";
      SMTP_FROM_NAME = "Vaultwarden at muehml.eu";
    };
  };
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "vaultwarden" ];
    ensureUsers = [
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
    ];
  };

  sops.secrets.vaultwarden-env = {
    owner = "vaultwarden";
  };

  services.caddy.virtualHosts."${subdomain}.${config.networking.fqdn}".extraConfig = ''
    reverse_proxy http://${toString config.services.vaultwarden.config.ROCKET_ADDRESS}:${toString config.services.vaultwarden.config.ROCKET_PORT}
  '';
}
