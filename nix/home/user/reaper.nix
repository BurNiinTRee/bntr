{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.muehml.reaper.enable = lib.mkEnableOption "Reaper" // {
    default = config.muehml.guiApps;
  };

  config = lib.mkIf config.muehml.reaper.enable {
    home.packages = with pkgs; [
      reaper
      # setbfree
      x42-plugins
      x42-gmsynth
      x42-avldrums
      guitarix
    ];
    persist.directories = [ ".config/REAPER" ];
  };
}
