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
      font-family = "Maple Mono";
      theme = "light:Monokai Pro Light,dark:Monokai Pro";
    };
  };
}
