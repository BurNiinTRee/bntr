{
  config,
  pkgs,
  lib,
  flakeInputs,
  ...
}:
{
  # Realtime stuff
  security.rtkit.enable = true;

  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "95";
    }
    {
      domain = "@audio";
      item = "nice";
      type = "-";
      value = "-19";
    }
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "4194304";
    }
  ];

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    socketActivation = true;
    alsa = {
      enable = true;
      # support32Bit = true;
    };
    jack.enable = true;
    wireplumber.enable = true;

    pulse.enable = true;
  };
  networking.firewall.allowedTCPPorts = [
    9875
    9876
  ];
  networking.firewall.allowedUDPPorts = [
    9875
    9876
  ];
}
