{ config, withSystem, ... }:
{
  flake.modules.devenv.decl-shadow-test =
    { ... }:
    {
      imports = [ config.flake.modules.devenv.rust ];

    };

  perSystem =
    { config, pkgs, ... }:
    {
      packages = {
        decl-shadow-test = pkgs.callPackage (
          { rustPlatform, lib }:
          rustPlatform.buildRustPackage (finalAttrs: {
            name = "decl-shadow-test";
            version = "0.1.0";
            cargoLock.lockFile = ./Cargo.lock;
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./Cargo.lock
                ./Cargo.toml
                ./src
              ];
            };
          })
        ) { };

        decl-shadow-test-site =
          pkgs.runCommand "decl-shadow-test-site"
            { nativeBuildInputs = [ config.packages.decl-shadow-test ]; }
            ''
              mkdir $out
              decl-shadow-test build --source ${./site} --out $out
            '';
      };
    };

  flake.modules.nixos.muehml =
    { pkgs, ... }:
    {
      networking.firewall.allowedUDPPorts = [ 443 ];
      services.nginx = {
        package = pkgs.nginxQuic;
        virtualHosts."decl-shadow-test.muehml.eu" = {
          forceSSL = true;
          enableACME = true;
          quic = true;
          locations."/" = {
            root = withSystem "x86_64-linux" ({ config, ... }: config.packages.decl-shadow-test-site);
            index = "index.html";
            extraConfig = ''
              if ($arg_cachebust) {
                add_header Cache-Control "max-age=31536000,immutable";
              }
              add_header Alt-Svc "h3=\":443\"";
            '';
          };
        };
      };
    };
}
