# Nginx as Webserver

- Serve static content (HTML, CSS, JS, images, etc.) and forward dynamic requests to backend apps (like PHP, Python, or Node.js apps).
- Listens on HTTP ports (usually 80 or 443 for HTTPS).
- When a request comes in (e.g., GET /index.html), Nginx serves the static file directly from disk.
- For dynamic requests, Nginx passes the request to an application server via FastCGI, uWSGI, or proxy_pass.

Example use case: Hosting a static website or acting as a frontend for a WordPress/PHP application.

# Reverse Proxy

- Nginx receives client requests and forwards them to backend servers, then returns the response to the client.
- Load balancing across multiple app servers.
- SSL termination (Nginx handles HTTPS, app servers get plain HTTP).
- Caching responses for performance.
- Hiding internal architecture from users.


- Nginx uses the proxy_pass directive to forward traffic.
```
server {
    listen 80;

    location / {
        proxy_pass http://backend_servers;
    }
}

upstream backend_servers {
    server app1.internal:8080;
    server app2.internal:8080;
}
```


#  Ingress Controller in Kubernetes

- Manage external access to services inside a Kubernetes cluster, using rules defined in Ingress
- The Nginx Ingress Controller is a Kubernetes Deployment running Nginx.
- It watches for changes to Ingress objects and configures Nginx accordingly.
- It routes HTTP/HTTPS traffic to services based on hostnames or paths.
- Central entry point to your services.
- TLS termination.
- Path-based and host-based routing.
- Rate limiting, rewrites, redirects, etc.


# Difference between a Reverse & Forward Proxies

**Reverse Proxy**
- Sits in front of web servers.
- Clients don’t know the backend servers; they only talk to the reverse proxy.
- Used by servers to serve clients better.
- Manages incoming traffic to a group of internal servers.

```
Client --> Reverse Proxy (Nginx) --> Backend Servers (e.g., app1, app2)
```

**Forward Proxy**
- Sits in front of clients.
- Servers don’t know the real client; they only see the proxy.
- Used by clients to access the internet or restricted servers.
- Manages outgoing traffic from users.
- Bypassing geo-blocks or censorship (VPN-style), Content filtering (corporate firewalls), Hiding client identity (anonymity)

```
Client --> Forward Proxy(VPN) --> Internet (websites)
```