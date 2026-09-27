{
  config,
  pkgs,
  ...
}:
let
  command-not-found = pkgs.writeScript "command-not-found" ''
    #!${pkgs.bash}/bin/bash
    source ${config.programs.nix-index.package}/etc/profile.d/command-not-found.sh
    command_not_found_handle "$@"
  '';
in
{
  programs.nushell = {
    enable = true;
    extraConfig = ''
      let fish_completer = {|spans|
          fish --command $'complete "--do-complete=($spans | str join " ")"'
          | $"value(char tab)description(char newline)" + $in
          | from tsv --flexible --no-infer
      }

      let carapace_completer = {|spans: list<string>|
          carapace $spans.0 nushell ...$spans
          | from json
          | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
      }

      # This completer will use carapace by default
      let external_completer = {|spans|
          let expanded_alias = scope aliases
          | where name == $spans.0
          | get --optional 0.expansion

          let spans = if $expanded_alias != null {
              $spans
              | skip 1
              | prepend ($expanded_alias | split row ' ' | take 1)
          } else {
              $spans
          }

          match $spans.0 {
              nu => $fish_completer
              git => $fish_completer
              asdf => $fish_completer
              _ => $carapace_completer
          } | do $in $spans
      }
      $env.config.show_banner = false
      $env.config.hooks.command_not_found = {|cmd_name|
        try {
          ${command-not-found} $cmd_name
        }
      }
      $env.config.completions.external.enable = true
      $env.config.completions.external.max_results = 100
      $env.config.completions.external.completer = $external_completer
    '';
  };

  programs.atuin = {
    enable = true;
    enableBashIntegration = false;
    flags = [
      "--disable-up-arrow"
    ];
    settings = {
      workspaces = true;
    };
  };

  home.packages = [
    pkgs.carapace
    pkgs.fish
  ];
}
