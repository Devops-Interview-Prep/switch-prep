- AWS Shield is a managed DDoS protection service from AWS.
It protects your web applications and infrastructure from Distributed Denial of Service (DDoS) attacks.

- Think of AWS Shield as a security wall that blocks large-scale internet attacks trying to take down your website or service by overwhelming it with traffic.

# What is a DDoS Attack?

- A DDoS (Distributed Denial of Service) attack is when attackers flood your application with a massive number of fake requests to crash it or make it unavailable to real users.

# AWS Shield Has Two Tiers:

1. AWS Shield Standard (✅ Free by default)
Automatically active for all AWS customers

Protects against common & most frequent DDoS attacks

No setup needed

Protects services like:

CloudFront

Route 53

Elastic Load Balancing (ALB/NLB)

Global Accelerator

2. AWS Shield Advanced (💵 Paid, for enterprises)
Adds enhanced protection against larger/more sophisticated attacks

Includes:

24/7 DDoS response team (DRT)

Real-time metrics and alerts

WAF integration

Application layer (L7) attack protection

Cost protection: AWS credits you for scaling charges from attacks

# How Does It Work?
You host a site (e.g., via CloudFront, ALB, or API Gateway).

If a DDoS attack starts:

Shield Standard automatically blocks common floods (e.g., SYN floods, UDP floods).

Shield Advanced analyzes traffic, gives deeper visibility, and engages AWS support if needed.

Your application stays available and stable, even during the attack.