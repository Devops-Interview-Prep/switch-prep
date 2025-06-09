# Transport Layer Protocols (Layer 4 - OSI Model)

**1. TCP (Transmission Control Protocol)**

- Connection-oriented: Ensures reliable data transmission by establishing a connection first (3-way handshake).

- Reliability: Guarantees delivery, order, and error checking.

- Use cases: Web browsing (HTTP/HTTPS), Email (SMTP, IMAP), File transfer (FTP).

- Ports: Uses port numbers (e.g., 80 for HTTP, 443 for HTTPS).

- Features: Flow control, congestion control, retransmission of lost packets.


**2. UDP (User Datagram Protocol)**

- Connectionless: Sends packets without establishing a connection.

- No guarantee: No reliability, ordering, or error checking by default.

- Use cases: Video streaming, VoIP, DNS, gaming.

- Faster: Lower overhead than TCP.


**3. SCTP (Stream Control Transmission Protocol)**

- Hybrid: Combines features of TCP and UDP.

- Multi-homing: Supports multiple IP addresses.

- Use cases: Telecom signaling (SS7 over IP), 4G LTE control plane.


#  Internet Layer Protocols (Layer 3 - OSI Model)

**1. IP (Internet Protocol)**
- IPv4: 32-bit addressing, widely used, limited to ~4.3 billion addresses.

- IPv6: 128-bit addressing, designed to overcome IPv4 limitations.

- Unreliable: Does not guarantee delivery or order.

**Others:** ICMP (Internet Control Message Protocol),  IGMP (Internet Group Management Protocol)


# Application Layer Protocols (Layer 7 - OSI Model)

**1. HTTP/HTTPS (HyperText Transfer Protocol / Secure)**

- HTTP: Stateless, used for web traffic.

- HTTPS: Encrypted with TLS/SSL.

- Use cases: Websites, REST APIs.

**2.  DNS (Domain Name System)** 

- Resolves domain names (e.g., google.com) to IP addresses.

- Uses UDP (port 53) and sometimes TCP.

**Others:**   
FTP/SFTP (File Transfer Protocol / Secure), SMTP, IMAP, POP3 (Email protocols), SSH (Secure Shell), Telnet, SNMP (Simple Network Management Protocol), NTP (Network Time Protocol),

DHCP (Dynamic Host Configuration Protocol):
- Assigns IP addresses dynamically to devices in a network.


# gRPC and WebSockets

**gRPC**
- High-performance RPC framework built on HTTP/2.

- Supports streaming, multiplexing, and protobufs.

**WebSocket**
- Full-duplex communication over a single TCP connection.

- Ideal for real-time apps (chats, live updates).