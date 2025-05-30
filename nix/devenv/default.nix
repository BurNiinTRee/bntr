{ inputs, lib, ... }:
let
  devenvRootFileContent = builtins.readFile inputs.devenv-root.outPath;
  devenvRoot = lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;
in
{
  imports = [ inputs.devenv.flakeModule ];
  perSystem =
    { ... }:
    {
      devenv.shells = {
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
    };
}
