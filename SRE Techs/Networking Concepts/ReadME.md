# OSI Model
The OSI (Open Systems Interconnection) model is a conceptual model developed by the International Organization for Standardization (ISO) that describes how communications should occur in a computer network. In other words, the OSI model defines a framework for computer network communications.

The OSI model is composed of seven layers:

**1. Physical Layer**        
    The physical layer, also referred to as layer 1, deals with the physical connection between devices; this includes the medium, such as a wire, and the definition of the binary digits 0 and 1. Data transmission can be via an electrical, optical, or wireless signal. Consequently, we need data cables or antennas, depending on our physical medium.

**2. Data Link Layer**      
    The physical layer defines a medium to transmit our signal. The data link layer, i.e., layer 2, represents the protocol that enables data transfer between nodes on the same network segment. Let’s put it in simpler terms. The data link layer describes an agreement between the different systems on the same network segment on how to communicate. A network segment refers to a group of networked devices using a shared medium or channel for information transfer. For example, consider a company office with ten computers connected to a network switch; that’s a network segment.

**3. Network Layer**   
    The network layer, i.e., layer 3, is concerned with sending data between different networks. In more technical terms, the network layer handles logical addressing and routing, i.e., finding a path to transfer the network packets between the diverse networks.   
    Examples of the network layer include Internet Protocol (IP), Internet Control Message Protocol (ICMP), and Virtual Private Network (VPN) protocols such as IPSec and SSL/TLS VPN.

**4. Transport Layer**   
    Layer 4, the transport layer, enables end-to-end communication between running applications on different hosts   
    Examples of layer 4 are Transmission Control Protocol (TCP) and User Datagram Protocol (UDP).

**5. Session Layer**
    The session layer is responsible for establishing, maintaining, and synchronising communication between applications running on different hosts. Establishing a session means initiating communication between applications and negotiating the necessary parameters for the session. Data synchronisation ensures that data is transmitted in the correct order and provides mechanisms for recovery in case of transmission failures  
    Examples of the session layer are Network File System (NFS) and Remote Procedure Call (RPC).

**6. Presentation Layer**  
    The presentation layer ensures the data is delivered in a form the application layer can understand. Layer 6 handles data encoding, compression, and encryption. An example of encoding is character encoding, such as ASCII or Unicode.

**7. Application Layer**    
    The application layer provides network services directly to end-user applications. Your web browser would use the HTTP protocol to request a file, submit a form, or upload a file.   
    The application layer is the top layer, and you might have encountered many of its protocols as you use different applications. Examples of Layer 7 protocols are HTTP, FTP, DNS, POP3, SMTP, and IMAP. Don’t worry if you are not familiar with all of them.


# TCP/IP Model

**1. Application Layer**   
     The OSI model application, presentation and session layers, i.e., layers 5, 6, and 7, are grouped into the application layer in the TCP/IP model.  
**2. Transport Layer**  
     This is layer 4.  
**3. Internet Layer**   
    This is layer 3. The OSI model’s network layer is called the Internet layer in the TCP/IP model.  
**4. Link Layer**     
    This is layer 2.


# IP Addresses and Subnets

Every host on the network needs a unique identifier for other hosts to communicate with him. Without a unique identifier, the host cannot be found without ambiguity. When using the TCP/IP protocol suite, we need to assign an IP address for each device connected to the network.

*For a network 192.168.1.0/24*      
    192.168.1.0 → Reserved as the network address. It identifies the network itself, not a specific device.   
    192.168.1.255 → Reserved as the broadcast address. It's used to send data to all devices on the 192.168.1.0/24 network.   
    That means only the addresses from 192.168.1.1 to 192.168.1.254 can be assigned to devices like computers, printers, or phones. These are the usable host addresses.

*RFC 1918 defines the following three ranges of private IP addresses:*
    10.0.0.0 - 10.255.255.255 (10/8)   
    172.16.0.0 - 172.31.255.255 (172.16/12)   
    192.168.0.0 - 192.168.255.255 (192.168/16)

*Router*     
    A router forwards data packets to the proper network. Usually, a data packet passes through multiple routers before it reaches its final destination. The router functions at layer 3, inspecting the IP address and forwarding the packet to the best network (router) so the packet gets closer to its destination.

# UDP and TCP

The IP protocol allows us to reach a destination host on the network; the host is identified by its IP address. We need protocols that would enable processes on networked hosts to communicate with each other. There are two transport protocols to achieve that: UDP and TCP.

**UDP**   
    UDP (User Datagram Protocol) allows us to reach a specific process on this target host. UDP is a simple connectionless protocol that operates at the transport layer, i.e., layer 4. Being connectionless means that it does not need to establish a connection. UDP does not even provide a mechanism to know that the packet has been delivered.

    A port number is:
        16 bits long → that’s 2 bytes or 2 octets
        That gives 2¹⁶ = 65,536 possible values
        Valid port range = 1 to 65,535
    Port 0 is reserved and generally not used in practice

