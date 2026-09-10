# AWS VPC — Virtual Private Cloud

> A VPC is a private, logically isolated section of the AWS cloud where you launch resources in a virtual network you define. You control the IP address range, subnets, routing, security, and network access — it's your private data center inside AWS.

---

## Core Concepts

```
VPC: A private network in a single AWS Region
     - You define the IP address space (CIDR block)
     - Regional: spans all AZs in the region
     - Isolated from other VPCs by default

Subnet: A subdivision of a VPC in a single AZ
     - Resources (EC2, RDS, Lambda) are launched into subnets
     - Subnets cannot span Availability Zones

Internet Gateway (IGW): Allows public internet access
NAT Gateway: Allows private subnets to reach internet (outbound only)
Route Table: Defines where traffic goes based on destination CIDR
NACL: Subnet-level stateless firewall
Security Group: Instance-level stateful firewall
VPC Endpoint: Private access to AWS services without internet
```

---

## Availability Zones

```
An AZ is a physically isolated data center within an AWS Region.
Each AZ has its own: power, cooling, networking, physical security.

AZs in the same region are connected via low-latency (<1ms), 
high-bandwidth fiber — used for synchronous replication.

When you create a VPC, it is regional.
Subnets are per-AZ — each subnet lives in exactly one AZ.

Why multi-AZ?
  If one AZ has a hardware failure, fire, or outage:
  → Resources in other AZs continue running
  → Route 53 / ALB / ASG automatically redirect to healthy AZs
```

---

## CIDR Blocks — IP Address Ranges

```
CIDR = Classless Inter-Domain Routing
Format: <base-ip>/<prefix-length>

When creating a VPC, you specify a CIDR block:
  Example: 10.0.0.0/16

  /16 means: first 16 bits are "network", remaining 16 are "host"
  Total IPs = 2^(32-16) = 2^16 = 65,536 IP addresses
  
  Valid VPC CIDR sizes: /16 (65,536 IPs) to /28 (16 IPs)
```

### AWS Reserved IPs Per Subnet

```
AWS reserves 5 IPs in EVERY subnet (not in the VPC itself).

Example for subnet 10.0.1.0/24:

IP Address     Reserved For
──────────────────────────────────────────────────────
10.0.1.0       Network address (subnet identifier)
10.0.1.1       VPC router (AWS default gateway)
10.0.1.2       DNS server (AmazonProvidedDNS)
10.0.1.3       Reserved for future AWS use
10.0.1.255     Broadcast address (not usable in AWS)

Usable IPs in /24: 256 - 5 = 251
Usable IPs in /16: 65,536 - 5 = 65,531
```

---

## Subnets — Public, Private, Isolated

```
A subnet is a segment of a VPC's CIDR, tied to one AZ.
Resources in the same subnet can communicate directly.
Traffic between subnets goes through the VPC router.
```

| Subnet Type | Internet Route | Outbound Internet | Use Case |
|-------------|---------------|------------------|----------|
| **Public** | Has IGW route | Yes (via IGW) | ALB, Bastion hosts, NAT Gateway itself |
| **Private** | No IGW route | Yes (via NAT GW) | App servers, backend APIs, EKS nodes |
| **Isolated** | None | No | RDS databases, internal processing jobs |

```bash
# Create a subnet via CLI:
aws ec2 create-subnet \
  --vpc-id vpc-0abc123def456 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a

# Tag it:
aws ec2 create-tags \
  --resources subnet-0abc123 \
  --tags Key=Name,Value=private-subnet-1a
```

---

## Route Tables

```
A route table defines where traffic goes based on destination CIDR.
Each route has:
  Destination: CIDR block (e.g., 0.0.0.0/0, 10.0.2.0/24)
  Target:      Where to send the traffic (IGW, NAT GW, local, TGW)

Every VPC has a main route table (auto-created).
Subnets not explicitly associated inherit the main route table.
A subnet can only have ONE route table at a time.
```

### Example Route Table Entries

```
Public subnet route table (routes traffic to IGW):
Destination      Target         Meaning
─────────────────────────────────────────────────────────
10.0.0.0/16      local          VPC-internal traffic stays local
0.0.0.0/0        igw-abc123     All internet traffic → Internet Gateway

Private subnet route table (routes to NAT Gateway):
Destination      Target         Meaning
─────────────────────────────────────────────────────────
10.0.0.0/16      local          VPC-internal stays local
0.0.0.0/0        nat-def456     Outbound internet → NAT Gateway
172.31.0.0/22    tgw-xyz789     Corporate network → Transit Gateway
10.1.0.0/16      vgw-ghi012     On-prem network → VPN Gateway
```

---

## Internet Gateway (IGW)

