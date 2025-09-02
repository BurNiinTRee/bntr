{ lib, ... }:
{
  imports = [
    (lib.mkAliasOptionModule
      [ "impermanence" "directories" ]
      [ "environment" "persistence" "/mnt/persist" "directories" ]
    )
    (lib.mkAliasOptionModule
      [ "impermanence" "files" ]
      [ "environment" "persistence" "/mnt/persist" "files" ]
    )
  ];

  config = {
    fileSystems."/mnt/persist" = {
      neededForBoot = true;
      device = "/dev/disk/by-id/scsi-0HC_Volume_100964436";
      fsType = "ext4";
      options = [ "discard,defaults,noatime" ];
    };

    impermanence.directories = [
      "/var/lib/postgresql"
      "/var/lib/nixos"
    ];
  };
}
