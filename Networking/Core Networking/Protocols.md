# Network Protocols Reference

> Protocols define rules for communication between systems. Organized by OSI layer — understanding which layer each protocol operates at and why is a core networking interview topic.

---

## Layer 4 — Transport Protocols (TCP vs UDP)

```
OSI Model:
Layer 7 — Application    (HTTP, DNS, SSH, SMTP)
Layer 4 — Transport      (TCP, UDP, SCTP)
Layer 3 — Network        (IP, ICMP, IGMP)
Layer 2 — Data Link      (Ethernet, ARP)
Layer 1 — Physical       (cables, fiber, WiFi radio)
```

### TCP (Transmission Control Protocol)

```
Key properties:
- Connection-oriented (handshake before data)
- Reliable: guarantees delivery, order, no duplicates
- Flow control: receiver controls sender speed (TCP window)
- Congestion control: avoids overwhelming the network
- Uses port numbers (multiplexing on same IP)

Port examples:
  HTTP   → 80      HTTPS  → 443
  SSH    → 22      FTP    → 21
  SMTP   → 25      MySQL  → 3306
  PostgreSQL → 5432    Redis → 6379

TCP 3-Way Handshake (connection setup):
  Client ──SYN──────────────→ Server   (I want to connect, my seq=X)
  Client ←──SYN-ACK────────── Server   (OK, my seq=Y, ack=X+1)
  Client ──ACK──────────────→ Server   (Acknowledged, ack=Y+1)
  [ESTABLISHED — data flows]

TCP 4-Way Teardown (connection close):
  Client ──FIN──────────────→ Server   (Client done sending, FIN_WAIT_1)
  Client ←──ACK─────────────  Server   (Server acks FIN, CLOSE_WAIT → Client: FIN_WAIT_2)
  Client ←──FIN─────────────  Server   (Server done sending, LAST_ACK)
  Client ──ACK──────────────→ Server   (Client: TIME_WAIT → CLOSED after 2*MSL)
```

### UDP (User Datagram Protocol)

```
Key properties:
- Connectionless — no handshake, no state
- Unreliable: no delivery guarantee, no ordering, no duplicate detection
- No flow control or congestion control
- Lower overhead → faster for latency-sensitive applications

Use cases:
  DNS queries       → speed matters more than retrying
  Video streaming   → slight packet loss = glitch (acceptable)
  VoIP/gaming       → latency must be minimal; old packets useless
  DHCP              → must work before IP assigned
  NTP               → quick time sync queries
```

### TCP vs UDP Comparison

| Property | TCP | UDP |
|----------|-----|-----|
| Connection | Yes (handshake) | No |
| Reliability | Guaranteed delivery | Best-effort |
| Order | In-order delivery | Out-of-order possible |
| Speed | Slower (overhead) | Faster |
| Use case | HTTP, SSH, DB | DNS, streaming, VoIP |
| Header size | 20+ bytes | 8 bytes |

---

## Layer 3 — Network Protocols

### IP (Internet Protocol)

```
IPv4: 32-bit address, ~4.3 billion addresses
  Format: 192.168.1.100
  CIDR:   192.168.0.0/24  (256 addresses, /24 = 24-bit network prefix)

IPv6: 128-bit address, 340 undecillion addresses
  Format: 2001:0db8:85a3:0000:0000:8a2e:0370:7334
  Short:  2001:db8:85a3::8a2e:370:7334

# Check IP on Linux:
ip addr show                     # list all interfaces
ip route show                    # routing table
ip route get 8.8.8.8             # what route is used to reach a host
```

### ICMP (Internet Control Message Protocol)

```
# ICMP is used for network diagnostics — ping and traceroute use it
# It's a layer 3 protocol (alongside IP, not above it)

ICMP message types:
  Type 0: Echo Reply       ← ping response
  Type 3: Destination Unreachable (host/port/network unreachable)
  Type 8: Echo Request     ← ping sends this
  Type 11: Time Exceeded   ← used by traceroute (TTL expired)

# Ping: send 4 Echo Requests, measure round-trip time
ping -c 4 google.com
# PING google.com: icmp_seq=1 ttl=117 time=12.3 ms

# Traceroute: probe with increasing TTL to discover each hop
traceroute google.com
# Uses ICMP Time Exceeded responses from each router as TTL decrements

# Why firewalls block ICMP:
# - Prevents network mapping/scanning
# - Causes ping/traceroute to fail (shows as * * *)
```

---

## Layer 7 — Application Protocols

### HTTP/HTTPS

