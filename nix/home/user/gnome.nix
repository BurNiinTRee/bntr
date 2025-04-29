{
  config,
  lib,
  pkgs,
  ...
}:
{
  persist.files = [
    ".config/monitors.xml"
    ".config/gnome-initial-setup-done"
  ];
  persist.directories = [
    ".config/goa-1.0"
  ];

  dconf.settings = lib.mkIf config.muehml.guiApps {
    "org/gnome/desktop/input-sources" = {
      sources = [
        (lib.hm.gvariant.mkTuple [
          "xkb"
          "eu"
        ])
        (lib.hm.gvariant.mkTuple [
          "xkb"
          "us+engram"
        ])
      ];
      xkb-options = [ "caps:escape" ];
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "librewolf.desktop"
        "thunderbird.desktop"
        "org.gnome.Nautilus.desktop"
        "com.mitchellh.ghostty.desktop"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "ghostty";
      name = "Launch Terminal";
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    "org/gnome/mutter" = {
      attach-modal-dialogs = false;
      workspaces-only-on-primary = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      resize-with-right-button = true;
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
    };
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
    };
    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;
    };
    "org/gnome/desktop/default-applications/terminal" = {
      exec = "ghostty";
    };
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };
    "org/gnome/Console" = {
      theme = "auto";
      shell = [
        "zellij"
        "-l"
        "welcome"
      ];
    };
    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };
    "org/gnome/desktop/interface" = {
      clock-show-seconds = true;
      clock-show-weekday = true;
      monospace-font-name = "Fira Code 10";
    };
    "org/gnome/desktop/background" = lib.mkIf config.muehml.nixosIntegration {
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/glass-chip-l.jxl";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/glass-chip-d.jxl";
    };
    "org/gnome/desktop/screensaver" = lib.mkIf config.muehml.nixosIntegration {
      picture-uri = config.dconf.settings."org/gnome/desktop/background".picture-uri;
    };
  };
}
