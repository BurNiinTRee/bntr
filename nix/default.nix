{
  self,
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    treefmt-nix
    ;
in
{
  debug = true;
  systems = [ "x86_64-linux" ];
  _module.args.selfLocation = "/home/user/bntr";

  imports = [
    ./flake/nixpkgs.nix
    ./devenv
    ./home
    ./nixos
    ./templates
    treefmt-nix.flakeModule
  ];

  flake.flakeModules = {
    nixpgks = ./flake/nixpkgs.nix;
  };

  perSystem =
    {
      config,
      pkgs,
      system,
      self',
      ...
    }:
    {
      checks = {
        muehml = self.nixosConfigurations.muehml.config.system.build.toplevel;
        # larstop2 = self.nixosConfigurations.larstop2.config.system.build.toplevel;
        homeManager = self.homeConfigurations.user.config.home.activationPackage;
        devenv = self.devShells.x86_64-linux.default;
      };

      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          rustfmt.enable = true;
          asmfmt.enable = true;
          shellcheck.enable = true;
        };
      };

      _module.args.pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };
}
