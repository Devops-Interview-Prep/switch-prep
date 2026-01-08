# Intro 

- DNS is a distributed, hierarchical, read-heavy database that answers:

    - “Who knows the IP address (or other records) for this name?”

- It is:

    - Decentralized

    - Eventually consistent

    - Cached aggressively

    - Designed for scale, not immediacy

- DNS is a tree:
```
.
└── com
    └── example
        └── www
```
- The dot (.) at the top is the root zone.
- Root servers do NOT know IPs of websites.
- They only know Who is responsible for each TLD (.com, .org, .in, etc.)
- There are 13 logical root servers
    - Named A through M
    - Example root server reply:
    ```
    Query: www.example.com
    Answer: I don’t know, but .com is handled by these servers
    ```
🔹 TLD = Top-Level Domain
- Examples: .com, .org, .in, .io etc.
- Each TLD has authoritative servers.
- TLD servers know Which authoritative name servers own example.com

🔹 In Browsers:
- Traditional DNS → controlled by OS / network

- Modern browsers → can override DNS using DoH (DNS over HTTPS)

- Browsers may auto-switch to their own resolvers unless you stop them

```
Browser
 ↓
Operating System
 ↓
Configured DNS Resolver
 ↓
Recursive Resolver (ISP / 8.8.8.8 / 1.1.1.1)
```


# Recursive DNS (The “Finder”)

🔹 What is a Recursive Resolver?

- A recursive DNS server:

    - Accepts a query from a client

    - Takes responsibility to fully resolve it

    - Returns the final answer (or error)

- Examples:

    - ISP DNS (e.g., Airtel, Jio)

    - Public DNS:

        - 8.8.8.8 (Google)
            - Google Public DNS
            - Recursive DNS resolver
            - Free, global, highly available

        - 1.1.1.1 (Cloudflare)
        - 9.9.9.9 Quad9

    - Kubernetes:

        - CoreDNS (acts as recursive + caching)

🔹 How Recursive DNS Works (Step-by-Step)
- Query: www.example.com

```
1. Client → Recursive DNS
   "What is the IP for www.example.com?"

2. Recursive DNS → Root Server
   "Who handles .com?"

3. Root → Recursive DNS
   "Ask .com TLD servers"

4. Recursive DNS → .com TLD Server
   "Who handles example.com?"

5. TLD → Recursive DNS
   "Ask ns1.example.com"

6. Recursive DNS → Authoritative Server
   "What is the IP for www.example.com?"

7. Authoritative → Recursive DNS
   "Here is the IP: 93.184.216.34"

8. Recursive DNS → Client
   "93.184.216.34"

```

🔹 Caching in Recursive DNS

- Recursive DNS caches responses based on TTL.
```
Record: www.example.com → 93.184.216.34
TTL: 300 seconds
```
- For next 5 minutes:

    - No root

    - No TLD

    - No authoritative query

⚡ This is why DNS is fast

🔹 Failure Modes (Recursive DNS)

| Issue           | Symptom                |
| --------------- | ---------------------- |
| Cache poisoning | Wrong IP returned      |
| DNS cache miss  | Slow resolution        |
| Resolver down   | Entire internet “down” |
| High latency    | App startup slow       |
| NXDOMAIN cached | Domain appears broken  |


# Authoritative DNS (The “Source of Truth”)

- An authoritative DNS server:

    - Owns the DNS records for a domain

    - Gives final, definitive answers

    - Does not recurse

    - Examples:

        - Route53

        - Cloudflare DNS

        - Azure DNS

        - On-prem BIND servers

🔹 What Authoritative DNS Knows
- It stores records like:

| Record Type | Purpose           |
| ----------- | ----------------- |
| A / AAAA    | IP address        |
| CNAME       | Alias             |
| MX          | Mail              |
| TXT         | Verification      |
| NS          | Name servers      |
| SRV         | Service discovery |

# DNS in Kubernetes

🔹 CoreDNS in K8s

- CoreDNS acts as:

    - Recursive resolver for pods

    - Authoritative for cluster domains

🔹 Common K8s DNS Issues

| Issue                    | Cause              |
| ------------------------ | ------------------ |
| Pods can’t resolve names | CoreDNS down       |
| Slow pod startup         | DNS latency        |
| CrashLoop on startup     | DNS dependency     |
| NXDOMAIN                 | Wrong service name |


# TTL – The Most Important DNS Knob

- TTL Tradeoff

| TTL        | Pros          | Cons            |
| ---------- | ------------- | --------------- |
| High (1h+) | Low load      | Slow rollback   |
| Low (30s)  | Fast failover | High query cost |

📌 SRE Rule of Thumb

- Normal services: 300s

- Critical failover: 30–60s

- Rarely change: 3600s+

# DNS Record Types (Very Important)

1️⃣ A Record

```
Maps domain → IPv4

example.com → 93.184.216.34


Use case:

Websites

APIs

```

2️⃣ AAAA Record

```

Maps domain → IPv6

example.com → 2606:2800:220:1:248:1893:25c8:1946

```

3️⃣ CNAME (Canonical Name)

```

Alias of another domain

www.example.com → example.com


Rules:

Cannot coexist with other records

Resolves indirectly

Use case:

CDNs

Load balancers

```

4️⃣ MX (Mail Exchange)

```

Mail servers for a domain

example.com → mail.google.com (priority 10)


Lower number = higher priority.

```

5️⃣ TXT Record

```

Text metadata

Examples:

SPF

DKIM

Domain verification

v=spf1 include:_spf.google.com ~all

```

6️⃣ NS (Name Server)

```
Authoritative DNS servers for the domain

example.com → ns1.route53.aws

```

7️⃣ PTR Record (Reverse DNS)

```

IP → Domain

93.184.216.34 → example.com


Used in:

Email validation

Logging

Security

```

8️⃣ SRV Record

```

Service discovery

_service._proto.name → host:port


Example:

_ldap._tcp.example.com → ldap.example.com:389


Used heavily in:

Kubernetes

Consul

Active Directory

```

9️⃣ SOA (Start of Authority)

```

Domain metadata

Contains:

Primary DNS

Serial number

Refresh / Retry / Expiry

Used for zone transfers.

```

# DNS Caching Layers

- DNS caching exists at multiple levels:

    - Browser cache

    - OS cache

    - Local DNS resolver

    - Recursive resolver

    - CDN / Load balancer

- TTL applies at each layer.