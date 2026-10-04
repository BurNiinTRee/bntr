{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      muehml = {
        HostName = "muehml.eu";
        User = "root";
      };
      "*" = {
        ForwardAgent = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        Compression = false;
        AddKeysToAgent = "no";
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    };
  };
}
