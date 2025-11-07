{ lib, ... }:
{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        # device = "/dev/vda";
        device = "/dev/nvme0n1";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "ESP";
              start = "1MiB";
              end = "2GiB";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            }
            {
              name = "root";
              start = "2GiB";
              end = "-32GiB";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                  };
                  "/nix" = {
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                    mountpoint = "/nix";
                  };
                };
              };
            }
            {
              name = "swap";
              start = "-32GiB";
              end = "100%";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            }
          ];
        };
      };
    };
  };
}