```
HTTP:  HyperText Transfer Protocol — stateless, plaintext
HTTPS: HTTP + TLS encryption (certificate-based)

HTTP methods:
  GET    → retrieve resource (idempotent)
  POST   → create resource
  PUT    → replace resource (idempotent)
  PATCH  → partial update
  DELETE → remove resource (idempotent)

Status codes:
  2xx → success  (200 OK, 201 Created, 204 No Content)
  3xx → redirect (301 Moved, 302 Found, 304 Not Modified)
  4xx → client error (400 Bad Request, 401 Unauth, 403 Forbidden, 404 Not Found)
  5xx → server error (500 Internal, 502 Bad Gateway, 503 Unavailable)

# Test HTTP with curl:
curl -I https://api.example.com           # headers only
curl -X POST -d '{"key":"val"}' -H "Content-Type: application/json" https://api.example.com
```

### DNS (Domain Name System)

```
DNS resolves human-readable names to IP addresses.

# DNS resolution chain:
Browser → /etc/hosts → Local DNS cache → Recursive resolver →
  → Root nameserver → TLD nameserver (.com) → Authoritative nameserver

DNS record types:
  A     → domain → IPv4 address   (example.com → 93.184.216.34)
  AAAA  → domain → IPv6 address
  CNAME → alias  → canonical name (www → example.com)
  MX    → mail server for domain
  NS    → authoritative nameserver
  TXT   → arbitrary text (SPF, DKIM, domain verification)
  PTR   → reverse DNS (IP → hostname)

# DNS uses UDP port 53 (TCP for zone transfers or large responses)

# Debug DNS:
nslookup example.com                      # basic lookup
dig example.com A                         # A record
dig +short example.com                    # just the IP
dig @8.8.8.8 example.com                  # query specific DNS server
dig -x 93.184.216.34                      # reverse lookup (PTR)
```

### SSH (Secure Shell)

```bash
# SSH uses port 22, encrypts all traffic
ssh user@hostname                          # connect to remote host
ssh -p 2222 user@host                      # non-standard port
ssh -i ~/.ssh/id_rsa user@host             # specific private key
ssh -L 8080:localhost:80 user@host         # local port forwarding
ssh -R 9090:localhost:3000 user@host       # remote port forwarding

# Generate SSH key pair:
ssh-keygen -t ed25519 -C "your@email.com"
# Copies public key to server:
ssh-copy-id user@host
```

---

## gRPC and WebSockets

```
gRPC:
- Built on HTTP/2 — supports multiplexing, header compression
- Uses Protocol Buffers (binary serialization) — smaller + faster than JSON
- Supports 4 patterns: unary, server streaming, client streaming, bidirectional streaming
- Use case: microservice-to-microservice communication (internal APIs)

WebSocket:
- Starts as HTTP, upgrades to WebSocket protocol (Upgrade header)
- Full-duplex: server can push to client without request
- Persistent connection over single TCP socket
- Use case: real-time apps (chat, live dashboard, collaborative editing, stock tickers)
- Port: same as HTTP/HTTPS (80/443, proxied by nginx/load balancer)
```

---

## Interview Q&A

**Q: Why does DNS use UDP instead of TCP?**
DNS queries are small (typically < 512 bytes) and latency-critical — adding a TCP handshake (1.5 round trips) before every lookup would significantly slow page loads. UDP's single packet request + single packet response is much faster. For responses too large for one UDP packet (> 512 bytes or 4096 bytes with EDNS0), DNS falls back to TCP. DNS also uses TCP for zone transfers between authoritative servers where reliability matters more than speed.

**Q: What is the TCP TIME_WAIT state and why does it exist?**
After the 4-way close, the client enters TIME_WAIT for 2*MSL (Maximum Segment Lifetime, typically 60-120 seconds). This serves two purposes: (1) ensures the final ACK reaches the server — if lost, the server retransmits its FIN and the client can re-ACK; (2) prevents old duplicate packets from a previous connection from being misinterpreted by a new connection on the same port. High-traffic servers can accumulate many TIME_WAIT states — tunable via `net.ipv4.tcp_tw_reuse`.

**Q: What is the difference between HTTP/1.1, HTTP/2, and HTTP/3?**
HTTP/1.1: text protocol, one request per TCP connection at a time (head-of-line blocking), keep-alive for connection reuse. HTTP/2: binary framing, multiplexed requests on a single TCP connection (no HTTP-level HOL blocking), header compression (HPACK), server push. HTTP/3: replaces TCP with QUIC (UDP-based transport), eliminates TCP HOL blocking entirely, faster connection setup (0-RTT), built-in encryption. gRPC is built on HTTP/2; most modern CDNs support HTTP/3.
