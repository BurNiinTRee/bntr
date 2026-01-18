{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # We move the direnv cache to the ~/.cache directory
  # This predominantly helps with .envrc:s in rclone mounts, as these
  # don't allow symlinks, but use_flake tries to create some
  xdg.configFile."direnv/lib/cache.sh".text = ''
    : ''${XDG_CACHE_HOME:=$HOME/.cache}
    declare -A direnv_layout_dirs
    direnv_layout_dir() {
    	echo "''${direnv_layout_dirs[$PWD]:=$(
    		local hash="$(sha1sum - <<<"''${PWD}" | cut -c-7)"
    		local path="''${PWD//[^a-zA-Z0-9]/-}"
    		echo "''${XDG_CACHE_HOME}/direnv/layouts/''${hash}''${path}"
    	)}"
    }
  '';
}
