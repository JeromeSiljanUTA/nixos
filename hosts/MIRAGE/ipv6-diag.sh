#!/usr/bin/env bash
#
# MIRAGE IPv6 diagnostics
#
# Collects network/IPv6 state into a single report so it can be shared for
# debugging. Safe to re-run; it only reads state and does a short packet
# capture. Run it on MIRAGE (ideally as root) while the IPv6 config under test
# is active:
#
#   sudo bash ~/nixos/hosts/MIRAGE/ipv6-diag.sh
#
# Note: the report contains public IPs, MAC addresses and DHCP identifiers.
# Review it before posting publicly.

set -u
umask 077

OUT="/tmp/mirage-ipv6-diag-$(date +%Y%m%d-%H%M%S).txt"
: >"$OUT"

section() {
  {
    printf '\n\n============================================================\n'
    printf '### %s\n' "$*"
    printf '============================================================\n'
  } >>"$OUT"
}

run() {
  printf '\n$ %s\n' "$*" >>"$OUT"
  "$@" >>"$OUT" 2>&1
  local rc=$?
  [ "$rc" -ne 0 ] && printf '[exit %s]\n' "$rc" >>"$OUT"
  return 0
}

runsh() {
  printf '\n$ %s\n' "$*" >>"$OUT"
  bash -c "$*" >>"$OUT" 2>&1
  local rc=$?
  [ "$rc" -ne 0 ] && printf '[exit %s]\n' "$rc" >>"$OUT"
  return 0
}

# ---------------------------------------------------------------- metadata
section "Report metadata"
runsh 'date -Is; echo; uname -a; echo; hostname; echo; (nixos-version 2>/dev/null || true); echo; uptime; echo; id'

if [ "$(id -u)" -ne 0 ]; then
  section "WARNING"
  printf 'This script was not run as root; some output (journal, tcpdump, nftables) may be missing.\n' >>"$OUT"
fi

# ---------------------------------------------------------------- links
section "Interfaces (brief)"
run ip -br link
run ip -br addr
runsh 'ip -s link show dev enp1s0; echo; ip -s link show dev enp2s0'

section "Interfaces (full)"
run ip addr show

# ---------------------------------------------------------------- IPv4
section "IPv4 routes"
run ip -4 route show table all

section "IPv4 addresses"
run ip -4 addr show

# ---------------------------------------------------------------- IPv6
section "IPv6 addresses"
run ip -6 addr show
run ip -6 addr show dev enp1s0
run ip -6 addr show dev enp2s0

section "IPv6 routes (all tables)"
run ip -6 route show table all

section "IPv6 policy rules"
run ip -6 rule show

section "IPv6 sysctls"
runsh '
for s in \
  net.ipv6.conf.all.forwarding \
  net.ipv6.conf.all.accept_ra \
  net.ipv6.conf.all.disable_ipv6 \
  net.ipv6.conf.default.accept_ra \
  net.ipv6.conf.enp1s0.forwarding \
  net.ipv6.conf.enp1s0.accept_ra \
  net.ipv6.conf.enp1s0.disable_ipv6 \
  net.ipv6.conf.enp2s0.forwarding \
  net.ipv6.conf.enp2s0.accept_ra \
  net.ipv6.conf.enp2s0.disable_ipv6; do
  printf "%-40s = %s\n" "$s" "$(sysctl -n "$s" 2>/dev/null || echo n/a)"
done'

# ---------------------------------------------------------------- networkd
section "systemd-networkd status (all)"
run networkctl status
run networkctl list

section "systemd-networkd status enp1s0 (WAN)"
run networkctl status enp1s0

section "systemd-networkd status enp2s0 (LAN)"
run networkctl status enp2s0

section "systemd-networkd JSON"
runsh 'networkctl status --json=pretty 2>/dev/null || networkctl status --json=short 2>/dev/null || true'

section "networkd config files (/etc/systemd/network)"
runsh '
ls -la /etc/systemd/network/
for f in /etc/systemd/network/*; do
  [ -f "$f" ] || continue
  echo
  echo "----- $f -----"
  cat "$f"
done'

section "systemd-networkd journal (this boot)"
run journalctl -u systemd-networkd -b --no-pager

section "networkd services"
run systemctl status systemd-networkd.service --no-pager
run systemctl status systemd-networkd-wait-online.service --no-pager
run systemctl status network-online.target --no-pager

# ---------------------------------------------------------------- dnsmasq
section "dnsmasq"
run systemctl status dnsmasq --no-pager
runsh 'cat /etc/dnsmasq.conf 2>/dev/null || true'
runsh 'journalctl -u dnsmasq -b --no-pager | tail -n 120'
runsh 'ss -lnup 2>/dev/null || netstat -lnup 2>/dev/null || true; echo; ss -lntp 2>/dev/null || netstat -lntp 2>/dev/null || true'

# ---------------------------------------------------------------- firewall
section "nftables ruleset (with handles)"
run nft list ruleset -a
section "nftables counters"
runsh 'nft list counters 2>/dev/null || true'

# ---------------------------------------------------------------- neighbors
section "Neighbor tables"
run ip neigh
run ip -6 neigh
runsh 'ip -6 neigh show proxy 2>/dev/null || true'

# ---------------------------------------------------------------- resolvers
section "Resolver configuration"
runsh 'ls -la /etc/resolv.conf; echo; cat /etc/resolv.conf'
runsh 'resolvectl status 2>/dev/null || systemd-resolve --status 2>/dev/null || true'

# ---------------------------------------------------------------- tests
section "Connectivity tests"
run ping -4 -c2 -W2 1.1.1.1
run ping -6 -c2 -W2 2606:4700:4700::1111
run ping -6 -c2 -W2 fe80::1%enp2s0
run ping -6 -c2 -W2 2606:4700:4700::1111%enp1s0
run dig +time=2 +tries=1 A example.com
run dig +time=2 +tries=1 AAAA example.com
run dig +time=2 +tries=1 @2606:4700:4700::1111 AAAA example.com
run dig +time=2 +tries=1 @fe80::1%enp2s0 AAAA example.com
runsh 'echo "IPv4 public:"; curl -4 -sS --max-time 8 https://ifconfig.co 2>&1; echo; echo "IPv6 public:"; curl -6 -sS --max-time 8 https://ifconfig.co 2>&1; echo'
runsh 'curl -4 -sS --max-time 8 -o /dev/null -w "IPv4 HTTP %{http_code}\n" https://www.google.com 2>&1 || true'
runsh 'curl -6 -sS --max-time 8 -o /dev/null -w "IPv6 HTTP %{http_code}\n" https://www.google.com 2>&1 || true'

# ---------------------------------------------------------------- captures
section "Packet capture: WAN enp1s0 (RA + DHCPv6 + DHCPv4), 25s"
runsh 'timeout 25 tcpdump -ni enp1s0 -vvv -c 100 "icmp6 or udp port 546 or udp port 547 or udp port 67 or udp port 68" 2>&1 || true'

section "Packet capture: LAN enp2s0 (ICMPv6), 10s"
runsh 'timeout 10 tcpdump -ni enp2s0 -vvv -c 50 "icmp6" 2>&1 || true'

# ---------------------------------------------------------------- done
section "End of report"
runsh 'date -Is'

echo
echo "Report written to: $OUT"
echo "Size: $(wc -c <"$OUT") bytes"
