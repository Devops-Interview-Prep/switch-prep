- A network interface is a point of connection between your computer and a network. It can be physical (like a Wi-Fi card or Ethernet port) or virtual (like loopback or Docker bridges).

- Imagine your computer is a house, and the network interface is a door that connects your house to the outside world (the network). You can have multiple doors (interfaces), each leading to different places (internet, internal network, virtual networks, etc.).

```
Type	                Example	                        Description
Loopback	            lo (127.0.0.1)	                Internal-only, connects to itself (used for testing, local apps)
Ethernet	            eth0, enp0s3	                Wired LAN interface
Wi-Fi	                wlan0, wlp3s0	                Wireless LAN interface
Virtual	                docker0, br0, tun0	            Used by containers, VPNs, virtual machines
Bridge	                br-xxxxx	                    Software switch connecting multiple interfaces (used in Docker)
```

- Each interface has:
  - A unique name (e.g., eth0, lo)
  - An IP address
  - A MAC address (hardware address)
  - Optional: Gateway, Subnet mask, DNS


# How the port connection works for ssh:

- Local machine	acts as a client and uses a random high port (e.g., 49832)
- Remote server	acts as the SSH server and listens on port 22 (by default)

