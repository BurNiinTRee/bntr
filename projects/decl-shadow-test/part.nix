{ config, ... }:
{
  flake.modules.devenv.decl-shadow-test =
    { ... }:
    {
      imports = [ config.flake.modules.devenv.rust ];

    };
}
