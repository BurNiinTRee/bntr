{
  config,
  pkgs,
  lib,
  selfLocation,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Europe/Stockholm";

  environment.systemPackages = with pkgs; [
    file
    helix
    wget
  ];
  environment.variables.EDITOR = "hx";

  sops.defaultSopsFile = ../../secrets/muehml.eu.yaml;
  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [ "/home/user/.ssh/id_ed25519" ];

  users.users.user = {
    description = "Lars Mühmel";
    isNormalUser = true;
    initialHashedPassword = "$y$j9T$uybR5rKgVQ5.l/vWvpwYr/$7KxxPR/4ygU2nnKbsEEoH0wh/laRcOgic/yesW2p3P/";
    extraGroups = [
      "audio"
      "libvirtd"
      "kvm"
      "networkmanager"
      "video"
      "wheel"
      "plugdev"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgevajch6O5ZQYWubHgaRZPnhrFM937mjUQO4gT+Bnr user@bluefin"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = config.users.users.user.openssh.authorizedKeys.keys;

  system.fsPackages = [ pkgs.rclone ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "yes";
    };
  };

  # hardware.tuxedo-rs = {
  #   enable = true;
  #   tailor-gui.enable = true;
  # };

  specialisation.no-comin.configuration = {
    services.comin.enable = lib.mkForce false;
  };

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "old";
        url = "https://github.com/BurNiinTRee/nix-sources.git";
      }
      {
        name = "github";
        url = "https://github.com/BurNiinTRee/bntr.git";
      }
      {
        name = "local";
        url = selfLocation;
        poller.period = 2;
      }
    ];
  };

  # Keyboard udev rules
  services.udev.extraRules = ''
    # Rules for Oryx web flashing and live training
    KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

    # Legacy rules for live training over webusb (Not needed for firmware v21+)
      # Rule for all ZSA keyboards
      SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
      # Rule for the Moonlander
      SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"
      # Rule for the Ergodox EZ
      SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"
      # Rule for the Planck EZ
      SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="plugdev"

    # Wally Flashing rules for the Ergodox EZ
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

    # Keymapp / Wally Flashing rules for the Moonlander and Planck EZ
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
    # Keymapp Flashing rules for the Voyager
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
  '';

  services.sysprof.enable = true;

  system.stateVersion = "23.05";
}
