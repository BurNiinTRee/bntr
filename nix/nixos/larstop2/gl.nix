{ pkgs, ... }:
{
  # Enable GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
      intel-compute-runtime
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-vaapi-driver
    ];
  };
}
