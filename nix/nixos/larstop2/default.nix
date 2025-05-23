{
  # modulesPath,
  ...
}:
{
  imports = [
    ./compat.nix
    ./configuration.nix
    ./hardware-configuration.nix
    # (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    ./sound.nix
    ./impermanence.nix
    ./gnome.nix
    ./gsconnect.nix
    ../nix.nix
    ./gl.nix
    ./steam.nix
    ./virtualisation.nix
    ./networking.nix
    ./power.nix
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
