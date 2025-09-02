{
  pkgs,
  lib,
  ...
}:
{
  services.xserver.enable = true;

  xdg.portal = {
    enable = true;
  };

  services = {
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
    };
    desktopManager.gnome.enable = true;
  };

  services.libinput.enable = true;

  services.gnome = {
    # gnome-initial-setup.enable = lib.mkForce false;
    # gnome-keyring.enable = lib.mkForce false;
  };

  programs.geary.enable = false;
  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.paperwm
  ];
  services.flatpak.enable = true;
}
