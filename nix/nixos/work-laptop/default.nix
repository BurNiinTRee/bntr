{ ... }:
{
  networking.hostName = "work-laptop";
  wsl.enable = true;
  wsl.defaultUser = "user";
  imports = [
    ../user.nix
    ../nix.nix
  ];

  sops = {
    age.sshKeyPaths = [ "/home/user/.ssh/id_ed25519" ];
    defaultSopsFile = ../../secrets/muehml.eu.yaml;
  };
  system.stateVersion = "24.11";
}
