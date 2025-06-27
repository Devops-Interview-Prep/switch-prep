- AWS WAF (Web Application Firewall) is a security service that protects your web applications from common internet threats and malicious traffic.

- AWS WAF acts like a security guard for your website or API.
It checks incoming requests and blocks the bad ones (like hackers, bots, or known attack patterns), and lets good traffic through.

# What can AWS WAF protect?
It works with:

Amazon CloudFront (CDN)

Application Load Balancer (ALB)

Amazon API Gateway

AWS App Runner

# How It Works:

You create a Web ACL (Access Control List)

Add rules to allow, block, or count requests

Attach this Web ACL to your CloudFront, ALB, or API Gateway

WAF starts inspecting each request using your rules

