# Linux Network Commands

> Essential networking commands for troubleshooting connectivity, inspecting active connections, tracing routes, and diagnosing DNS and port issues. Core toolkit for DevOps, SRE, and system administration.

---

## ping — Test Connectivity and Latency

```bash
# Basic usage:
ping google.com                    # continuous ping until Ctrl+C
ping -c 4 google.com               # send exactly 4 packets
ping -c 4 -i 2 google.com          # 4 packets, 2 second interval

# Example output:
# PING google.com (142.251.223.238): 56 data bytes
# 64 bytes from 142.251.223.238: icmp_seq=0 ttl=115 time=22.670 ms
# --- google.com ping statistics ---
# 4 packets transmitted, 4 received, 0% packet loss
# round-trip min/avg/max/stddev = 21.3/23.1/26.8/2.2 ms

# Interpret results:
#   0% packet loss    → healthy connection
#   100% packet loss  → no connectivity (or ICMP blocked by firewall)
#   <100% loss        → network congestion or instability
#   high latency      → routing issue or distant server

# ping flags:
# -c <n>     : send exactly n packets
# -i <sec>   : interval between packets (default: 1s)
# -s <bytes> : packet size (default: 56 bytes)
# -t <ttl>   : set Time-To-Live value
# -W <sec>   : timeout for each reply
# -f         : flood ping (fastest possible, tests throughput)
# -4/-6      : force IPv4 or IPv6
# -q         : quiet output (only summary)
```

**ping checks:** network connectivity, DNS resolution, NIC health, network latency, internet access

---

## netstat / ss — View Network Connections

```bash
# netstat (older) — on many systems:
netstat -tunp        # TCP+UDP connections with PID

# ss (modern replacement, faster):
ss -tunp             # same output, faster
ss -tlnp             # listening TCP ports only
ss -an               # all sockets (numeric)

# Output columns:
# Proto  Recv-Q  Send-Q  Local Address    Foreign Address  State      PID/Program
# tcp    0       0       127.0.0.1:5432   0.0.0.0:*        LISTEN     1342/postgres
# tcp    0       0       192.168.1.5:22   192.168.1.10:... ESTABLISHED 1023/sshd
# udp    0       0       0.0.0.0:68       0.0.0.0:*                    602/dhclient

# Key flags:
# -a    all connections + listening
# -t    TCP only
# -u    UDP only
# -n    numeric (no DNS resolution, faster)
# -l    listening ports only
# -p    show PID and program name
# -r    show routing table
# -s    protocol statistics
```

### TCP Connection States

| State | Meaning |
|-------|---------|
| `LISTEN` | Server waiting for incoming connections on this port |
| `SYN_SENT` | Client sent SYN, waiting for SYN-ACK |
| `SYN_RECEIVED` | Server received SYN, sent SYN-ACK, waiting for ACK |
| `ESTABLISHED` | Connection open, data flowing |
| `FIN_WAIT_1/2` | One side initiated close, waiting for FIN from other side |
| `CLOSE_WAIT` | Received FIN, local app hasn't closed yet |
| `TIME_WAIT` | Waiting to ensure final ACK reached other side (2*MSL) |
| `CLOSED` | Connection fully terminated |

```bash
# Practical examples:
ss -tlnp | grep :8080           # what's using port 8080?
ss -tunp | grep ESTABLISHED     # active connections
netstat -tunp | grep -v LISTEN  # non-listening connections
lsof -i :443                    # who's using HTTPS port?
```

---

## traceroute — Trace Network Path

```bash
# Trace path to google.com (shows each router hop):
traceroute google.com
traceroute -n google.com          # numeric only (faster, no DNS)

# Example output:
# traceroute to google.com (142.251.223.238)
#  1  192.168.1.1    1.2ms   1.1ms   1.3ms    ← your router
#  2  10.0.0.1       8.5ms   8.4ms   8.6ms    ← ISP gateway
#  3  * * *                                    ← router blocking ICMP
#  4  72.14.194.25   12.1ms  12.0ms  11.9ms   ← Google network
#  5  142.251.223.238 22.3ms  22.1ms  22.5ms  ← destination

# * * * means: router either blocks ICMP or is very busy
# Increasing latency between hops = identifies bottleneck

# How traceroute works:
# 1. Sends packet with TTL=1 → first router decrements to 0, returns ICMP Time Exceeded
# 2. Sends packet with TTL=2 → second router returns ICMP Time Exceeded
# 3. Repeats with increasing TTL until destination reached

# Flags:
# -n         : don't resolve hostnames (faster)
# -m <hops>  : max hops (default: 30)
# -q <count> : probes per hop (default: 3)
# -w <sec>   : wait time per probe
# -I         : use ICMP (like Windows tracert)
# -T         : use TCP (bypasses firewalls blocking UDP/ICMP)
```

