
In AWS, load balancers are services that distribute incoming traffic across multiple targets (like EC2 instances, containers, or IP addresses) to ensure high availability, fault tolerance, and scalability. AWS offers Elastic Load Balancing (ELB) as a managed service for this purpose.

# How Load Balancing Works in AWS

- Client sends request to load balancer's DNS name.

- Load balancer checks health of targets.

- It chooses a healthy target using a routing algorithm (round-robin, least connections, etc.).

- Routes traffic to the selected target.

- Load balancer monitors target health and scales automatically if needed.

# Types of Load Balancers in AWS

**1. Application Load Balancer (ALB):**   
- Layer: Operates at Layer 7 (Application layer)
- Use case: Best suited for HTTP/HTTPS traffic

  - Key Features:
    - URL-based routing (e.g., /api/* → service A, /admin/* → service B)

    - Host-based routing (e.g., api.example.com vs admin.example.com)

    - Native support for WebSocket

    - Integration with AWS WAF for security

    - Supports container-based applications (e.g., ECS with dynamic ports)

**2. Network Load Balancer (NLB):**

- Layer: Operates at Layer 4 (Transport layer)
- 
- Use case: Ideal for high-performance TCP/UDP traffic

 - Key Features:

    - Handles millions of requests per second with low latency

    - Supports static IPs or Elastic IPs

    - Preserves source IP address means the backend pod/service receives the actual IP address of the client that made the request — not the IP of the load balancer or proxy.

    - Good for non-HTTP protocols or when extremely high performance is required

**3. Gateway Load Balancer (GWLB)**

- Layer: Operates at Layer 3 (Network layer)
  
- Use case: For deploying third-party virtual appliances like firewalls, IDS/IPS, etc.

 - Key Features:

    - Transparent traffic forwarding using GENEVE protocol

    - Designed for security appliance deployments

    - Integrates with VPC Endpoints (PrivateLink)


# Architectures using Load Balancers in k8s for external Traffic

**1. DNS + Ngnix Controller(NodePort IP):**

- Your subents should be public and the nodes should have public ips

- Will deploy a ngnix controller with nodeport ip service 

- In dns we will put public ip of all the nodes and will apply routing policy that will do a l4 routing to controller pods
 
- Later the traffic will come to controller and the L7 load balancing will happen

- *Cons:*
  - No Active Health Checking:

    - Route 53 does not natively know if a node is up or if the NodePort is reachable — unless you configure Route 53 health checks, which adds complexity and cost.

  - Uneven Load Distribution:
    - DNS-based load balancing isn’t very accurate.
    - Clients often cache DNS responses or prefer one IP.
    - This leads to uneven load across nodes (especially with mobile clients or CDNs).

  - No Connection Draining or Session Stickiness:
    - If a node is being taken down, clients may still hit it (unless DNS TTLs are super low).

  - No Security Controls:

    - Without a cloud LB (NLB/ALB), you don’t get IP whitelisting, WAF, etc., at the edge.

- *Can Be Used When:*
  - Bare metal/on-prem cluster
  - Lab/demo/test environments
  - You manage your own edge LB
  - You implement Route 53 health checks per node IP

**2. DNS + NLB + Ngnix Controller(LoadBalancer IP):**

- subnets can be public or private, to expose traffic we will use internet facing nlb

- Create a ingress controller with Loadbalancer IP, that will create a nlb according to your configuration and will assing an external ip as the nlb loadbalancer url

- Traffic will come through the dns to nlb and there we will define Target groups to distribute the traffic further to ngnix pods and the rest will be taken care by the controller 

- *Cons:*

  - You lose AWS-native protections unless you put another WAF in front.

  - If you deploy multiple NGINX controllers behind NLB, failover is tied to NLB health checks, not as dynamic as ALB target groups.

- *Pros*

  - You get support for protocols like gRPC, WebSockets (NLB handles L4 passthrough well)

  - Cost-sensitive and avoids multiple ALBs

  - Protocols Supported by AWS NLB:
    - TCP, UDP, TLS, gRPC, websockets, QUIC, HTTP/HTTPS

**3. DNS + ALB + Load Balancer Controller(LoadBalancer IP):**

- You define an Ingress resource (e.g., with annotations for TLS, routing, etc.).

- The AWS Load Balancer Controller detects it and automatically provisions an ALB.

- The ALB:
    - Handles TLS termination (via ACM if specified).
    - Performs host/path-based routing.
    - Forwards requests to target groups containing your Kubernetes pods (via NodePort or IP mode).

- The controller is an internal component; it’s not exposed to the internet.

- By default, 1 ALB per Ingress. Can be costly in large environments (workarounds exist via alb.ingress.kubernetes.io/group.name).

- Only supports HTTP/HTTPS (L7). Cannot use for gRPC without TLS or any non-HTTP protocols.

- Can't manipulate headers or do rewrites like NGINX can.

- No full WebSocket support without HTTPS

- gRPC only works properly over HTTPS.


