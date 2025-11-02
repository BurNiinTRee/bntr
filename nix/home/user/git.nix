{
  pkgs,
  flakeInputs,
  ...
}:
{
  programs.git = {
    enable = true;
    signing = {
      signByDefault = false;
      key = "Lars Mühmel <larsmuehmel@web.de>";
    };
    settings = {
      user = {
        name = "Lars Mühmel";
        email = "larsmuehmel@web.de";
      };
      init.defaultBranch = "main";
      commit = {
        verbose = true;
      };
      merge.conflictStyle = "zdiff3";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
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
      templates.git_push_bookmark = "\"BurNiinTRee/push-\" ++ change_id.short()";
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
