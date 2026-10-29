{
  config,
  lib,
  pkgs,
  ...
}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];

  imports = [
    ./hardware-configuration.nix
    ../../common/utils/utils.nix
    ../../common/ci/woodpecker.nix
  ];
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = false;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  networking.hostName = "NEMESIS";
  networking.firewall.checkReversePath = false;

  networking.firewall.allowedTCPPorts = [22 80 81 2222 3000 5000 8000 8001 8002 8003 8084 8096 8123 9091 29170];
  networking.firewall.allowPing = true;

  networking.firewall.extraCommands = ''
    iptables -I DOCKER-USER -i docker0 -o wt0 -j DROP
  '';

  networking.nameservers = ["192.168.10.1" "8.8.8.8" "8.8.4.4"];

  time.timeZone = "America/Chicago";

  # Disk health warnings and SMART logging.
  services.smartd.enable = true;

  users.users.jerome = {
    isNormalUser = true;
    description = "Jerome";
    extraGroups = ["wheel" "shockwaves"];
    home = "/home/jerome";
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      dns = ["192.168.10.1" "8.8.8.8" "8.8.4.4"];
    };
  };

  # needed for gpu + docker
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia-container-toolkit.enable = true;

  services.nginx = {
    enable = true;

    virtualHosts."nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:81";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 1G;
        '';
      };
    };

    virtualHosts."jellyfin.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
      };
    };

    virtualHosts."git.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:3001";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 1G;
        '';
      };
    };

    virtualHosts."redlib.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8001";
        proxyWebsockets = true;
      };
    };

    virtualHosts."lubelogger.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8084";
        proxyWebsockets = true;
      };
    };

    virtualHosts."homeassistant.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8123";
        proxyWebsockets = true;
      };
    };

    virtualHosts."immich.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:2283";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 20G;
        '';
      };
    };

    virtualHosts."paperless.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8000";
        proxyWebsockets = true;
      };
    };

    virtualHosts."transmission.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:9091";
        proxyWebsockets = true;
      };
    };

    virtualHosts."tandoor.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:29170";
        proxyWebsockets = true;
      };
    };

    virtualHosts."traccar.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8002";
        proxyWebsockets = true;
      };
    };

    virtualHosts."sftpgo.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };

    virtualHosts."audiobookshelf.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:13378";
        proxyWebsockets = true;
      };
    };

    virtualHosts."searxng.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8888";
        proxyWebsockets = true;
      };
    };

    virtualHosts."firecrawl.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:3002";
        proxyWebsockets = true;
      };
    };

    virtualHosts."vector-prime.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8912";
        proxyWebsockets = true;
      };
    };

    virtualHosts."matrix.nemesis.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8008";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 10G;
        '';
      };
    };

    virtualHosts."fdroid.nemesis.home.arpa" = {
      locations."/fdroid/repo/" = {
        proxyPass = "http://127.0.0.1:8090/";
        extraConfig = ''
          client_max_body_size 2G;
        '';
      };

      locations."/upload/" = {
        proxyPass = "http://127.0.0.1:8091/";
        extraConfig = ''
          client_max_body_size 2G;
          proxy_request_buffering off;
          proxy_read_timeout 300s;
        '';
      };

      locations."/" = {
        return = "302 http://fdroid.nemesis.home.arpa/fdroid/repo/";
      };
    };
  };

  services.xserver.xkb.layout = "us";

  services.openssh.enable = true;
  services.netbird.enable = true;

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/age-key.txt";
    secrets = {
      woodpecker_agent_secret = {};
      woodpecker_gitea_client_id = {};
      woodpecker_gitea_client_secret = {};
      woodpecker_webhook_secret = {};
      woodpecker_gitea_token = {};
    };
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";
}
