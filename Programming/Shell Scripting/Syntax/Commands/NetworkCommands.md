# ping

- `ping server-ip`
  - 100% packet loss in case of connection faliure
  - 0% packate loss for active connection
  - <100% packate loss may happen if server has high network traffic

- It can check:
  - network connectivity
  - internet connectivity 
  - network interface card
  - latancy on network
  - DNS Resolution

```
ping google.com
PING google.com (142.251.223.238): 56 data bytes
64 bytes from 142.251.223.238: icmp_seq=0 ttl=115 time=22.670 ms
64 bytes from 142.251.223.238: icmp_seq=1 ttl=115 time=26.844 ms
64 bytes from 142.251.223.238: icmp_seq=2 ttl=115 time=21.305 ms
64 bytes from 142.251.223.238: icmp_seq=3 ttl=115 time=21.478 ms
^C
--- google.com ping statistics ---
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 21.305/23.074/26.844/2.239 ms

# round-trip min/avg/max/stddev = 21.305/23.074/26.844/2.239 ms shows the latency 

```

```
Flag	                            Description
-c <count>	                        Number of packets to send.
E.g., ping -c 4 google.com  sends 4 packets.

-i <interval>	                    Interval (in seconds) between sending packets.
E.g., ping -i 2 google.com  sends 1 packet every 2 seconds.

-t <ttl>	                        Time To Live — sets max hops (how far packet can travel).

-s <size>	                        Packet size in bytes.
E.g., ping -s 1000 google.com sends 1000-byte packets.

-W <timeout>	                    Time to wait for a reply (in seconds).

-f                                  To send packates as fast as possible to test the network performance

-a                                   audible response

Linux specific.
-q	                                Quiet output — only shows summary.
-v	                                Verbose — gives more detailed output.
-4	                                Use IPv4 only.
-6	                                Use IPv6 only.

```

# Netstat

```
sudo netstat -tunp       # On older systems
sudo ss -tunp            # Faster, newer alternative
```

- network utility that displays:
  - Network Connections for TCP & UDP
  - Routing Tables
  - A Number of network Interfaces
  - Network Protocol Statistics

- It's helpful for troubleshooting, monitoring, and debugging network-related issues.
- Common Use Cases of netstat
  - View active network connections
  - See which ports are open and listening
  - Identify which process is using a specific port
  - Check interface statistics (bytes sent/received)
  - Monitor routing table

- **Flags**

```
Option	                Description
-a	                    Show all connections and listening ports
-t	                    Show TCP connections only
-u	                    Show UDP connections only
-n	                    Show IP addresses and port numbers numerically (no DNS resolution)
-l	                    Show only listening ports
-p	                    Show the PID and name of the program using the connection
-r	                    Show the routing table
-i	                    Show network interface statistics
-s	                    Show protocol statistics
-c	                    Continuously display output every second (like top)
```

- **Output**

- `netstat -tunp`
```
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 127.0.0.1:5432          0.0.0.0:*               LISTEN      1342/postgres
tcp        0      0 192.168.1.5:22          192.168.1.10:51876      ESTABLISHED 1023/sshd
udp        0      0 0.0.0.0:68              0.0.0.0:*                           602/dhclient
```
- `Proto`	            ->      Protocol (tcp, udp, etc.)
- `Recv-Q`	            ->      Receive queue — how much data is queued to be read
- `Send-Q`	            ->      Send queue — how much data is queued to be sent
- `Local Address`	    ->      IP and port on the local machine
- `Foreign Address`     ->      IP and port of the remote machine
- `State`	            ->      Connection state (e.g., LISTEN, ESTABLISHED, TIME_WAIT, etc.)
- `PID/Program name`	->      Process ID and name of the program using the connection

**Common TCP Connection States**

