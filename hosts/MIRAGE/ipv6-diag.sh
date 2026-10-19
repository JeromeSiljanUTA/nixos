#!/usr/bin/env bash
#
# MIRAGE IPv6 diagnostics
#
# Collects network/IPv6 state into a single report so it can be shared for
# debugging. Safe to re-run; it only reads state and does a short packet
# capture. Run it on MIRAGE (as root) while the config under test is active:
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

# ---------------------------------------------------------------- quick summary
section "Quick summary"
runsh '
echo "== Global/ULA IPv6 addresses =="
ip -6 addr show | grep -E "inet6 (fd[0-9a-f]{2}:|2[0-9a-f]{3}:)" || echo "(none)"
echo
echo "== IPv6 default routes =="
ip -6 route show default || true
echo
echo "== networkd delegated prefixes (WAN) =="
networkctl status enp1s0 2>/dev/null | grep -i "prefix" || echo "(none)"
echo
echo "== LAN IPv6 prefixes advertised (from RA config) =="
grep -R "^Prefix=" /etc/systemd/network/ 2>/dev/null || echo "(none)"'

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

section "systemd-networkd JSON (short)"
runsh 'networkctl status --json=short 2>/dev/null || networkctl status --json=pretty 2>/dev/null || true'

section "networkd config files"
runsh '
for d in /etc/systemd/network /etc/static/systemd/network /run/systemd/network /usr/lib/systemd/network; do
  [ -d "$d" ] || continue
  echo "===== $d ====="
  ls -la "$d"
  for f in "$d"/*; do
    [ -f "$f" ] || continue
    echo
    echo "----- $f -----"
    cat "$f"
  done
  echo
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
runsh '
pid=$(pgrep -x dnsmasq | head -n1)
if [ -n "$pid" ]; then
  echo "== command line =="
  tr "\0" " " < "/proc/$pid/cmdline"; echo
  conf=$(tr "\0" "\n" < "/proc/$pid/cmdline" | awk "/^-C$/{getline; print}")
  if [ -n "$conf" ]; then
    echo
    echo "== config file: $conf =="
    cat "$conf"
  fi
else
  echo "dnsmasq is not running"
fi'
runsh 'journalctl -u dnsmasq -b --no-pager | tail -n 80'
runsh 'ss -lnup 2>/dev/null || netstat -lnup 2>/dev/null || true; echo; ss -lntp 2>/dev/null || netstat -lntp 2>/dev/null || true'

# ---------------------------------------------------------------- firewall
section "nftables ruleset (with handles)"
run nft -a list ruleset

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
run ping -6 -c2 -W2 fdad:2cc4:4627:0::1%enp2s0
run dig +time=2 +tries=1 A example.com
run dig +time=2 +tries=1 AAAA example.com
run dig +time=2 +tries=1 @2606:4700:4700::1111 AAAA example.com
run dig +time=2 +tries=1 @fe80::1%enp2s0 AAAA example.com
runsh 'echo "IPv4 public:"; curl -4 -sS --max-time 8 https://ifconfig.co 2>&1; echo; echo "IPv6 public:"; curl -6 -sS --max-time 8 https://ifconfig.co 2>&1; echo'
runsh 'curl -4 -sS --max-time 8 -o /dev/null -w "IPv4 HTTP %{http_code}\n" https://www.google.com 2>&1 || true'
runsh 'curl -6 -sS --max-time 8 -o /dev/null -w "IPv6 HTTP %{http_code}\n" https://www.google.com 2>&1 || true'

# ---------------------------------------------------------------- captures
# Run both captures in parallel so we only wait ~60s total. Router
# advertisements can be 30-200s apart, so 60s gives a decent chance of
# catching both the ISP's and the eero's advertisements.
section "Packet capture: WAN enp1s0 + LAN enp2s0 (60s, parallel)"
WANOUT=$(mktemp)
LANOUT=$(mktemp)
timeout 60 tcpdump -ni enp1s0 -vvv -c 200 \
  'icmp6 or udp port 546 or udp port 547 or udp port 67 or udp port 68' >"$WANOUT" 2>&1 &
p1=$!
timeout 60 tcpdump -ni enp2s0 -vvv -c 200 'icmp6' >"$LANOUT" 2>&1 &
p2=$!
wait "$p1" "$p2" 2>/dev/null || true
{
  echo
  echo '$ timeout 60 tcpdump -ni enp1s0 -vvv "icmp6 or udp port 546 or udp port 547 or udp port 67 or udp port 68"'
  echo "--- enp1s0 (WAN): look for ISP Router Advertisements and DHCPv6 replies ---"
  cat "$WANOUT"
  echo
  echo '$ timeout 60 tcpdump -ni enp2s0 -vvv "icmp6"'
  echo "--- enp2s0 (LAN): look for RAs (who advertises, Router Lifetime, prefixes, RDNSS) ---"
  cat "$LANOUT"
} >>"$OUT"
rm -f "$WANOUT" "$LANOUT"

# ---------------------------------------------------------------- done
section "End of report"
runsh 'date -Is'

echo
echo "Report written to: $OUT"
echo "Size: $(wc -c <"$OUT") bytes"
