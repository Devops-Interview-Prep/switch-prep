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

---

## Network Interface Commands

```bash
# List all network interfaces
ip link show
ip addr show           # with IP addresses

# Show routing table
ip route show
route -n

# Check interface stats (packets sent/received, errors)
ip -s link show eth0

# Bring interface up/down
ip link set eth0 up
ip link set eth0 down

# Assign IP to interface
ip addr add 192.168.1.100/24 dev eth0

# Delete IP from interface
ip addr del 192.168.1.100/24 dev eth0
```

## Linux Network Namespace (Foundation of Containers)

```bash
# Create network namespace (isolated networking stack)
ip netns add myns

# Run command in namespace
ip netns exec myns ip addr show

# Create veth pair (virtual ethernet pair — like a pipe)
ip link add veth0 type veth peer name veth1

# Move one end into namespace
ip link set veth1 netns myns

# This is how Docker creates isolated container networking!
```

Container networking works by:
1. Creating a network namespace for each container
2. Creating a `veth` pair
3. One end in container namespace, other end on host bridge (docker0 / cni0)
4. Bridge routes traffic between containers and to external network

## Docker Networking — Interface Types

```
Host machine interfaces:
  docker0      → default bridge (172.17.0.0/16)
  br-xxxxxxxx  → user-defined bridge network
  vethXXXXX    → one end of each container's veth pair

Container sees:
  eth0         → the other end of veth pair
  lo           → loopback
```

## Common Interview Questions

**Q: What is a veth pair and how does Docker use it?**
A veth (virtual ethernet) pair is like a virtual cable — packets sent into one end come out the other. Docker creates one veth per container. One end goes into the container's network namespace (appears as `eth0` inside the container), the other end connects to the `docker0` bridge on the host. The bridge provides routing between containers and to the outside world via IP forwarding + NAT.

**Q: Why does each container get its own network namespace?**
Network namespaces give containers complete isolation — their own IP address, routing table, firewall rules, and loopback. Without this, containers would share the host's network stack and could bind to the same ports or sniff each other's traffic. Kubernetes uses the same mechanism: each pod gets a network namespace, and all containers in a pod share it (which is why sidecar containers can communicate on localhost).


