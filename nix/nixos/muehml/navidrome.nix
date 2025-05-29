{ config, pkgs, ... }:
let
  domain = "music.${config.networking.fqdn}";
in
{
  services.navidrome = {
    enable = true;
    settings = {
      BaseUrl = "https://${domain}/";
    };
  };

  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${toString config.services.navidrome.settings.Address}:${toString config.services.navidrome.settings.Port}";
    };
  };

  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/var/lib/navidrome" = {
    device = "//u412961-sub4.your-storagebox.de/u412961-sub4";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,seal,rw,uid=navidrome,gid=navidrome,dir_mode=0770";
      in
      [ "${automount_opts},credentials=${config.sops.secrets.storage-box-navidrome.path}" ];
  };

  sops.secrets.storage-box-navidrome = { };
}
