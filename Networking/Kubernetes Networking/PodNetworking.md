🔹 Pod IPs

- Each Pod gets a unique IP

- IP is assigned by the CNI plugin

- Pod IP is:

    - Ephemeral

    - Changes when Pod restarts

    - NOT stable

🔹 How Pods Communicate

```
Pod A (10.244.1.12)
  ↓
Node A
  ↓
Cluster Network
  ↓
Node B
  ↓
Pod B (10.244.2.34)
```

➡️ No NAT   
➡️ No port mapping      
➡️ Flat network

- This is very different from Docker bridge networking.