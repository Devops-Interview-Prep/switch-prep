# CNI — Container Network Interface

> CNI is a specification + set of plugins that handle all networking for Kubernetes pods. Kubernetes itself does not implement networking — it delegates everything to the CNI plugin. CNI creates network namespaces, assigns IPs, configures routes, and enforces network policies.

---

## What CNI Does

```
When a pod starts, kubelet calls the CNI plugin to:
  1. Create a network namespace for the pod
  2. Create a virtual ethernet (veth) pair
  3. Assign an IP address to the pod
  4. Connect the pod to the node network
  5. Configure routes (so other pods/nodes can reach it)
  6. Enforce Network Policies (depending on CNI)
  7. Handle NAT for egress traffic (depending on CNI)
  8. Handle pod-to-pod traffic across nodes
```

---

## Common CNI Plugins — Comparison

| CNI | How It Works | Network Policy | Use Case |
|-----|-------------|----------------|----------|
| **AWS VPC CNI** | Pods get real VPC IPs from ENIs | Via Calico add-on | EKS — native AWS networking |
| **Calico** | BGP routing + iptables/eBPF | Yes (built-in) | Multi-cloud, policy-heavy |
| **Cilium** | eBPF-based, bypass iptables | Yes (built-in) | High-performance, observability |
| **Flannel** | Overlay network (VXLAN) | No (needs Calico) | Simple clusters, learning |
| **Weave** | Overlay mesh | Yes | Self-healing, easy setup |

---

## AWS VPC CNI — Deep Dive

```
With AWS VPC CNI:
  - Pods get IP addresses from the VPC subnet CIDR
  - IPs come from ENI secondary IPs (not a separate pod CIDR)
  - Pods are first-class VPC citizens — directly routable in the VPC

Pros:
  - Native AWS networking — no overlay overhead
  - Security Groups for Pods (with extensions)
  - Works with VPC flow logs, peering, Direct Connect

Cons:
  - IP exhaustion — each pod uses a real VPC IP
  - AWS-specific — not portable to other clouds
  - Node IP limit depends on instance type (max ENIs × IPs per ENI)
```

---

## ENI — Elastic Network Interface

```
An ENI is a virtual network card attached to an EC2 instance.
Each ENI has:
  - 1 primary private IP (used by the node itself)
  - Multiple secondary private IPs (used by pods)
  - Associated security groups
  - A MAC address
```

```
EC2 Instance
 ├── eth0 (ENI-0)
 │    ├── Primary IP: 10.0.1.10       ← node uses this
 │    ├── Secondary IP: 10.0.1.11     ← pod 1
 │    ├── Secondary IP: 10.0.1.12     ← pod 2
 │    └── ...
 ├── eth1 (ENI-1)
 └── eth2 (ENI-2)
```

### ENI Limits by Instance Type

| Instance Type | Max ENIs | IPs per ENI | Max Pods (approx) |
|---------------|----------|-------------|-------------------|
| t3.small | 2 | 4 | 8 |
| t3.large | 3 | 12 | 35 |
| m5.large | 3 | 10 | 29 |
| c5.4xlarge | 8 | 30 | 234 |

```
EKS maxPods formula:
  maxPods = (ENIs × (IPs per ENI − 1)) + 2

Why subtract 1 per ENI?
  The primary IP on each ENI is reserved for the node itself.

Why add 2?
  AWS reserves buffer IPs for kube-system pods and networking stability.
  e.g., for t3.large: (3 × (12−1)) + 2 = 33 + 2 = 35 max pods
```

---

## CNI Lifecycle — What Happens When a Pod Starts

```
1. kubelet calls CNI plugin ADD for the new pod

2. CNI plugin executes:
   a. Creates a veth pair (virtual ethernet cable):
        - One end goes into the pod's network namespace (pod side)
        - One end stays on the node (node side)
   b. In the pod namespace:
        - Assigns pod IP
        - Sets up lo (loopback)
        - Configures default route
   c. On the node:
        - Connects node-side veth to bridge/eBPF
        - Programs routing rules

3. Pod becomes reachable by IP from other pods/nodes

When pod terminates:
  - kubelet calls CNI DEL
  - CNI removes routes, veth pair, releases IP
```

---

## Overlay vs Underlay CNI — How They Differ

```
Overlay CNIs (e.g., Flannel VXLAN):
  - Pod IP ≠ VPC/underlay network IP
  - Traffic is encapsulated: pod frame → VXLAN header → UDP → node IP
  - Simpler to deploy (no underlay changes needed)
  - Overhead from encapsulation (~10-30% throughput reduction)

Underlay CNIs (e.g., AWS VPC CNI, Calico with BGP):
  - Pod IP = routable directly in the underlying network
  - No encapsulation overhead
  - Better performance and visibility (VPC flow logs see pod IPs)
  - Requires network to understand pod IP ranges
```

---

## ENI IP Warm Pool — Advanced Configuration

| Variable | Purpose |
|----------|---------|
| `WARM_IP_TARGET` | Keep X free secondary IPs pre-allocated |
| `WARM_ENI_TARGET` | Keep N ENIs pre-attached (ready for pods) |
| `MINIMUM_IP_TARGET` | Minimum IPs always available (floor) |

---

## Interview Q&A

**Q: What is the difference between an overlay CNI (Flannel) and an underlay CNI (AWS VPC CNI)?**
Flannel creates an overlay network — pods get IPs from a separate pod CIDR (e.g., 10.244.0.0/16), and traffic between nodes is encapsulated in VXLAN tunnels. The underlying network only sees node-to-node UDP traffic, not individual pod IPs. AWS VPC CNI is an underlay CNI — pods get real VPC subnet IPs from ENI secondary IPs. Traffic from pod to pod goes directly through the VPC routing fabric without encapsulation, making it faster and giving visibility at the VPC level (flow logs, security groups per pod). Trade-off: VPC CNI uses real VPC IPs (can exhaust subnet space), while overlay CNIs use a separate pod CIDR that doesn't consume VPC IPs.

**Q: What determines how many pods can run on an EKS node?**
The max pods per node is determined by the AWS VPC CNI limits: `(maxENIs × (IPsPerENI - 1)) + 2`. This is because each pod needs a secondary IP from an ENI, and the primary IP on each ENI is reserved for the node. Instance types with more ENIs and more IPs per ENI support more pods. For example, a `t3.small` (2 ENIs, 4 IPs each) supports at most `(2 × 3) + 2 = 8` pods. This is a hard limit — you cannot schedule more pods than available secondary IPs. Solutions for IP exhaustion include: using larger instance types, enabling VPC CNI IP prefix delegation (allocates /28 prefixes per ENI = 16 IPs each), or switching to Cilium with a custom CIDR.

**Q: Why does Kubernetes not implement networking itself?**
Kubernetes follows the CNI specification and delegates all pod networking to a plugin. This design decision keeps Kubernetes portable — the same cluster can use AWS VPC CNI in EKS, Calico in an on-prem cluster, and Cilium in GKE, all with the same Kubernetes API. Each environment has different networking primitives (VPC ENIs, BGP routes, eBPF maps), and CNI plugins implement those specifics. Without this abstraction, Kubernetes would need to know about AWS, GCP, Azure, bare metal, and every possible network topology — making it impossible to maintain.