| **State**      | **Meaning**                                                                           |
| -------------- | ------------------------------------------------------------------------------------- |
| `LISTEN`       | The server is **waiting** for an incoming connection on a specified port.             |
| `SYN_SENT`     | The client has sent a SYN (synchronize) packet, **requesting to start a connection**. |
| `SYN_RECEIVED` | The server received SYN and sent a SYN-ACK back, **waiting for ACK** from client.     |
| `ESTABLISHED`  | The connection is **open**, and both sides are communicating.                         |
| `FIN_WAIT_1`   | Connection close initiated by one side (sent FIN).                                    |
| `FIN_WAIT_2`   | Waiting for the other side to send FIN.                                               |
| `CLOSE_WAIT`   | One side received FIN and waiting for the application to **close the connection**.    |
| `CLOSING`      | Both sides have sent FIN — **waiting for final ACK**.                                 |
| `LAST_ACK`     | Sent FIN, waiting for final ACK (on receiver's side).                                 |
| `TIME_WAIT`    | Waiting to make sure the other side received the ACK of its FIN.                      |
| `CLOSED`       | Connection is completely closed, and resources are released.                          |


# Traceroute

- traceroute shows the path (route) that your packet takes to reach a destination, hop-by-hop, across the internet or network.
- It helps identify:
  - Which routers the packet travels through.
  - Where the delay is occurring.
  - Where packets might be getting dropped.

**How It Works (in simple terms)**

- It sends UDP or ICMP packets with increasing TTL (Time-To-Live) values.
- Each router that forwards the packet decrements the TTL.
- When TTL becomes 0, the router sends back a "Time Exceeded" ICMP message.
- traceroute records the router’s IP and the time taken.
- It repeats this with TTL = 1, 2, 3... until it reaches the destination or times out.

**TTL**
- A number that tells how long a packet should stay "alive" in the network before being discarded.
- It’s like a self-destruct timer for packets — so they don’t wander the internet forever if something goes wrong.
- Even though it says "Time To Live", TTL is not measured in time — it’s measured in hops (i.e., how many routers the packet can pass through).
- *Simple Analogy*
  - Imagine you're passing a message through a line of 10 people. You say:
  - “Here’s a note. Pass it on — but only 9 people max.”
  - Each person:
    - Reads the note
    - Decreases the counter by 1
    - Passes it to the next
  - If it reaches someone and the counter is 0, they throw the note away — that’s how TTL works!
- *In Networking*
  - Each packet has a TTL number (e.g., 64).
  - Each router it passes through decreases TTL by 1.
  - If TTL reaches 0, the packet is discarded, and an error is sent back (ICMP: Time Exceeded).

  *Step-by-Step Example:*
- Step 1: TTL = 1
  - Packet is sent with TTL = 1.
  - The first router decreases TTL to 0, drops the packet, and replies:
    -  ❗ ICMP Time Exceeded message is sent back to your machine.
  - So traceroute knows who the first router is.  
-  Step 2: TTL = 2
   -  Packet is sent with TTL = 2.
   -  First router decrements it to 1, forwards it.
   -  Second router decrements it to 0, drops it, replies with: ❗ ICMP Time Exceeded
   -  Now traceroute learns the second router in the path.
-  This continues:
   -  TTL = 4, TTL = 5, ..., until:
      -  The packet finally reaches the destination before TTL hits zero.
   -  At the final destination:
      -  The server responds with a normal response (like ICMP Echo Reply or TCP SYN/ACK).
      -  At this point, traceroute knows it has reached the destination, and stops.

**Common Options**

| Option       | Description                                                 |
| ------------ | ----------------------------------------------------------- |
| `-n`         | Don’t resolve IPs to hostnames (faster)                     |
| `-m <hops>`  | Set max hops (default: 30)                                  |
| `-q <count>` | Number of probes per hop (default: 3)                       |
| `-w <sec>`   | Wait time for each response                                 |
| `-I`         | Use ICMP instead of UDP (like Windows `tracert`)            |
| `-T`         | Use TCP SYN packets (helpful when firewalls block ICMP/UDP) |

  