---

## dig / nslookup — DNS Lookups

```bash
# dig — detailed DNS query tool (preferred):
dig google.com                    # A record lookup
dig google.com A                  # explicitly request A record
dig google.com MX                 # mail server records
dig google.com NS                 # name server records
dig +short google.com             # IP only (cleaner output)
dig @8.8.8.8 google.com           # query specific DNS server
dig -x 8.8.8.8                    # reverse lookup (IP → hostname)

# nslookup — simpler alternative:
nslookup google.com
nslookup google.com 8.8.8.8       # use specific DNS server

# Check DNS resolution chain:
dig +trace google.com             # show full recursive resolution
```

---

## curl / wget — HTTP Testing

```bash
# curl — Swiss army knife for HTTP:
curl https://api.example.com              # GET request
curl -I https://example.com              # headers only
curl -X POST -d '{"key":"val"}' \
     -H "Content-Type: application/json" \
     https://api.example.com/endpoint
curl -o output.zip https://example.com/file.zip   # download
curl -L https://example.com              # follow redirects
curl -v https://example.com             # verbose (shows TLS handshake, headers)
curl -w "%{http_code}" -o /dev/null https://example.com  # just status code

# wget — download files:
wget https://example.com/file.zip        # download
wget -O output.txt https://example.com  # save with name
wget -q https://example.com             # quiet mode
```

---

## Other Useful Network Commands

```bash
# Check if a port is open on a remote host:
nc -zv host 443              # netcat: -z=scan, -v=verbose
telnet host 22               # test TCP connectivity to port

# Show routing table:
ip route show
route -n

# Show network interface info:
ip addr show                 # all interfaces
ip addr show eth0            # specific interface
ifconfig eth0                # older alternative

# DNS and hostname:
hostname                     # current hostname
hostname -I                  # all IP addresses
cat /etc/resolv.conf         # configured DNS servers
cat /etc/hosts               # static DNS overrides
```

---

## Interview Q&A

**Q: What is the difference between `netstat -tunp` and `ss -tunp`?**
Both show TCP and UDP connections with process information (`-p`), numeric output (`-n`), and filter to TCP+UDP (`-t` and `-u`). `ss` (socket statistics) is the modern replacement for `netstat` — it's significantly faster on systems with many connections because it reads from kernel netlink sockets directly, while `netstat` reads `/proc/net/tcp` files. `ss` is preferred for production systems, especially those with thousands of connections. `netstat` is still common in scripts and documentation because it's been around longer.

**Q: What does traceroute tell you and what do the `* * *` results mean?**
Traceroute shows each intermediate router (hop) between your machine and the destination, along with the round-trip time to each. This identifies where latency increases (bottleneck router) or where packets stop (network failure). `* * *` on a hop means that router is not sending ICMP Time Exceeded responses — either it blocks ICMP (common firewall policy), the router is very busy and drops probe packets, or it's configured to not send ICMP unreachable messages. `* * *` in the middle doesn't necessarily mean failure — if later hops respond, the route is working.

**Q: You can't connect to a service on port 5432 from another machine. How do you debug?**
Systematic approach: (1) `ping host` — is the host reachable at all? (2) `telnet host 5432` or `nc -zv host 5432` — can you reach the port? If not: (3) On the server: `ss -tlnp | grep 5432` — is the service actually listening on that port? Is it listening on `127.0.0.1:5432` (localhost only) instead of `0.0.0.0:5432`? (4) Check firewall: `iptables -L -n | grep 5432` or `ufw status` — is the port blocked? (5) Check security groups (AWS) or network ACLs — cloud-level firewall?
