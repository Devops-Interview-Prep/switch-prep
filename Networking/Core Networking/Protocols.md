# Transport Layer Protocols (Layer 4 - OSI Model)

**1. TCP (Transmission Control Protocol)**

- Connection-oriented: Ensures reliable data transmission by establishing a connection first (3-way handshake).

- Reliability: Guarantees delivery, order, and error checking.

- Use cases: Web browsing (HTTP/HTTPS), Email (SMTP, IMAP), File transfer (FTP).

- Ports: Uses port numbers (e.g., 80 for HTTP, 443 for HTTPS).

- Features: Flow control, congestion control, retransmission of lost packets.

- **TCP Lifecycle: Overview of Connection States**

  - TCP uses a three-way handshake to establish connections and a four-step process to close them. Each step involves a state.

  - *TCP 3-Way Handshake (for establishing connection):*
    - Client → SYN → Server (SYN_SENT)
    - Server → SYN-ACK → Client (SYN_RECEIVED)
    - Client → ACK → Server → Now both go into ESTABLISHED state

  - *TCP Connection Termination (4-step close)*
    - Client sends FIN → enters FIN_WAIT_1
    - Server sends ACK → client enters FIN_WAIT_2, server enters CLOSE_WAIT
    - Server sends its FIN → client enters TIME_WAIT, server enters LAST_ACK
    - Client sends ACK, then after timeout enters CLOSED


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

**2. ICMP (Internet Control Message Protocol)**

- It is a network layer protocol (used alongside IP) that helps diagnose and report network errors — like a messenger between devices that says "something went wrong" or "everything’s okay".
- ICMP is like a delivery receipt system for the internet:
  - “Hey, your message couldn’t be delivered.”
  - “Your message took too long.”
  - “Your host is unreachable.”
  - “I’m alive! (ping)”
- ICMP is used for:

| Tool/Concept     | ICMP Role                                            |
| ---------------- | ---------------------------------------------------- |
| `ping`           | Sends **ICMP Echo Request**, expects **Echo Reply**  |
| `traceroute`     | Uses **ICMP Time Exceeded** to find hops             |
| Host unreachable | ICMP sends back a "destination unreachable" message  |
| TTL expired      | ICMP sends "Time Exceeded" message when TTL hits 0   |
| Network errors   | ICMP tells sender why a packet couldn’t be delivered |

- ICMP Packet Types (Common):

| Type | Name                    | Used For                             |
| ---- | ----------------------- | ------------------------------------ |
| `0`  | Echo Reply              | Sent in response to `ping`           |
| `3`  | Destination Unreachable | Host, network, or port unreachable   |
| `8`  | Echo Request            | Used by `ping` to check availability |
| `11` | Time Exceeded           | Used by `traceroute`                 |

- ICMP Can Be Blocked
  - Some firewalls block ICMP to avoid scanning or attacks.
  - That’s why ping or traceroute might not work to certain servers.

**Others:** IGMP (Internet Group Management Protocol)


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