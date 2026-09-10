# Network Models — OSI and TCP/IP

> Two reference models describe how network communication works. The OSI model (7 layers) is the conceptual standard used for teaching and troubleshooting. The TCP/IP model (4 layers) is what actually runs the internet. Understanding both is essential for networking interviews.

---

## OSI Model — 7 Layers

```
Layer 7: Application   — HTTP, FTP, DNS, SMTP, SSH
Layer 6: Presentation  — TLS/SSL, encoding, compression, encryption
Layer 5: Session       — NFS, RPC (session establishment/teardown)
Layer 4: Transport     — TCP, UDP (ports, segmentation, reliability)
Layer 3: Network       — IP, ICMP, routing between networks
Layer 2: Data Link     — Ethernet, MAC addresses, frames (same-segment comm)
Layer 1: Physical      — cables, fiber, WiFi radio signals (bits → signals)

Mnemonic (top-down): All People Seem To Need Data Processing
Mnemonic (bottom-up): Please Do Not Throw Sausage Pizza Away
```

### Layer-by-Layer Breakdown

```
Layer 7 — Application:
  Provides network services directly to end-user applications
  Your web browser uses HTTP to request pages
  Protocols: HTTP, HTTPS, FTP, DNS, SMTP, IMAP, SSH, Telnet, SNMP

Layer 6 — Presentation:
  Translates data between network format and application format
  Handles encoding (ASCII, Unicode), compression, encryption
  TLS/SSL encryption lives here — ensures data is unreadable in transit

Layer 5 — Session:
  Manages sessions (connections) between applications
  Establishes, maintains, and terminates dialogs
  Protocols: NFS (file sharing), RPC (remote procedure calls)

Layer 4 — Transport:
  End-to-end communication between processes (not hosts)
  Port numbers identify which process receives data
  TCP: reliable, ordered delivery; UDP: fast, connectionless
  Multiplexing: multiple conversations over same IP address via ports

Layer 3 — Network:
  Routes packets between different networks (IP addresses)
  Routers operate at this layer
  Protocols: IP, ICMP, IPSec, BGP, OSPF

Layer 2 — Data Link:
  Communication between devices on the SAME network segment
  MAC addresses identify devices on local network
  Protocols: Ethernet, WiFi (802.11), ARP
  Switches operate at this layer (learn MAC-to-port mappings)

Layer 1 — Physical:
  Actual transmission of bits as signals
  Cables: Cat5e, Cat6, fiber optic; Wireless: radio frequencies
  Defines voltage levels, timing, pin layouts
```

---

## TCP/IP Model — 4 Layers

```
TCP/IP collapses OSI into 4 layers (what actually runs the internet):

TCP/IP Layer       OSI Layers it covers        Examples
─────────────────────────────────────────────────────
Application        7 + 6 + 5 (App+Pres+Session) HTTP, FTP, DNS, SSH, SMTP
Transport          4 (Transport)                 TCP, UDP
Internet           3 (Network)                   IP, ICMP
Link               2 + 1 (DataLink + Physical)   Ethernet, WiFi
```

**Key difference:** OSI is the theoretical model for understanding. TCP/IP is the practical model for implementation. When troubleshooting, both are used — "is this a layer 3 issue (routing)?" vs "is this layer 4 (firewall blocking port)?".

---

## IP Addresses and Subnets

```
IPv4 address: 32-bit, written as 4 octets (e.g., 192.168.1.100)
CIDR notation: IP/prefix (e.g., 192.168.1.0/24)

Subnet calculation for 192.168.1.0/24:
  Network address:    192.168.1.0   (identifies the network — reserved)
  Broadcast address:  192.168.1.255 (send to ALL hosts — reserved)
  Usable host range:  192.168.1.1 to 192.168.1.254 (254 hosts)
  Hosts per subnet:   2^(32-24) - 2 = 254

Common subnet sizes:
  /32  → single host (1 IP)
  /30  → 2 usable hosts (point-to-point links)
  /29  → 6 usable hosts
  /28  → 14 usable hosts
  /27  → 30 usable hosts
  /24  → 254 usable hosts (typical LAN)
  /16  → 65,534 usable hosts
  /8   → 16M+ hosts

RFC 1918 — Private IP ranges (not routable on internet):
  10.0.0.0/8          (10.0.0.0 - 10.255.255.255)
  172.16.0.0/12       (172.16.0.0 - 172.31.255.255)
  192.168.0.0/16      (192.168.0.0 - 192.168.255.255)

# Useful commands:
ip addr show                    # show all interfaces and their IPs
ip route show                   # routing table
ip route get 8.8.8.8           # what interface/gateway to reach Google DNS
```

---

## Packet Encapsulation — How Data Travels