**TCP**
- TCP (Transmission Control Protocol) is a connection-oriented transport protocol. It uses various mechanisms to ensure reliable data delivery sent by the different processes on the networked hosts. Like UDP, it is a layer 4 protocol. Being connection-oriented, it requires the establishment of a TCP connection before any data can be sent.
- In TCP, each data octet has a sequence number; this makes it easy for the receiver to identify lost or duplicated packets. The receiver, on the other hand, acknowledges the reception of data with an acknowledgement number specifying the last received octet.
- A TCP connection is established using what’s called a three-way handshake. Two flags are used: SYN (Synchronise) and ACK (Acknowledgment).   

*The packets are sent as follows:*  

1. SYN Packet: The client initiates the connection by sending a SYN packet to the server. This packet contains the client’s randomly chosen initial sequence number.
   
2. SYN-ACK Packet: The server responds to the SYN packet with a SYN-ACK packet, which adds the initial sequence number randomly chosen by the server.

3. ACK Packet: The three-way handshake is completed as the client sends an ACK packet to acknowledge the reception of the SYN-ACK packet.

# Encapsulation
encapsulation. In this context, encapsulation refers to the process of every layer adding a header (and sometimes a trailer) to the received unit of data and sending the “encapsulated” unit to the layer below.

we have the following four steps: 

1. Application data:   
   It all starts when the user inputs the data they want to send into the application. For example, you write an email or an instant message and hit the send button. The application formats this data and starts sending it according to the application protocol used, using the layer below it, the transport layer.
   
2. Transport protocol segment or datagram:   
   The transport layer, such as TCP or UDP, adds the proper header information and creates the TCP segment (or UDP datagram). This segment is sent to the layer below it, the network layer.

3. Network packet:    
   The network layer, i.e. the Internet layer, adds an IP header to the received TCP segment or UDP datagram. Then, this IP packet is sent to the layer below it, the data link layer.

4. Data link frame:    
   The Ethernet or WiFi receives the IP packet and adds the proper header and trailer, creating a frame.

The process has to be reversed on the receiving end until the application data is extracted.

# Ethernet

Ethernet is a set of networking technologies used for wired local area networks (LANs) — the cables and protocols that connect your computer to a router, switch, or modem in your home, office, or data center.

It defines:
- How devices on a local network communicate
- The format of data (Ethernet frames)
- How data is physically transmitted (e.g., over cables)

Two Key Things Ethernet Provides:
1. Data Link Layer Protocol:   
    It defines how to wrap data in a frame with MAC addresses so devices know where to send it.   
    Ensures reliable delivery on the local network (e.g., your PC to router).

2. Physical Connection Standard:   
    Uses cables like Cat5e, Cat6, or fiber optics.  
    Plugged into network ports on your computer/router/switch.1

**MAC Address**  
A MAC address (Media Access Control address) is a unique identifier assigned to a network interface (like the Ethernet or Wi-Fi card) on a device.

It operates at the Data Link Layer (Layer 2) of the OSI model and is used for local network communication (like between your laptop and your router).


# Life of a Packet

1. On the TryHackMe search page, you enter your search query and hit enter.    
   
   *packet cantaining: http request*  

2. Your web browser, using HTTPS, prepares an HTTP request and pushes it to the layer below it, the transport layer.
The TCP layer needs to establish a connection via a three-way handshake between your browser and the TryHackMe web server or loadbalancer. After establishing the TCP connection, it can send the HTTP request containing the search query. Each TCP segment created is sent to the layer below it, the Internet layer.  

   *TCP segment: http request with tcp connection*

1. The IP layer adds the source IP address, i.e., your computer, and the destination IP address, i.e., the IP address of the TryHackMe web server. For this packet to reach the router, your laptop delivers it to the layer below it, the link layer.
   
   *packet cantaining: TCP segment + sourceIP + DestinationIP*

2. Depending on the protocol, The link layer adds the proper link layer header and trailer, and the packet is sent to the router. 
      
   *Ethernet frame: layer3 + MAC address(source + router)*

3. The router removes the link layer header and trailer, inspects the IP destination, among other fields, and routes the packet to the proper link. Each router repeats this process until it reaches the router of the target server.
if your services are on cloud the request will be sent to loadbalancer 

# Telnet

The TELNET (Teletype Network) protocol is a network protocol for remote terminal connection. In simpler words, telnet, a TELNET client, allows you to connect to and communicate with a remote system and issue text commands. Although initially it was used for remote administration, we can use telnet to connect to any server listening on a TCP port number.

**Default PORT: 23**

Telnet uses client-server architecture — the server listens, the client connects and sends.

Telnet is insecure because:
- No encryption
- Passwords and commands are sent in plain text
- Vulnerable to packet sniffing and man-in-the-middle attacks

🔐 It's been replaced by SSH (Secure Shell) for most remote access tasks.



# SSH

SSH is a network protocol that lets you securely connect to a remote machine to execute commands, transfer files, or tunnel traffic — all over an encrypted connection.

**Default PORT: 22** 

- The server sends a host key so the client can verify it's talking to the right machine.
- The client checks this key against the list of known hosts (~/.ssh/known_hosts).
- Client and server do a key exchange
- They agree on: A session key,An encryption algorithm (e.g., AES)
- All further communication is encrypted using this session key.
- The client now proves who it is.
- Methods include:
  - Password
  - Public key authentication (id_rsa / id_ed25519)
  - SSH agents, 2FA, etc.

