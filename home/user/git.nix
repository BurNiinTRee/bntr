{...}: {
  programs.git.enable = true;
  xdg.configFile."git/config".text = ''
    [user]
    email = "lars@muehml.eu"
    name = "Lars Mühmel"

    [init]
    defaultBranch = "main"
  '';
}
