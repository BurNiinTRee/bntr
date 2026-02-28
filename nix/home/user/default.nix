{
  config,
  pkgs,
  lib,
  flakeInputs,
  flakeInputs',
  selfLocation,
  ...
}:
let
  ni = config.muehml.nixosIntegration;
  ifNi = lib.mkIf ni;
  gui = config.muehml.guiApps;
  ifGui = lib.mkIf gui;
in
{
  imports = [
    ./bitwarden.nix
    ./direnv.nix
    ./eduroam.nix
    ./email.nix
    ./firefox.nix
    ./ghostty.nix
    ./git.nix
    ./gnome.nix
    ./gpg.nix
    ./helix.nix
    ./impermanence.nix
    ./nextcloud.nix
    ./nushell.nix
    ./password-store.nix
    ./ssh.nix
    ./reaper.nix
    ./wezterm.nix
    ./zellij.nix
  ];
  options = {
    muehml.nixosIntegration = lib.mkEnableOption "features that only make sense on NixOS";
    muehml.guiApps = lib.mkEnableOption "applications that don't run in a terminal";
  };
  config = {
    persist.directories = [
      "bntr"
      "projects"
      ".cache/nix"
    ];

    fonts.fontconfig.enable = ifNi true;

    programs.gh.enable = true;

    programs.bash.enable = true;
    programs.starship = {
      enable = true;
      enableBashIntegration = false;
    };
    programs.htop.enable = true;
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
    home.packages =
      with pkgs;
      [
        fd
        fira-code
        lsof
        nil
        pijul
        ripgrep
        wl-clipboard
      ]
      ++ lib.optionals gui [
        denaro
        distrobox
        intel-gpu-tools
        libreoffice-fresh
        qpwgraph
      ];

    home.sessionVariables = {
      ## Wayland for Elecron apps
      ## broken as of 22-12-18
      # NIXOS_OZONE_WL = 1;
      ## Rust and Rustup in $XDG_DATA_HOME
      RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
      CARGO_HOME = "${config.xdg.dataHome}/cargo";
    };

    home.sessionPath = [
      "${config.home.sessionVariables.CARGO_HOME}/bin"
    ];

    xdg.configFile."latexmk/latexmkrc".text = ''
      $pdf_previewer = 'xdg-open';
    '';

    nix = {
      registry = {
        nixpkgs = {
          exact = false;
          to = {
            type = "github";
            owner = "nixos";
            repo = "nixpkgs";
            rev = flakeInputs.nixpkgs.rev;
          };
        };

        bntr-outer.to = {
          type = "github";
          owner = "BurNiinTRee";
          repo = "nix-sources";
        };
        bntr.to = {
          type = "github";
          owner = "BurNiinTRee";
          repo = "nix-sources";
          dir = "modules";
        };
        flake-parts.to = {
          type = "github";
          owner = "hercules-ci";
          repo = "flake-parts";
        };
      };
      package = lib.mkIf (!ni) pkgs.nix;
      settings =
        let
          emptyFlakeRegistry = pkgs.writeText "flake-registry.json" (
            builtins.toJSON {
              flakes = [ ];
              version = 2;
            }
          );
        in
        {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          sandbox = true;
          connect-timeout = 5;
          log-lines = 25;
          min-free = 54534824;
          fallback = true;
          warn-dirty = false;
          auto-optimise-store = true;
          max-jobs = 6;
          flake-registry = emptyFlakeRegistry;
          netrc-file = "${config.home.homeDirectory}/.config/nix/netrc";
          extra-substituters = [ "https://attic.muehml.eu/ci" ];
          extra-trusted-public-keys = [ "ci:pGN5GUIYtBiawlMyFIapGrGbUT8N1misYuS6iW90neU=" ];
        };
    };
    persist.files = [
      ".config/nix/netrc"
      ".local/share/nix/trusted-settings.json"
    ];

    home = {
      stateVersion = "23.05";
      homeDirectory = lib.mkIf (!ni) "/home/user/";
      username = lib.mkIf (!ni) "user";
    };

    programs.home-manager.enable = lib.mkIf (!ni) true;

    targets.genericLinux.nixGL = {
      packages = lib.mkIf (!ni) flakeInputs'.nixgl.packages;
      defaultWrapper = "mesa";
      installScripts = [ "mesa" ];
    };
  };
}
