{
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = false;
    servers = {
      create = {
        enable = true;
        package = pkgs.neoforgeServers.neoforge-1_21_1-21_1_172;
        jvmOpts = "-Xms6G -Xmx7G";
        serverProperties.server-port = 25566;
      };
      vanilla-istercraft = {
        enable = true;
        package = pkgs.vanillaServers.vanilla-26_1_2;
        jvmOpts = "-Xms6G -Xmx7G";
        serverProperties.server-port = 25568;
      };
      nelvira = {
        enable = true;
        package = pkgs.vanillaServers.vanilla-1_21_11;
        jvmOpts = "-Xms6G -Xmx7G";
        serverProperties.server-port = 25567;
      };
    };
  };

  systemd.services.minecraft-server-create.serviceConfig.TimeoutStartSec = "300";

  environment.systemPackages = [
    pkgs.tmux
    (pkgs.writeShellScriptBin "minecraft-server-console-create" ''
      read -p "You can close the minecraft server console with Ctrl+B followed by D. Continue with Enter.
      "
      exec ${lib.getBin pkgs.tmux}/bin/tmux -S /run/minecraft/create.sock attach
    '')
    (pkgs.writeShellScriptBin "minecraft-server-console-nelvira" ''
      read -p "You can close the minecraft server console with Ctrl+B followed by D. Continue with Enter.
      "
      exec ${lib.getBin pkgs.tmux}/bin/tmux -S /run/minecraft/nelvira.sock attach
    '')
  ];

  persist.directories = [
    config.services.minecraft-server.dataDir
    config.services.minecraft-servers.dataDir
  ];

  networking.firewall.allowedUDPPorts = [
    24454
    25565
  ];
  networking.firewall.allowedTCPPorts = [
    25565
  ];

  systemd.services.gate = {
    wantedBy = [ "multi-user.target" ];
    script = "${pkgs.gate}/bin/gate -c ${./gate-config.yaml}";
  };
}