```
IGW enables internet access for resources inside a VPC.

Rules:
  - One IGW per VPC (1:1 mapping)
  - IGW cannot be detached while resources in the VPC are running
  - Performs NAT for instances with public IPv4 addresses
  - Only instances with a public IP or Elastic IP can use it

Without IGW → no internet access (public or private)
With IGW + route (0.0.0.0/0 → igw) + public IP → internet access
```

---

## NAT Gateway — Outbound Internet for Private Subnets

```
NAT = Network Address Translation

Private subnet instances have no public IP.
NAT Gateway translates private IPs to its own public IP for outbound requests.
The internet cannot initiate connections back to private instances (inbound blocked).

NAT Gateway vs NAT Instance:
  NAT Gateway: AWS-managed, auto-scales, highly available within an AZ
  NAT Instance: Self-managed EC2 with NAT AMI, you handle scaling and patching

Why create one NAT Gateway per AZ?
  1. High availability: if one AZ goes down, other AZs still have their own NAT
  2. Cost: cross-AZ traffic incurs extra data transfer charges
     → Private subnet in us-east-1a should use NAT GW in us-east-1a (same AZ)
```

```bash
# Allocate an Elastic IP for NAT Gateway:
aws ec2 allocate-address --domain vpc

# Create NAT Gateway in public subnet:
aws ec2 create-nat-gateway \
  --subnet-id subnet-PUBLIC-0abc123 \
  --allocation-id eipalloc-0abc123def
```

---

## VPC Endpoints — Private Access to AWS Services

```
By default, traffic from your VPC to AWS services (S3, DynamoDB, SSM) 
goes through the public internet (via NAT Gateway or IGW).

VPC Endpoints create a private path — no internet required.
Result: faster, cheaper, more secure.
```

| Endpoint Type | Works With | How It Works |
|--------------|------------|--------------|
| **Gateway Endpoint** | S3, DynamoDB only | Adds a route in the route table to AWS backbone |
| **Interface Endpoint** | 100+ AWS services | Creates an ENI (private IP) in your subnet |

```
Real-world example:
  BEFORE (without VPC Endpoint):
    EC2 (private subnet) → NAT Gateway → public internet → s3.amazonaws.com
    Cost: NAT Gateway data processing + transfer charges

  AFTER (with S3 Gateway VPC Endpoint):
    EC2 (private subnet) → AWS internal backbone → S3
    Cost: free (S3 gateway endpoints have no hourly charge)
    Security: traffic never leaves AWS network
```

---

## Network ACLs (NACLs) vs Security Groups

```
NACL: Subnet-level, stateless firewall
SG:   Instance-level, stateful firewall
```

### NACL Rules

```
- Applies to ALL instances in associated subnets
- Rules evaluated in order: lowest rule number first
- First matching rule wins (explicit allow OR deny)
- Default NACL: allows all inbound + outbound traffic
- Custom NACL: denies all by default (must add allow rules)
- Must explicitly allow BOTH inbound and outbound for each flow
  (stateless = no connection tracking)

Example: Allow HTTP from internet on a public subnet
  Inbound rule  100: Allow TCP 80 from 0.0.0.0/0
  Outbound rule 100: Allow TCP 1024-65535 to 0.0.0.0/0  ← required! (ephemeral ports)
```

### NACL vs Security Group Comparison

| Aspect | NACL | Security Group |
|--------|------|----------------|
| Level | Subnet | Instance (ENI) |
| State | Stateless — must allow both directions | Stateful — response auto-allowed |
| Rules | Allow AND Deny | Allow only (deny by default) |
| Evaluation | In order (lowest number first) | All rules evaluated together |
| Default | Allows all | Denies all inbound, allows all outbound |
| Use case | Broad subnet-level protection, explicit deny | Per-instance access control |

---

## VPC Peering

```
VPC peering creates a direct network connection between two VPCs.
Resources in peered VPCs can communicate using private IP addresses.

Can peer:
  - VPCs in same region
  - VPCs across regions (inter-region peering, higher latency + cost)
  - VPCs in different AWS accounts

Key constraint:
  NO transitive peering.
  If A ↔ B and B ↔ C, then A cannot talk to C — you must create A ↔ C peering.
  VPC peering is point-to-point only.

CIDR overlap is NOT allowed:
  VPC A: 10.0.0.0/16 and VPC B: 10.0.1.0/24 → overlap, cannot peer.
```

```
Setup Steps:
1. Create peering connection (VPC A requests VPC B)
2. VPC B owner accepts the request
3. Update VPC A's route table: destination = VPC B CIDR, target = peering connection
4. Update VPC B's route table: destination = VPC A CIDR, target = peering connection
5. Update security groups to allow traffic from peered VPC's CIDR
```

