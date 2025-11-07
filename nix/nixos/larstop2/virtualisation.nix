{ pkgs, ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
    };
    spiceUSBRedirection.enable = true;
    podman = {
      enable = true;
    };
  };

  programs.virt-manager.enable = true;

  # environment.systemPackages = [
  #   pkgs.virt-viewer
  # ];
  # home-manager.users.user.persist.directories = [ ".local/share/containers/storage" ];
}
