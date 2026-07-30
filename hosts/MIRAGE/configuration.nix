{
  config,
  lib,
  pkgs,
  stevenblack-hosts,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../common/utils/utils.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 0;
  };

  # enp1s0 is the built in realtek NIC (in)
  # enp2s0 is the m.2 intel NIC (out)

  networking = {
    hostName = "MIRAGE";

    useDHCP = false;

    interfaces.enp1s0.useDHCP = true;

    interfaces.enp2s0.ipv4.addresses = [
      {
        address = "192.168.10.1";
        prefixLength = 24;
      }
    ];

    nat = {
      enable = true;
      externalInterface = "enp1s0";
      internalInterfaces = ["enp2s0"];
    };

    firewall = {
      enable = false;
    };

    nftables = {
      enable = true;

      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority filter;
            policy drop;

            # Allow loopback
            iifname "lo" accept

            # Allow existing connections
            ct state established,related accept

            # Allow ping from LAN
            iifname "enp2s0" ip protocol icmp accept

            # LAN access to router services
            iifname "enp2s0" tcp dport 22 accept
            iifname "enp2s0" udp dport 53 accept
            iifname "enp2s0" tcp dport 53 accept

            # DHCP
            iifname "enp2s0" udp dport 67 accept
            iifname "enp2s0" udp dport 68 accept

            log prefix "nft-input-drop: "
          }

          chain forward {
            type filter hook forward priority filter;
            policy drop;

            # Allow responses from websites I hit
            ct state established,related accept

            # Allow if the packet is coming from LAN and going to WAN
            iifname "enp2s0" oifname "enp1s0" accept

            log prefix "nft-forward-drop: "
          }
        }
      '';
    };
  };

  services.dnsmasq = {
    enable = true;

    settings = {
      interface = "enp2s0";
      dhcp-range = "192.168.10.100,192.168.10.200,12h";

      no-hosts = true;

      dhcp-host = [
        # Assign ip for devices based on MAC
        "a0:36:bc:05:50:4f,192.168.10.10,nemesis"
        "34:19:4d:29:c0:b8,192.168.10.30,lg-tv"
      ];

      dhcp-option = [
        "option:router,192.168.10.1"
        "option:dns-server,192.168.10.1"
      ];

      host-record = [
        "mirage,mirage.home.arpa,192.168.10.1"
        "nemesis,nemesis.home.arpa,192.168.10.10"
      ];

      addn-hosts = [
        "${stevenblack-hosts}/hosts"
        "${./modules/dns_blocklist.txt}"
      ];

      log-queries = "extra";
      log-facility = "/var/log/dnsmasq.log";

      server = [
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
  };

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.jerome = {
    isNormalUser = true;
    description = "Jerome Siljan";
    extraGroups = ["wheel"];
    packages = with pkgs; [];
  };

  environment.systemPackages = with pkgs; [
    dig
    tcpdump
  ];

  services.openssh.enable = true;
  services.netbird.enable = true;

  system.stateVersion = "25.11";
}
