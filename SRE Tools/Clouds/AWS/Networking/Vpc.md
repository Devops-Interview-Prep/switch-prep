# VPC 

- A private, isolated network within the AWS cloud
where you can launch and manage your resources
securely.

- We need vpc to To securely isolate and control network environments.
  

# Availability Zones

- An Availability Zone (AZ) is a physically isolated data center within an AWS Region. Each AZ has its own:
     - Power
     - Cooling
     - Network
     - Physical security
- But AZs in the same region are connected with low-latency, high-bandwidth fiber — typically <1ms.
  
- When you create a VPC (Virtual Private Cloud), it's regional — but your subnets are created per Availability Zone.

- This enables high availability and fault tolerance. If one AZ goes down (hardware failure, fire, etc.), your app can continue running in others.

# CIDR Blocks

- CIDR (Classless Inter-Domain Routing) is a method for allocating IP addresses and routing Internet Protocol (IP) packets.
- While Creating Vpc we need to specify a cidr block that defines the IP address range for the entire vpc.

Ex. 10.0.0.0/16

This block will have 2pow(32-16) = 65536 ips but 65531 usable ips

- AWS reserves 5 IP addresses in every subnet (not VPC) for internal networking purposes.
```
Ex. 

For a subnet like 10.0.1.0/24, these are reserved:

IP	Reserved For
10.0.1.0	Network address (subnet identifier)
10.0.1.1	Reserved by AWS for the VPC router
10.0.1.2	Reserved for DNS (AmazonProvidedDNS)
10.0.1.3	Reserved for future use
10.0.1.255	Broadcast address (not used, but still reserved)
```

# Subnets 

- A subnet is a smaller, segmented part of a larger
network that isolates and organizes devices within a
specific IP address range.

- Subnets are used for isolation, routing, load balancing, and network security

**Subnet Types:**   
 1. Public Subnet:    
   Has a route to an Internet Gateway (IGW), making instances inside it accessible from the internet (if public IP is assigned).   
   Usecase: Load balancers, Bastion Hosts

 2. Private Subnet:   
   Has no direct route to the internet. Instances use NAT Gateway or NAT Instance for outbound access.   
   Usecase: Application servers, backend APIs


 3. Isolated Subnet:    
   No outbound or inbound internet access. Used for strict internal services like databases or background jobs.   
   Usecase: Databases, internal processing jobs


# Route Tables

- Route Tables are mainly used to Define the protocol for traffic routing between the subnets.
- A single VPC can have as many as route tables it requires.
- f the dependencies are attached to the route table then they can't be deleted. 

-  Every VPC has a default route table
   -  When you create a VPC, a main route table is automatically created.
   -  You can create custom route tables as needed. 

-  Subnets must be explicitly associated with a route table
   -  If not, they inherit the main route table by default.
  
- Routes are matched by destination CIDR
  - Each route has:  
        1. Destination: A CIDR block (e.g., 0.0.0.0/0, 10.0.2.0/24)   
        2. Target: Where to send traffic (e.g., IGW, NAT Gateway, ENI, local)

```
Ex. Routes:
Destination	    Target	        Meaning
10.0.0.0/16	    local	        All VPC-internal traffic stays inside
0.0.0.0/0	    igw-abc123	    Internet-bound traffic goes to IGW
172.31.0.0/22	tgw-xyz456	    Send to Transit Gateway
10.1.0.0/16	    vgw-def789	    Send to VPN Gateway (on-prem)

# for the last entry 
From VPC to on-prem: 
Traffic for 10.1.0.0/16 leaves your VPC via the VPN Gateway to your on-prem network.

From on-prem to VPC: 
The on-prem network must have a route back to your VPC’s CIDR in its routing (and firewall rules). Then traffic can flow back over the VPN to your VPC.
```

# Internet Gateway(IGW)

- With the help of IGW (Internet Gateway), the resources present (e.g: EC2) in the VPC will enable to access the Internet.

- One VPC can't have more than one IGW 

- If resources are running in a certain VPC then IGW can not be detached from that particular VPC. 

- It performs network address translation (NAT) for instances that have public IPv4 addresses.

- It allows inbound traffic from the internet to reach your instances (if allowed by security groups and NACLs).

- Only instances with a public IPv4 address or Elastic IP can communicate directly with the internet via the IGW.



# Network Address Translation (NAT)

- Network Address Translation (NAT) is a process where one IP address space (usually private IPs) is mapped to another IP address space (usually public IPs). It allows resources in a private network (with private IPs) to access external networks like the internet without exposing their private IPs.

- An internal host can communicate with an internet server with help of NAT.

