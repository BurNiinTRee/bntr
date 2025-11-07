{
  # modulesPath,
  ...
}:
{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    # (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    # ./sound.nix
    ./impermanence.nix
    # ./gnome.nix
    # ./gsconnect.nix
    ./minecraft.nix
    ../nix.nix
    # ./gl.nix
    # ./steam.nix
    ./virtualisation.nix
    ./networking.nix
    ./power.nix
  ];
}
