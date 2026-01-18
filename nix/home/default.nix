{
  inputs,
  withSystem,
  selfLocation,
  ...
}:
{
  flake.homeConfigurations = {
    user = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = withSystem "x86_64-linux" ({ pkgs, ... }: pkgs);
      modules = [
        {
          imports = [
            ../home/user
            inputs.nix-index-db.homeModules.nix-index
          ];
          muehml.guiApps = true;
          muehml.reaper.enable = false;
          _module.args.flakeInputs = inputs;
          _module.args.flakeInputs' = withSystem "x86_64-linux" ({ inputs', ... }: inputs');
          _module.args.selfLocation = selfLocation;
        }
      ];
    };

    user-no-gui = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = withSystem "x86_64-linux" ({ pkgs, ... }: pkgs);
      modules = [
        {
          imports = [
            ../home/user
            inputs.nix-index-db.homeModules.nix-index
          ];
          _module.args.flakeInputs = inputs;
          _module.args.flakeInputs' = withSystem "x86_64-linux" ({ inputs', ... }: inputs');
          _module.args.selfLocation = selfLocation;
        }
      ];
    };
  };
}