- The internet and a private network are separated by a NAT device

- At the same time, incoming traffic from the internet to these instances is blocked unless specifically allowed through other means.

- Each NAT Gateway must be launched in a public subnet in the same AZ as the private subnet it will serve.

**NAT Gateway:**   
AWS manages the gateway, scales it automatically, and provides high availability within an Availability Zone (AZ). It translates private IP addresses to its own public IP, allowing outbound internet traffic.

**NAT Instance:**   
You launch a specially configured EC2 instance (usually from a NAT AMI) in a public subnet. This instance performs NAT and routes traffic from private subnet instances to the internet. You manage scaling, patching, and availability.


**Why create NAT Gateway per AZ?**

1. *High availability and fault tolerance:*    
    If an AZ goes down, only the private subnet in that AZ loses NAT connectivity, others are unaffected.

2. *Cross-AZ traffic charges:*    
    NAT Gateway traffic across AZ boundaries incurs additional data transfer charges, so you want NAT Gateway in the same AZ as the private subnet.



# NACL Network Access Control Lists

- The NACL security layer for VPC serves as a firewall to manage traffic entering and leaving one or more subnets.

- The NACL for the default VPC is active and connected to the default subnets.

- Applies to all instances in one or more subnets it’s associated with

- Rules are evaluated in order starting from the lowest rule number, and the first matching rule is applied

- Every VPC has a default NACL that allows all inbound and outbound traffic

- Custom NACL By default, deny all inbound/outbound traffic unless explicitly allowed

- Each subnet must be associated with exactly one NACL, but you can associate multiple subnets to the same NACL


**Difference Between NACL and Security Group**

1. NACL Supports both allow and deny rules but sg Only allow rules (deny by default)

2. NACL rules Processed in order (lowest number first), but in sg all rules evaluated before allowing traffic

3. Default NACL allows all but Default SG denies all inbound, allows all outbound

**For SG(stateful):**
- If a connection is initiated from the outside (inbound), and you allow it via an inbound rule, then SG will automatically allow the response back out — even if your outbound rules seem to block it.

- Conversely, if your instance initiates a connection to the outside (like downloading a package), then outbound rules apply strictly.

**For NACL(stateless)**
- This means they don’t remember the state of a connection. Every inbound and outbound packet is evaluated independently, so you must explicitly allow both directions of traffic — even for responses!



# AWS VPC (Virtual Private Cloud) Peering

- VPC peering can establish the connection between two Virtual Private Clouds which enables you to route the traffic between two VPCs using the IP address. The virtual servers which are in the same network can communicate with each other with out VPC peering connections but the servers which are in the two different networks can't communicate with each other with out VPC peering.

- You can connect VPCs within the same region or across regions.

- Inter-Region Peering Supported, but latency is higher and data transfer costs apply (cross-region bandwidth charges).

- No transitive peering — if A is peered with B and B is peered with C, A cannot talk to C unless A-C is also peered.

- Can connect VPCs in different AWS accounts.

1. Create a Peering Connection
    - From VPC A, you create a request to peer with VPC B.
    - You must specify the account and VPC ID of VPC B.

2. Accept the Peering Request
    - VPC B's owner accepts the request from their side.

3. Update Route Tables
    - In VPC A's route table: Route to VPC B’s CIDR via Peering Connection.
    - In VPC B’s route table: Route to VPC A’s CIDR via Peering Connection.

4. Update security groups to allow inbound/outbound traffic from the peered VPC's IP range.


# Transit Gateway

Transit Gateway (TGW) is a regional network transit hub that connects:
1. Multiple VPCs
2. VPN Connections
3. AWS Direct Connect
4. Other Transit Gateways (via inter-region peering)

- You have many VPCs (say, 10+) that need to communicate with each other and with on-prem infrastructure — without having to manage many-to-many VPC peering.

- To connect VPCs or other networks to TGW, you create attachments:
    - VPC Attachments
    - VPN Attachments
    - Direct Connect Attachments
    - Peering Attachments (between TGWs)

- Route Tables
    - TGW has its own route tables, separate from VPC route tables.
    - You can create multiple route tables to isolate traffic (e.g., dev vs prod).
    - Each attachment is associated with a TGW route table.
    - You associate VPCs with a TGW route table to define how they send traffic.
    - Attachments propagate routes to a TGW route table.

- Multi-account support (via AWS RAM).

- Inter-region peering between TGWs (no NAT needed).

-  Pricing
    - Charged per attachment per hour.
    - Charged for data processing through the gateway (per GB).
    - Inter-region peering has additional transfer costs.



