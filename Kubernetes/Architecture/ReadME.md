- Orchestration tool to manage containers

# Nodes
1. **Master Nodes**
   -  All the managing processes on the cluster 
   -  Four Process run on this node
      1. **API Server**
         - Cluster gateway or Entrypoint 
         - Will get the requests from the client
         - Acts as a gatekeeper for authentication
      2. **Scheduler**
         - It checks where to schedule the new pod
         - Then sends the request to Kubelet
         - Kubelet schedules the new pod
      3. **Controller Manager**
         - Detects the changes in cluster state like pod died 
         - Then tries to recover the cluster state 
         - Controller -> Scheduler -> Kubelet
      4. **ETCD**
         - key value store or cluster brain
         - Cluster changes get stored in the key value store
         - It does not store the application data
         - Distributed storage across all the nodes

2. **Worker Nodes**
   - Worker nodes do the actual work
   - The workload is scheduled on these nodes
   - These 3 processes needs to be installed on every nodes
      1. **Container Runtime**
         - Any container runtime like docker 
      2. **Kubelet**
         - It is responsible for scheduling the pods after scheduler tells where to schedule
         - Starts the pod with container inside and assign resources to it 
      1. **Kube Proxy**
         - Forwards the request to the pod from the service 


# Mental Model (EKS)

- EKS control plane is logically inside your VPC, but physically managed and isolated by AWS.
   - Control plane ENIs are created in your VPC
   - Control plane runs in AWS-managed infrastructure
   - Worker nodes communicate privately with the control plane
   - You never see EC2 instances for master nodes

# Comparison: Self-Managed vs EKS

| Aspect          | Self-managed k8s   | EKS                 |
| --------------- | ------------------ | ------------------- |
| Master nodes    | EC2/VMs you manage | AWS-managed         |
| Master location | Same VPC           | Same VPC (ENIs)     |
| etcd            | You manage         | AWS-managed         |
| Upgrades        | Manual             | One-click           |
| Cost            | You pay EC2        | Included in EKS fee |


# How Do Worker Nodes Talk to Master Components?

- ALL communication to the control plane goes through the kube-apiserver
- No component (scheduler, etcd, controllers, kubelet) talks to each other directly without the API server.

```
Worker Node
  kubelet
    │
    │ HTTPS + TLS (443)
    ▼
kube-apiserver
```

| From        | To             | Protocol    |
| ----------- | -------------- | ----------- |
| kubelet     | kube-apiserver | HTTPS (TLS) |
| kube-proxy  | kube-apiserver | HTTPS       |
| controllers | kube-apiserver | HTTPS       |
| scheduler   | kube-apiserver | HTTPS       |
| etcd        | kube-apiserver | mTLS        |
| kubectl     | kube-apiserver | HTTPS       |


# Node Bootstrap: How a Worker Node Joins the Cluster

1. Node starts
   - EC2 boots
   - containerd starts
   - kubelet starts
2. kubelet authenticates
   - kubelet presents:
      - Client certificate (x509)
      - OR IAM identity (EKS)
3. kubelet registers itself
```
kind: Node
metadata:
  name: ip-10-0-1-23
```
4. API server validates
   - AuthN (cert / IAM)
   - AuthZ (RBAC)

     

**Continuous Communication (Heartbeat Loop)**

- kubelet → API Server
   - Every few seconds:
      - Node status
      - Pod status
      - Resource usage
   - If heartbeats stop:
      - NodeNotReady → Pod eviction


# ETCD

- etcd is a strongly consistent, distributed key-value store

