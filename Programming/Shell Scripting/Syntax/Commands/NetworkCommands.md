# Linux Network Commands

> Essential network troubleshooting commands for DevOps and SRE work — diagnosing connectivity, inspecting open ports, tracing network paths, and testing DNS resolution.

---

## ping — Test Connectivity and Latency

```bash
# Basic usage:
ping google.com                 # continuous until Ctrl+C
ping -c 4 google.com            # send exactly 4 packets
ping -c 4 -i 2 google.com       # 4 packets, 2-second interval

# Example output:
# PING google.com (142.251.223.238): 56 data bytes
# 64 bytes from 142.251.223.238: icmp_seq=0 ttl=115 time=22.670 ms
# 64 bytes from 142.251.223.238: icmp_seq=1 ttl=115 time=26.844 ms
# 64 bytes from 142.251.223.238: icmp_seq=2 ttl=115 time=21.305 ms
# 64 bytes from 142.251.223.238: icmp_seq=3 ttl=115 time=21.478 ms
# --- google.com ping statistics ---
# 4 packets transmitted, 4 received, 0.0% packet loss
# round-trip min/avg/max/stddev = 21.305/23.074/26.844/2.239 ms
#                                                              ↑ latency
```

### Interpreting Results

```
0% packet loss    → healthy connection
100% packet loss  → no connectivity (or ICMP blocked by firewall)
<100% packet loss → congestion or instability
high stddev       → network jitter / unstable connection
```

### ping Flags

```
-c <count>    : send exactly N packets
-i <interval> : interval between packets (default: 1s)
-t <ttl>      : set TTL (Time-To-Live) value
-s <bytes>    : packet payload size (default: 56 bytes)
-W <timeout>  : wait time per reply (seconds)
-f            : flood ping — max speed, tests throughput (use carefully)
-a            : audible beep on response
-q            : quiet output — only shows summary
-v            : verbose output
-4            : force IPv4
-6            : force IPv6
```

**What ping can check:** network connectivity, DNS resolution, NIC health, network latency, internet access

---

## netstat / ss — View Network Connections

```bash
# netstat (older, widely available):
sudo netstat -tunp       # TCP+UDP connections with PID

# ss (modern replacement — faster, preferred):
sudo ss -tunp            # same as above
sudo ss -tlnp            # listening TCP ports only
sudo ss -an              # all sockets (numeric addresses)

# Output format:
# Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
# tcp        0      0 127.0.0.1:5432          0.0.0.0:*               LISTEN      1342/postgres
# tcp        0      0 192.168.1.5:22          192.168.1.10:51876      ESTABLISHED 1023/sshd
# udp        0      0 0.0.0.0:68              0.0.0.0:*                           602/dhclient
```

### Output Field Meaning

```
Proto         → Protocol (tcp, udp)
Recv-Q        → Receive queue — data waiting to be read by application
Send-Q        → Send queue — data waiting to be sent
Local Address → IP:port on this machine
Foreign Addr  → IP:port of the remote machine
State         → Connection state
PID/Program   → Process ID and name using this connection
```

### netstat / ss Flags

```
-a    : all connections + listening ports
-t    : TCP only
-u    : UDP only
-n    : numeric (no DNS resolution — faster)
-l    : listening ports only
-p    : show PID and program name
-r    : show routing table
-i    : show network interface statistics
-s    : protocol statistics
-c    : refresh continuously every second
```

### TCP Connection States

| State | Meaning |
|-------|---------|
| `LISTEN` | Server waiting for incoming connection on this port |
| `SYN_SENT` | Client sent SYN, waiting for SYN-ACK |
| `SYN_RECEIVED` | Server received SYN, sent SYN-ACK, waiting for ACK |
| `ESTABLISHED` | Connection open, data flowing both ways |
| `FIN_WAIT_1` | Connection close initiated, FIN sent |
| `FIN_WAIT_2` | Waiting for other side to send FIN |
| `CLOSE_WAIT` | Received FIN, application hasn't closed yet |
| `CLOSING` | Both sides sent FIN, waiting for final ACK |
| `LAST_ACK` | Sent FIN, waiting for final ACK |
| `TIME_WAIT` | Waiting to ensure final ACK reached other side (2*MSL) |
| `CLOSED` | Connection fully terminated |

```bash
# Practical examples:
ss -tlnp | grep :8080             # what's using port 8080?
ss -tunp | grep ESTABLISHED       # all active connections
netstat -tunp | grep -v LISTEN    # exclude listening ports
lsof -i :443                      # who's using HTTPS port?
```

---

## traceroute — Trace Network Path

```bash
# Trace path to destination:
traceroute google.com
traceroute -n google.com       # no DNS resolution (faster)
traceroute -T google.com       # use TCP (bypasses ICMP/UDP firewalls)
traceroute -I google.com       # use ICMP (like Windows tracert)

# Example output:
# traceroute to google.com (142.251.223.238)
#  1  192.168.1.1    1.2ms   1.1ms   1.3ms    ← home router
#  2  10.0.0.1       8.5ms   8.4ms   8.6ms    ← ISP gateway
#  3  * * *                                   ← ICMP blocked
#  4  72.14.194.25   12.1ms  12.0ms  11.9ms   ← Google edge
#  5  142.251.223.238 22.3ms  22.1ms  22.5ms  ← destination
```