```
Each OSI layer wraps data with its own header (and sometimes trailer):

Application layer produces: HTTP Request (data)
  ↓
Transport layer adds:       TCP Header | HTTP Data     → TCP Segment
  ↓
Network layer adds:         IP Header | TCP Segment    → IP Packet
  ↓
Data Link layer adds:       Eth Header | IP Packet | Eth Trailer → Ethernet Frame
  ↓
Physical layer sends:       bits as electrical/optical signal

At the receiver, each layer STRIPS its own header and passes the rest up.

Example — web request to google.com:
1. Browser creates HTTP GET request
2. TCP: adds source port (random), dest port 443, sequence numbers → TCP segment
3. IP: adds source IP (your IP), dest IP (google's IP) → IP packet
4. Ethernet: adds source MAC, dest MAC (router's MAC) → Ethernet frame
5. Sent as electrical signal on wire to router
6. Router: strips Ethernet frame, reads IP header, re-frames for next hop
7. Repeat until packet reaches Google's servers (each hop reframes)
8. Google's server reverses the process to extract HTTP request
```

---

## Ethernet and MAC Addresses

```
Ethernet: the dominant Layer 2 protocol for wired networks
- Defines frame format and how devices share a medium
- Cables: Cat5e (1Gbps), Cat6 (10Gbps), fiber (100Gbps+)
- Used in: LANs, data centers, cloud server racks

MAC Address (Media Access Control):
- 48-bit hardware address burned into network interface card (NIC)
- Format: 00:1A:2B:3C:4D:5E (hexadecimal, colon-separated)
- First 3 bytes = OUI (manufacturer identifier)
- Last 3 bytes = device-unique identifier
- Used for Layer 2 delivery on local network
- Not routable — only meaningful on the local segment

ARP (Address Resolution Protocol):
- Maps IP address → MAC address on local network
- Broadcast "Who has IP 192.168.1.1?" → device responds with its MAC
# View ARP cache:
arp -n             # Linux
ip neigh show      # Modern Linux
```

---

## TCP vs UDP

```
TCP (Transmission Control Protocol):
  Connection-oriented: 3-way handshake (SYN → SYN-ACK → ACK)
  Reliable: retransmits lost packets
  Ordered: reassembles out-of-order segments
  Flow control: prevents sender from overwhelming receiver
  Use cases: HTTP/HTTPS, SSH, database queries, file transfer
  Header size: 20+ bytes

UDP (User Datagram Protocol):
  Connectionless: no handshake
  Unreliable: no retransmit, no ordering, no duplicate detection
  Fast: lowest possible overhead (8-byte header)
  Application must handle errors if needed
  Use cases: DNS, video streaming, VoIP, gaming, NTP, DHCP

Port ranges:
  0-1023:     well-known ports (require root to bind)
  1024-49151: registered ports (application-specific)
  49152-65535: ephemeral/dynamic (OS assigns for outbound connections)

Ports are 16-bit: 2^16 = 65,536 total (0-65535; port 0 reserved)
```

---

## SSH and Telnet

```
Telnet (port 23):
- Plain text — no encryption
- Commands, passwords visible in packet captures
- Replaced by SSH for all secure remote access
- Still useful for testing TCP connectivity: telnet host port

SSH (Secure Shell, port 22):
- Encrypted: everything is protected (commands, output, passwords)
- Authentication: password, public key, or certificate
- Key exchange negotiates session keys using asymmetric crypto
- Then symmetric encryption (AES) for speed
- Uses: remote shell, file transfer (SFTP/SCP), port forwarding, tunneling

# SSH commands:
ssh user@host                          # connect
ssh -i ~/.ssh/key.pem user@host        # specify private key
ssh -L 8080:localhost:80 user@host     # local port forwarding
ssh -R 9090:localhost:3000 user@host   # remote port forwarding
scp file.txt user@host:/path/          # secure copy
```

---

## Interview Q&A

**Q: What is the difference between OSI model and TCP/IP model?**
OSI (7 layers) is a theoretical framework created by ISO as a reference model — it separates Session, Presentation, and Application into distinct layers for conceptual clarity. TCP/IP (4 layers) is the practical model that actually runs the internet — it combines OSI's top 3 layers into "Application" and bottom 2 layers into "Link". OSI is used for teaching and troubleshooting ("is this a Layer 3 or Layer 4 problem?"). TCP/IP reflects real protocols. When an interviewer asks "what layer does X operate at?", they usually mean the OSI model.

**Q: What is the difference between MAC addresses and IP addresses?**
MAC addresses (Layer 2) are hardware identifiers — 48-bit, assigned to the NIC by the manufacturer, used only for delivery on the local network segment. They don't cross routers. IP addresses (Layer 3) are logical identifiers assigned by network configuration — 32-bit (IPv4), used for routing between networks. Routers use IP to decide where to forward packets but rewrite the MAC addresses at each hop. ARP maps IP → MAC on the local segment. A packet from London to Tokyo keeps the same source/destination IPs the whole way, but its MAC addresses change at every router.

**Q: What happens if you ping a host and get "Request timeout" vs "Host unreachable"?**
"Host unreachable" (ICMP Type 3) means a router or the destination reports that it cannot deliver the packet — the route exists but the host is down, the port is closed, or a firewall actively rejected it. "Request timeout" means no response received within the timeout — either ICMP is blocked by a firewall (common on cloud instances), the host is down and no router sends an unreachable message, the packet is lost, or TTL expired (traceroute behavior). Request timeout is more ambiguous — the host could be up but firewalled.
