{ ... }:
{
  programs.ssh = {
    enable = true;
    matchBlocks.muehml = {
      hostname = "muehml.eu";
      user = "root";
    };
    enableDefaultConfig = false;
    matchBlocks."*" = {
      forwardAgent = false;
      serverAliveInterval = 0;
      serverAliveCountMax = 3;
      compression = false;
      addKeysToAgent = "no";
      hashKnownHosts = false;
      userKnownHostsFile = "~/.ssh/known_hosts";
      controlMaster = "no";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "no";
    };
  };
  persist.directories = [ ".ssh" ];
}
