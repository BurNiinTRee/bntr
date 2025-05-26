{
  config,
  pkgs,
  ...
}:
let
  domain = "cloud.${config.networking.fqdn}";
in
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    autoUpdateApps.enable = true;
    hostName = domain;
    https = true;
    settings = {
      default_phone_region = "SE";
    };
    config = {
      adminpassFile = config.sops.secrets.nx-initial-admin-pass.path;
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
    };
    enableImagemagick = true;
    configureRedis = true;
  };

  sops.secrets.nx-initial-admin-pass = {
    owner = "nextcloud";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      forceSSL = true;
    };
  };

  # For mount.cifs, required unless domain name resolution is not needed.
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/var/lib/nextcloud/data" = {
    device = "//u412961-sub1.your-storagebox.de/u412961-sub1";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,seal,rw,uid=nextcloud,gid=nextcloud,dir_mode=0770";
      in
      [ "${automount_opts},credentials=${config.sops.secrets.storage-box-nc.path}" ];
  };

  sops.secrets.storage-box-nc = { };
}
