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
    # Required for the router to pass IPv6 traffic between LAN and WAN.
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # enp1s0 is the built in realtek NIC (in)
  # enp2s0 is the m.2 intel NIC (out)

  networking = {
    hostName = "MIRAGE";

    useDHCP = false;
    # systemd-networkd manages the interfaces. It is required for the
    # DHCPv6 prefix delegation and router advertisements configured below.
    useNetworkd = true;

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

            # IPv6 from LAN: neighbour discovery + ping
            iifname "enp2s0" icmpv6 type {
              echo-request,
              nd-router-solicit,
              nd-neighbor-solicit,
              nd-neighbor-advert
            } accept

            # IPv6 from WAN: ISP router advertisements and neighbour discovery
            iifname "enp1s0" icmpv6 type {
              nd-router-advert,
              nd-router-solicit,
              nd-neighbor-solicit,
              nd-neighbor-advert
            } accept

            # ICMPv6 errors are required for path MTU discovery to work
            icmpv6 type {
              destination-unreachable,
              packet-too-big,
              time-exceeded,
              parameter-problem
            } accept

            # DHCPv6 client replies from the ISP
            iifname "enp1s0" udp dport 546 accept

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

            # ICMPv6 is required for IPv6 to function (PMTU, neighbour discovery)
            icmpv6 type {
              destination-unreachable,
              packet-too-big,
              time-exceeded,
              parameter-problem,
              nd-neighbor-solicit,
              nd-neighbor-advert
            } accept

            log prefix "nft-forward-drop: "
          }
        }
      '';
    };
  };

  systemd.network = {
    networks = {
      # WAN: the ISP uplink. DHCPv4 gives us the internet, DHCPv6 asks for a
      # delegated prefix (PD) that we carve up for the LAN below.
      "10-wan" = {
        matchConfig.Name = "enp1s0";

        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          LinkLocalAddressing = "ipv6";
        };

        dhcpV4Config = {
          # We run our own resolver on the router.
          UseDNS = false;
        };

        dhcpV6Config = {
          # Ask for a /56; most ISPs hand out a /56 or /60 and will refuse a
          # larger request, so the exact size is only a hint.
          PrefixDelegationHint = "::/56";
          UseDNS = false;
        };

        # Some ISPs advertise a prefix without setting the managed flag, so
        # force the DHCPv6 client to run whenever we receive an RA.
        ipv6AcceptRAConfig = {
          DHCPv6Client = "always";
        };

        linkConfig.RequiredForOnline = "routable";
      };

      # LAN: the downstream network. Take a /64 from the delegated prefix,
      # assign it here, and announce it (plus DNS) to clients via SLAAC.
      "20-lan" = {
        matchConfig.Name = "enp2s0";

        # fe80::1 is the stable link-local address we advertise as the DNS
        # server in router advertisements below.
        address = [
          "192.168.10.1/24"
          "fe80::1/64"
        ];

        networkConfig = {
          IPv6AcceptRA = false;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
          LinkLocalAddressing = "ipv6";
        };

        dhcpPrefixDelegationConfig = {
          UplinkInterface = "enp1s0";
          SubnetId = "1";
          Announce = true;
        };

        ipv6SendRAConfig = {
          EmitDNS = true;
          DNS = "fe80::1";
          EmitDomains = true;
          Domains = "home.arpa";
        };

        linkConfig.RequiredForOnline = "routable";
      };
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
        "option:domain-search,home.arpa"
      ];

      host-record = [
        # fe80::1 is the router's stable LAN link-local address.
        "mirage,mirage.home.arpa,192.168.10.1,fe80::1"
        "nemesis,nemesis.home.arpa,192.168.10.10"
      ];

      address = [
        # wildcard: all *.nemesis.home.arpa resolve to nemesis
        "/nemesis.home.arpa/192.168.10.10"
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
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
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
