{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ghostty = lib.mkIf config.muehml.guiApps {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.ghostty;
    settings = {
      command = [ "nu" ];
      font-family = "Fira Code";
      theme = "light:Monokai Pro Light,dark:Monokai Pro";
    };
  };
}
