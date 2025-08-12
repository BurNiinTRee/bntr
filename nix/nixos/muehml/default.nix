{
  config,
  pkgs,
  lib,
  flakeInputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./atticd.nix
    ./impermanence.nix
    ./grafana.nix
    ./mail-server.nix
    ./navidrome.nix
    ./nextcloud-server.nix
    ./paperless.nix
    ./vaultwarden.nix
  ];

  services.journald.extraConfig = "SystemMaxUse=50M";

  sops.defaultSopsFile = ../../secrets/muehml.eu.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.netrc-muehml = { };
  nix.settings.netrc-file = config.sops.secrets.netrc-muehml.path;
  nix.settings.substituters = [ "https://attic.muehml.eu/ci" ];
  nix.settings.trusted-public-keys = [ "ci:pGN5GUIYtBiawlMyFIapGrGbUT8N1misYuS6iW90neU=" ];

  nix = {
    gc = {
      automatic = true;
      dates = "03:00";
      options = "-d";
    };
    optimise = {
      automatic = true;
      dates = [ "03:30" ];
    };
    nixPath = [ "nixpkgs=/etc/nixpkgs" ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  nix.registry.nixpkgs = {
    from = {
      id = "nixpkgs";
      type = "indirect";
    };
    flake = flakeInputs.nixpkgs-stable;
  };
  environment.etc."nixpkgs".source = flakeInputs.nixpkgs-stable;
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "corefonts"
    ];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "github";
        url = "https://github.com/BurNiinTRee/bntr.git";
      }
    ];
  };

  services.fail2ban = {
    enable = true;
    jails = {
      dovecot = ''
        enabled = true
        filter = dovecot[mode=aggressive]
        maxretry = 5
      '';
      nextcloud = ''
        enabled = true
        filter = nextcloud
        maxretry = 5
        logpath = /var/lib/nextcloud/data/nextcloud.log
      '';
    };
  };

  environment.etc."fail2ban/filter.d/nextcloud.conf".text = ''
    [Definition]
    _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
    failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
    datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
  '';

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.GatewayPorts = "clientspecified";
  programs.mosh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgevajch6O5ZQYWubHgaRZPnhrFM937mjUQO4gT+Bnr user@bluefin"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII3TXnbunXKZWodjSQPyaS5rFrhLdgMbJBBaBgfVIOIP u0_a71@localhost"
  ];

  users.users.deploy = {
    isSystemUser = true;
    group = "deploy";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVa60eaPM/JIHMbIIZ5xzY/CJ8GuWzHsndgKp8nzlaf github"
    ];
  };
  users.groups.deploy = { };
  nix.settings.trusted-users = [ "deploy" ];
  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  environment.systemPackages = [
    pkgs.htop
    pkgs.nix-du
    pkgs.attic-client
  ];

  security.acme = {
    defaults.email = "lars@muehml.eu";
    acceptTerms = true;
  };

  services.nginx = {
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    virtualHosts."forward.muehml.eu" = {
      forceSSL = true;
      enableACME = true;
      locations."/".proxyPass = "http://localhost:54321";
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.postgresql = {
    package = pkgs.postgresql_16;
  };

  # https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Online
  networking = {
    usePredictableInterfaceNames = false;
    hostName = "muehml";
    domain = "eu";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    interfaces."eth0" = {
      ipv6.addresses = [
        {
          address = "2a01:4f8:c17:a38f::1";
          prefixLength = 64;
        }
      ];
      useDHCP = true;
    };
  };
  system.stateVersion = "21.11";
}
