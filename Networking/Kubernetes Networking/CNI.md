# CNI (Container Network Interface)

- CNI is a specification + plugins that:
    - Create network interfaces for Pods
    - Create network namespace
    - Assign IPs
    - Connect Pod to Node network
    - Configure routing
    - Enforce Network Policies
    - Handle pod-to-pod traffic
    - (Sometimes) NAT traffic

- Kubernetes itself does not implement networking — CNI does.

🔹 Common CNI Plugins

| CNI         | How it works            |
| ----------- | ----------------------- |
| AWS VPC CNI | Pods get VPC IPs        |
| Calico      | Routing + NetworkPolicy |
| Cilium      | eBPF-based              |
| Flannel     | Overlay network         |


🔹 Example: AWS VPC CNI

- Pod gets an IP from VPC CIDR
- ENIs attached to nodes
- Pods are first-class VPC citizens

- Pros:
    - Native AWS networking
    - Security Groups for Pods (with extensions)

- Cons
    - IP exhaustion
    - AWS-specific

# What Actually Happens When a Pod Starts (CNI Lifecycle)

- kubelet calls CNI plugin ADD POD
- CNI does:
    - Creates veth pair
    - One end → pod namespace
    - One end → node bridge / eBPF
    - Assigns Pod IP
    - Adds routes
- Pod becomes reachable

# Types of CNI (How They Work Internally)

🔹 Overlay CNIs (Flannel, VXLAN)
    - Pod IP ≠ VPC IP
    - Traffic encapsulated
    - Pod → VXLAN → Node → VXLAN → Pod



# ENI (Elastic Network Interface)

- A virtual network card attached to an EC2 instance.
- Each ENI has:
    - 1 primary private IP
    - Multiple secondary private IPs
    - Security groups
    - A MAC address

```
EC2 Instance
 ├── eth0 (ENI-0)
 │    ├── Primary IP: 10.0.1.10
 │    ├── Secondary IP: 10.0.1.11
 │    ├── Secondary IP: 10.0.1.12
 │    └── ...
 ├── eth1 (ENI-1)
 └── eth2 (ENI-2)
```

- In AWS VPC CNI:
    - Pods get VPC IPs
    - Those IPs come from ENI secondary IPs
    - Pods are directly routable inside VPC

| Instance Type | Max ENIs |
| ------------- | -------- |
| t3.small      | 2        |
| t3.large      | 3        |
| m5.large      | 3        |
| c5.4xlarge    | 8        |


| Instance Type | IPs per ENI |
| ------------- | ----------- |
| t3.small      | 4           |
| t3.large      | 12          |
| m5.large      | 10          |
| c5.4xlarge    | 30          |

- EKS maxPods formula (important)
    - maxPods = (ENIs × (IPs per ENI − 1)) + 2
    - Why AWS adds “+2” (intuition)
        - AWS keeps buffer IPs for:
            - kube-system pods
            - networking stability
        - Prevents hard IP starvation
        - Safer scaling behavior

- Primary vs Secondary IPs
    - Primary IP

        - Used by the EC2 node itself

        - Node communication

        - kubelet, SSH, system traffic

    - Secondary IPs

        - Used by Pods

        - Attached dynamically

        - Recycled when Pods die

# How AWS VPC CNI Assigns Pod IPs

1️⃣ Node starts

- Node has:

    - 1 ENI

    - 1 primary IP

2️⃣ aws-node starts

- Queries:

    - Instance type limits

    - Max ENIs

    - Max IPs per ENI

- Example (t3.large):
```
Max ENIs: 3
IPs per ENI: 12
Total Pod IPs ≈ 36
```

3️⃣ IP pool creation

- ipamd:
    - Attaches additional ENIs
    - Assigns secondary IPs
    - Maintains a warm pool

    ```
    eth0 → 10 secondary IPs
    eth1 → 10 secondary IPs
    ```

4️⃣ Pod creation
- When a Pod is scheduled:
    - kubelet asks CNI for networking
    - CNI:
        - Picks a free secondary IP
        - Creates veth pair
        - Assigns IP to Pod
        - Programs routing



**Using Secondary IPs Explicitly (Advanced)**

| Variable            | Purpose                      |
| ------------------- | ---------------------------- |
| `WARM_IP_TARGET`    | Keep X free IPs              |
| `WARM_ENI_TARGET`   | Keep ENIs pre-attached       |
| `MINIMUM_IP_TARGET` | Minimum IPs always available |


| CNI         | Pod IP Source |
| ----------- | ------------- |
| AWS VPC CNI | VPC subnet    |
| Calico      | Pod CIDR      |
| Flannel     | Pod CIDR      |
| Cilium      | Pod CIDR      |


