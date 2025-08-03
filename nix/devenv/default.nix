{ inputs, lib, ... }:
let
  devenvRootFileContent = builtins.readFile inputs.devenv-root.outPath;
  devenvRoot = lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

in
{
  imports = [ inputs.devenv.flakeModule ];
  perSystem =
    { config, ... }:
    let
      devenvs = {
        default =
          { pkgs, ... }:
          {
            # https://github.com/cachix/devenv/issues/528
            containers = lib.mkForce { };
            packages = [ pkgs.sops ];
          };
        rust =
          { lib, pkgs, ... }:
          {
            devenv.root = devenvRoot;
            # https://github.com/cachix/devenv/issues/528
            containers = lib.mkForce { };
            languages.rust = {
              enable = true;
              channel = "stable";
              targets = [
                "x86_64-unknown-linux-musl"
              ];
            };
            packages = [ ];
          };
      };
      isDevenvFile = p: (builtins.baseNameOf p) == "devenv.nix";
      files = (lib.filesystem.listFilesRecursive ../../projects);
      extraProjectEnvFiles = builtins.filter isDevenvFile files;
      extraProjectDevenv =
        p:
        let
          name = builtins.baseNameOf (builtins.dirOf p);
          value = {
            imports = [ (import p devenvs) ];
          };
        in
        {
          inherit name value;
        };
      extraProjectDevenvs = builtins.listToAttrs (builtins.map extraProjectDevenv extraProjectEnvFiles);
    in
    {
      devenv.shells = devenvs // extraProjectDevenvs;
    };
}
