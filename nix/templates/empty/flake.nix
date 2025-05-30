{
  inputs = {
    bntr.url = "github:BurNiinTRee/nix-sources?dir=modules";
    devenv.url = "github:cachix/devenv";
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      flake-parts,
      bntr,
      devenv,
      devenv-root,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        systems = [ "x86_64-linux" ];

        imports = [
          bntr.flakeModules.nixpkgs
          devenv.flakeModule
        ];

        perSystem = {
          devenv.shells.default =
            {
              lib,
              pkgs,
              ...
            }:
            {
              devenv.root =
                let
                  devenvRootFileContent = builtins.readFile devenv-root.outPath;
                in
                pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

              # https://github.com/cachix/devenv/issues/528
              containers = lib.mkForce { };
              packages = [
              ];
            };
        };
      }
    );
}
