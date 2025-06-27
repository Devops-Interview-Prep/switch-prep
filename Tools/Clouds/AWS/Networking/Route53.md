- AWS Route 53 is a scalable and highly available Domain Name System (DNS) web service provided by Amazon Web Services.
- Hosted Zone:
  - Container for DNS records for a domain
- Record Set:
  - A DNS record (A, AAAA, CNAME, MX, TXT, etc.)
- TTL (Time to Live):
  - How long DNS servers cache the record
- Alias Record:
  - AWS-specific feature to map domain to AWS resources (e.g., CloudFront, ELB)

# Main Functions of Route 53:

- You can buy a domain like example.com directly from Route 53.
- It translates friendly domain names (e.g., www.example.com) into IP addresses (e.g., 192.0.2.1), so browsers can locate your server.
- You can configure Route 53 to monitor your application and automatically fail over to a healthy endpoint if one becomes unhealthy.
- You can route traffic using:
  - Simple routing
  - Weighted routing
  - Latency-based routing
  - Failover routing
  - Geolocation/geoproximity routing
  - Multi-value answer routing
- Route 53 works well with EC2, S3, CloudFront, API Gateway, and more.

#  Buy Domain from Route 53

- Steps:
  - Go to AWS Console > Route 53 > Domains > Registered Domains
  - Click Register Domain
  - Search for your desired domain (e.g., mycoolproject.com)
  - Choose a domain and continue
  - Fill out your contact info
  - Complete the purchase
-  AWS will automatically create a hosted zone for DNS management when the domain is registered.

# Buy Domain from Another Registrar (e.g., GoDaddy, Namecheap)

- Configure it to use Route 53 for DNS:
  - Create a hosted zone in Route 53 for your domain (e.g., example.com)
  - AWS will give you 4 NS (Name Server) records
  - Go to your domain registrar's dashboard
  - Update your domain's Name Server records to use Route 53's NS records
- Now Route 53 manages DNS, even though the domain was purchased elsewhere.