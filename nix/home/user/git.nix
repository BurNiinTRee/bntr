{
  pkgs,
  flakeInputs,
  ...
}:
{
  programs.git = {
    enable = true;
    delta.enable = true;
    signing = {
      signByDefault = true;
      key = "Lars Mühmel <larsmuehmel@web.de>";
    };
    userName = "Lars Mühmel";
    userEmail = "larsmuehmel@web.de";
    extraConfig = {
      init.defaultBranch = "main";
      commit = {
        verbose = true;
      };
      merge.conflictStyle = "zdiff3";
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      ui = {
        default-command = "log";
        pager = ":builtin";
        diff-formatter = [
          "delta"
          "--paging"
          "never"
          "--light"
          "$left"
          "$right"
        ];
        diff-editor = "meld";
        merge-editor = "meld";
      };
      user = {
        name = "Lars Mühmel";
        email = "lars@muehml.eu";
      };
      git.push-bookmark-prefix = "BurNiinTRee/push-";
      aliases = {
        up = [
          "util"
          "exec"
          "--"
          "nu"
          "-c"
          ''
            #!/usr/bin/env nu
            jj git fetch
            jj rebase -d 'trunk()' --skip-emptied
            jj simplify-parents
          ''
        ];
      };
    };
  };

  home.packages = [
    flakeInputs.git-branchless.packages.x86_64-linux.git-branchless
    pkgs.meld
  ];
}
