- Amazon CloudFront is a Content Delivery Network (CDN) service offered by AWS.
It delivers web content (HTML, CSS, JS, images, videos, APIs, etc.) quickly and securely to users around the world by caching it closer to them.

# Key Components of CloudFront

1. Origin:
   - The backend where your content is stored. Can be:
     - S3 Bucket
     - EC2 instance
     - Application Load Balancer
     - Any HTTP server (even outside AWS)

2. Edge Locations:
   - Global CDN servers that cache your content to reduce latency.

3. Distribution:
   - A configuration that tells CloudFront how to serve your content. 
   - You create a distribution and specify the origin and settings.

4. Cache Behavior:
   - Rules that control how CloudFront responds to requests (e.g., cache path /images/*, forward headers, TTL).

5. Invalidation:
   - Used to remove or refresh cached content from edge locations before the TTL expires.

6. Signed URLs/Cookies:
   - Used for restricting access to private content.

7. Viewer Protocol Policy:
   - Forces HTTP or HTTPS, or allows both.

8. Origin Access Control (OAC) or Origin Access Identity (OAI):
   - Mechanisms to securely restrict S3 access only to CloudFront.

# How CloudFront Works (Simplified Flow):

- User makes a request (e.g., https://cdn.example.com/image.jpg)
- CloudFront checks the nearest edge location.
- If cached, it serves the file immediately (low latency ✅).
- If not cached (cache miss), it fetches it from the origin, caches it at the edge, and returns it to the user.
- Future requests from nearby users are served from the cache.

# Types of Content Delivered

- Static: Images, CSS, JavaScript, fonts, videos
- Dynamic: API responses (with low TTL or no caching)
- Live/Streaming Media: HLS, MPEG-DASH
- Entire websites: Via S3 or custom origins


# Security Features

- HTTPS: Encrypts content in transit

- WAF integration: Protect against web exploits

- Geo-restriction: Block users from specific countries

- Signed URLs/Cookies: Restrict access to authorized users only

- Shielded origins: Protect backend from direct access

# Common Use Cases

Use Case	                                       Explanation
✅ Faster Website Load Times	                      Cache static content near users (e.g., images, scripts)
📽️ Video Streaming	                                Deliver videos via HLS/DASH
🌍 Global Distribution	                           Serve global audiences with low latency
🔒 Secure Content Delivery	                       Signed URLs for authorized access only
🛡️ API Acceleration + Security	                    Speed up APIs and protect them with AWS WAF
🧺 E-Commerce Sites	                               Cache product images, speed up delivery pages
☁️ Static Website Hosting	                        Host entire website using S3 + CloudFront


# S3 + CloudFront Static Website
Store your static website files in an S3 bucket.

Create a CloudFront distribution with the S3 bucket as the origin.

Restrict bucket access to only CloudFront using OAI/OAC.

Set custom domain (e.g., www.mysite.com) and attach an SSL cert via ACM.

Cache settings and behaviors for /index.html, /images/*, etc.

Deploy!

# Benefits of Using CloudFront
Global low latency & high transfer speeds

Scalable & integrates with all AWS services

Custom cache rules and content access control

Easy to use with custom domains and HTTPS

Reduces load on origin servers (less cost)