### How TTL-Based Tracing Works

```
Step 1: Send packet with TTL=1
        → First router decrements TTL to 0, drops packet, returns "Time Exceeded"
        → traceroute records: that router's IP + round-trip time

Step 2: Send packet with TTL=2
        → First router decrements to 1, passes forward
        → Second router decrements to 0, drops, returns "Time Exceeded"
        → traceroute records: second router IP + time

...repeats with TTL = 3, 4, 5... until:
  → Destination receives packet before TTL hits 0
  → Returns ICMP Echo Reply (or TCP ACK)
  → traceroute knows it reached destination, stops
```

### TTL — Time-To-Live

```
TTL is NOT measured in time — it's measured in hops (router count).

Analogy: Passing a note down a line of people — 
  "Pass this on, but subtract 1 from the counter each time.
   When counter hits 0, throw the note away and send an error back."

Each router:
  1. Receives the packet
  2. Decrements TTL by 1
  3. If TTL == 0: drops packet, sends ICMP "Time Exceeded" back to sender
  4. If TTL > 0: forwards to next hop
```

### traceroute Flags

| Option | Description |
|--------|-------------|
| `-n` | Don't resolve IPs to hostnames (faster) |
| `-m <hops>` | Max hops (default: 30) |
| `-q <count>` | Probes per hop (default: 3, shown as 3 columns) |
| `-w <sec>` | Wait time for each response |
| `-I` | Use ICMP (like Windows `tracert`) |
| `-T` | Use TCP SYN packets (bypasses firewalls blocking ICMP/UDP) |

---

## dig / nslookup — DNS Lookups

```bash
# dig — detailed DNS query (preferred tool):
dig google.com              # A record
dig google.com MX           # mail server records
dig google.com NS           # name server records
dig +short google.com       # IP only (cleaner)
dig @8.8.8.8 google.com     # query specific DNS server (Google's)
dig -x 8.8.8.8              # reverse lookup (IP → hostname)
dig +trace google.com       # show full recursive resolution

# nslookup — simpler interactive alternative:
nslookup google.com
nslookup google.com 8.8.8.8  # specify DNS server
```

---

## curl / wget — HTTP Testing

```bash
# curl — test HTTP endpoints:
curl https://api.example.com/health          # GET request
curl -I https://example.com                  # headers only
curl -X POST -d '{"key":"val"}' \
     -H "Content-Type: application/json" \
     https://api.example.com/endpoint
curl -L https://example.com                  # follow redirects
curl -v https://example.com                  # verbose (shows TLS + headers)
curl -w "%{http_code}" -o /dev/null \
     https://example.com                     # status code only

# wget — download files:
wget https://example.com/file.zip
wget -O output.txt https://example.com
wget -q https://example.com                  # quiet mode
```

---

## Other Essential Commands

```bash
# Test if a port is reachable:
nc -zv hostname 443           # netcat: -z=scan, -v=verbose
telnet hostname 22            # old-school TCP test

# Routing table:
ip route show
route -n                      # older style

# Interface and IP info:
ip addr show                  # all interfaces
ip addr show eth0             # specific interface
ifconfig eth0                 # older alternative

# DNS and hostname:
hostname && hostname -I       # machine name + all IPs
cat /etc/resolv.conf          # configured DNS servers
cat /etc/hosts                # static DNS overrides
```

---

## Interview Q&A

**Q: What does `* * *` mean in traceroute output, and does it indicate failure?**
`* * *` on a hop means that router did not send an ICMP Time Exceeded response — either it blocks ICMP (common firewall policy, routers configured to silently drop), or it's very busy and drops probe packets. It does NOT necessarily mean failure: if later hops respond and the final destination is reached, the route is working. The `* * *` hop is just invisible. However, if `* * *` appears at the final hop and the connection fails, it likely indicates the destination is not responding or a firewall is blocking the port.

**Q: Why is `ss` preferred over `netstat` on modern systems?**
`ss` (socket statistics) reads from kernel netlink sockets directly, while `netstat` reads pseudo-files in `/proc/net/tcp` and `/proc/net/udp`. On systems with thousands of concurrent connections, `netstat` becomes very slow because it reads and parses large files. `ss` gets the same information much faster via a direct kernel interface. Both show the same data — prefer `ss` in production scripts for performance.

**Q: You see a port in `TIME_WAIT` state — what does that mean and is it a problem?**
`TIME_WAIT` is a normal TCP state after a connection closes. The side that sent the final FIN enters `TIME_WAIT` and stays there for 2×MSL (Maximum Segment Lifetime, typically 60s-120s). This ensures the remote side received the final ACK — if the ACK was lost, the remote will retransmit its FIN and the local side can respond. Large numbers of `TIME_WAIT` sockets indicate high connection turnover (e.g., many short-lived HTTP/1.0 requests). It's usually not a problem, but if you're running out of ephemeral ports, use `SO_REUSEADDR`, keep-alive connections, or connection pooling.