---

## Transit Gateway — Hub-and-Spoke for Many VPCs

```
Problem: 10 VPCs that all need to talk to each other + on-prem.
VPC Peering solution: 10×9/2 = 45 peering connections. Unmanageable.

Transit Gateway (TGW) is a regional hub that connects:
  - Multiple VPCs (attach them to TGW)
  - VPN connections (to on-prem)
  - AWS Direct Connect (dedicated fiber to AWS)
  - Other TGWs (inter-region peering)

Each connection is an "attachment":
  VPC Attachment, VPN Attachment, Direct Connect Attachment, Peering Attachment

TGW has its own route tables (separate from VPC route tables):
  - Multiple TGW route tables for traffic isolation (dev vs prod)
  - Each attachment associates with a TGW route table

Multi-account: share TGW across accounts via AWS Resource Access Manager (RAM)
```

| | VPC Peering | Transit Gateway |
|--|-------------|----------------|
| Architecture | Point-to-point | Hub-and-spoke |
| Transitive routing | No | Yes |
| Scale | Works for ~5 VPCs | Works for 100s of VPCs |
| Cost | Free | Per attachment + data processing |
| Cross-account | Yes | Yes (via RAM) |

---

## Egress-Only Internet Gateway

```
Applies to IPv6 only.

Problem with IPv6:
  Every IPv6 address is globally routable — no NAT for IPv6.
  A private instance with IPv6 could be reached from the internet.

Egress-Only IGW (EOIGW):
  - Allows OUTBOUND IPv6 traffic from private subnets to internet
  - BLOCKS inbound IPv6 connections from the internet
  - IPv6 equivalent of a NAT Gateway (but for IPv6, addresses aren't masked)

Use case:
  Private subnet instances with IPv6 need internet access for updates,
  but should not be reachable from the internet.
```

---

## DHCP Options Set

```
When an EC2 instance launches in a VPC, it gets network settings via DHCP:
  - DNS server IP (AmazonProvidedDNS or custom)
  - Domain name (used for short hostnames)
  - NTP servers (optional)
  - NetBIOS settings (optional)

The VPC has one DHCP options set associated with it.
You can create a custom DHCP options set to:
  - Use your own internal DNS server (e.g., unbound, Windows DNS)
  - Set a custom domain name for internal name resolution
  - Point to custom NTP servers for time sync
```

---

## Managed Prefix Lists

```
A Managed Prefix List = a named collection of CIDR blocks.
Use them in: security groups, route tables, and NACLs.

Benefits:
  1. Centralize common IP ranges in one place
  2. Update one prefix list → all security groups using it auto-update
  3. AWS maintains prefix lists for AWS services (e.g., CloudFront IPs)

Types:
  Customer-managed: You define the CIDRs (e.g., your office IPs, on-prem ranges)
  AWS-managed: AWS updates automatically (e.g., com.amazonaws.global.cloudfront.origin-facing)

Example use: Instead of adding 20 CIDR rules to every security group for 
  your VPN ranges, create one prefix list "vpn-ips" and reference it.
```

---

## Interview Q&A

**Q: What is the difference between a Security Group and a NACL?**
Security Groups are stateful, instance-level firewalls — when you allow inbound traffic, the response is automatically allowed (no outbound rule needed). NACLs are stateless, subnet-level firewalls — every packet is evaluated independently, so you must explicitly allow both directions (including ephemeral ports 1024-65535 for responses). Security groups only support allow rules; NACLs support both allow and deny rules. Use security groups for per-instance control and NACLs for subnet-level protection or when you need explicit deny rules (e.g., blocklist a CIDR).

**Q: What is the difference between a NAT Gateway and an Internet Gateway?**
An Internet Gateway enables two-way communication: public subnet instances can receive inbound connections from the internet (if public IP assigned) and send outbound. A NAT Gateway only enables outbound communication for private subnet instances — it translates private IPs to its own public IP for outbound requests, but blocks all inbound connections. NAT Gateway must be deployed in a public subnet (it uses an IGW for its own internet access). Private subnet instances route 0.0.0.0/0 to the NAT Gateway, not the IGW.

**Q: Why is transitive VPC peering not supported, and how does Transit Gateway solve it?**
VPC peering creates a direct, point-to-point connection between two VPCs. Transitive routing (A→B→C) would require the peering connection to forward traffic not destined for that VPC — this is intentionally not allowed to keep peering simple and avoid unintended network paths. If you need A to reach C via B, you must create a direct A-C peering. Transit Gateway solves this by acting as a centralized hub with its own routing engine — every VPC attaches to TGW, TGW routes between them, and transitive routing is fully supported through TGW route tables.
