{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    languages = {
      language = [
        {
          name = "nix";
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }
        {
          name = "blueprint";
          file-types = [ "blp" ];
          indent = {
            tab-width = 2;
            unit = " ";
          };
          scope = "text.blp";
          roots = [ "meson.build" ];
          comment-token = "//";
          language-servers = [ "blueprint-compiler" ];
        }
      ];
      language-server = {
        rust-analyzer = {
          config.check.command = "clippy";
        };
        blueprint-compiler = {
          command = "blueprint-compiler";
          args = [ "lsp" ];
        };
      };
    };
    settings = {
      theme = "onelight";
      keys = {
        normal = {
          "A-," = "goto_previous_buffer";
          "A-." = "goto_next_buffer";
          "A-w" = ":buffer-close";
          "A-/" = "repeat_last_motion";

          "A-x" = "extend_to_line_bounds";
          "X" = [
            "extend_line_up"
            "extend_to_line_bounds"
          ];
        };
        select = {
          "A-x" = "extend_to_line_bounds";
          "X" = [
            "extend_line_up"
            "extend_to_line_bounds"
          ];
        };
      };
      editor = {
        color-modes = true;
        bufferline = "multiple";
        cursorline = true;
        line-number = "relative";
        true-color = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides.render = true;
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
        file-picker.hidden = false;
      };
    };
  };

  home.sessionVariables = {
    EDITOR = "hx";
  };
}
