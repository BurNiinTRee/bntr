{
  config,
  pkgs,
  ...
}:
let
  subdomain = "attic";
in
{
  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets.attic-credentials.path;
    settings = {
      listen = "[::]:43234";
      allowed-hosts = [ "${subdomain}.${config.networking.fqdn}" ];
      database.url = "postgresql:///?host=/run/postgresql";
      chunking = {
        nar-size-threshold = 64 * 1024; # 64KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 128 KiB
      };
    };
  };

  systemd.services.atticd = {
    unitConfig = {
      RequiresMountsFor = [ config.services.atticd.settings.storage.path ];
    };
    serviceConfig = {
      LoadCredentials = "credentials:${config.sops.secrets.attic-credentials.path}";
    };
  };

  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems.${config.services.atticd.settings.storage.path} = {
    device = "//u412961-sub3.your-storagebox.de/u412961-sub3";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,seal,rw,uid=${config.services.atticd.user},gid=${config.services.atticd.group},dir_mode=0770";
      in
      [ "${automount_opts},credentials=${config.sops.secrets.storage-box-attic.path}" ];
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ config.services.atticd.user ];
    ensureUsers = [
      {
        name = config.services.atticd.user;
        ensureDBOwnership = true;
      }
    ];
  };

  services.caddy.virtualHosts."${subdomain}.${config.networking.fqdn}".extraConfig = ''
    reverse_proxy http://${toString config.services.atticd.settings.listen}
  '';
  # extraConfig = "client_max_body_size 1G;";

  sops.secrets = {
    attic-credentials = { };
    storage-box-attic = { };
  };
}
