{ config, ... }:
{
  services.grafana = {
    # enable = true;
    settings = {
      server.domain = "grafana.${config.networking.fqdn}";
      server.port = 2342;
      security.admin_password = "$__file{${config.sops.secrets.grafana-initial-password.path}}";
      smtp = {
        enabled = true;
        from_address = "grafana@muehml.eu";
        skip_verify = true;
      };
    };
  };
  services.nginx.virtualHosts.${config.services.grafana.settings.server.domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
    };
  };

  sops.secrets.grafana-initial-password.owner = "grafana";

  services.prometheus = {
    # enable = true;
    port = 9001;
    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      port = 9002;
    };
    scrapeConfigs = [
      {
        job_name = "muehml";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
    ];
  };

  services.loki = {
    # enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = 3100;
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/tmp/loki";
      };
      schema_config.configs = [
        {
          from = "2022-08-13";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      storage_config.filesystem.directory = "/tmp/loki/chunks";
    };
  };
  # services.promtail = {
  #   # enable = true;
  #   configuration = {
  #     server = {
  #       http_listen_port = 28183;
  #       grpc_listen_port = 0;
  #     };
  #     positions.filename = "/tmp/positions.yaml";
  #     clients = [ { url = "http://127.0.0.1:3100/loki/api/v1/push"; } ];
  #     scrape_configs = [
  #       {
  #         job_name = "journal";
  #         journal = {
  #           max_age = "12h";
  #           labels = {
  #             job = "systemd-journal";
  #             host = "muehml";
  #           };
  #         };
  #         relabel_configs = [
  #           {
  #             source_labels = [ "__journal__systmd_unit" ];
  #             target_label = "unit";
  #           }
  #         ];
  #       }
  #     ];
  #   };
  # };
}
