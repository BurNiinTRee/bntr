{
  config,
  inputs,
  selfLocation,
  ...
}:
let
  inherit (inputs)
    self
    sops-nix
    disko
    home-manager
    impermanence
    nix-minecraft
    nix-index-db
    nixpkgs
    nixpkgs-stable
    simple-nixos-mailserver
    nixos-wsl
    comin
    ;
  setup-inputs =
    { lib, ... }:
    {
      system.configurationRevision = lib.mkIf (self ? rev) self.rev;
      _module.args.flakeInputs = inputs;
      _module.args.selfLocation = selfLocation;
    };
in
{
  flake.modules.nixos = {
    larstop2 =
      { ... }:
      {
        imports = [
          ./larstop2
          setup-inputs
          sops-nix.nixosModules.sops
          # home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          disko.nixosModules.disko
          comin.nixosModules.comin
          nix-minecraft.nixosModules.minecraft-servers
          {
            nixpkgs.overlays = [ nix-minecraft.overlay ];
            # home-manager.users.user = {
            #   imports = [
            #     ../home/user
            #     impermanence.nixosModules.home-manager.impermanence
            #     nix-index-db.homeModules.nix-index
            #   ];
            #   _module.args.flakeInputs = inputs;
            #   _module.args.selfLocation = selfLocation;
            #   muehml.nixosIntegration = true;
            #   muehml.guiApps = true;
            # };
          }
        ];
      };
    muehml = {
      imports = [
        ./muehml
        setup-inputs
        sops-nix.nixosModules.sops
        comin.nixosModules.comin
        impermanence.nixosModules.impermanence
        simple-nixos-mailserver.nixosModules.mailserver
      ];
    };
  };
  flake.nixosConfigurations = {
    larstop2 = nixpkgs.lib.nixosSystem {
      modules = [
        config.flake.modules.nixos.larstop2
      ];
    };
    # work-laptop = nixpkgs.lib.nixosSystem {
    #   system = "x86_64-linux";
    #   modules = [
    #     ./work-laptop
    #     nixos-wsl.nixosModules.wsl
    #     setup-inputs
    #     home-manager.nixosModules.home-manager
    #     {
    #       home-manager.users.user = {
    #         imports = [
    #           ../home/user
    #           nix-index-db.homeModules.nix-index
    #           # I should get rid of this
    #           impermanence.nixosModules.home-manager.impermanence
    #           {
    #             muehml.reaper.enable = false;
    #           }
    #         ];
    #         _module.args.flakeInputs = inputs;
    #         _module.args.selfLocation = selfLocation;
    #       };
    #     }
    #   ];
    # };
    muehml = nixpkgs-stable.lib.nixosSystem {
      modules = [
        config.flake.modules.nixos.muehml
      ];
    };

    # rpi = nixpkgs.lib.nixosSystem {
    #   modules = [
    #     ./rpi
    #     setup-inputs
    #   ];
    # };
  };
}
