{
  config,
  lib,
  pkgs,
  ...
}: {
  services.smartd.enable = true;

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    globalConfig.scrape_interval = "60s";

    exporters.smartctl = {
      enable = true;
      listenAddress = "127.0.0.1";
      maxInterval = "60s";
    };

    scrapeConfigs = [
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "grafana.nemesis.home.arpa";
        root_url = "http://grafana.nemesis.home.arpa/";
      };
      analytics.reporting_enabled = false;
      # Only used to encrypt Grafana's internal data; no sensitive data is stored.
      security.secret_key = "nemesis-smart-monitoring-secret-key";
    };

    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          uid = "prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];

      dashboards.settings.providers = [
        {
          name = "NEMESIS";
          options.path = ./dashboards;
        }
      ];
    };
  };
}
