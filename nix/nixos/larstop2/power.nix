{
  pkgs,
  lib,
  ...
}:
{
  powerManagement.cpuFreqGovernor = "powersave";

  # programs.gamemode = {
  #   enable = true;
  #   settings.custom = {
  #     start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
  #     end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
  #   };
  # };
  services.power-profiles-daemon.enable = true;
}
