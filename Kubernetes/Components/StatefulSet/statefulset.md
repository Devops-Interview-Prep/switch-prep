- A StatefulSet is a Kubernetes workload API object used to manage stateful applications. 
- Unlike Deployments (which are designed for stateless applications and treat their Pods as interchangeable), StatefulSets provide guarantees about the ordering and uniqueness of Pods. 
- This is crucial for applications that require a stable identity or persistent storage.

# Why StatefulSets? The Problem with Stateless Pods for Stateful Apps

- Imagine a database cluster (like PostgreSQL, Cassandra, or MongoDB) or a message queue (like Kafka). These applications:

  - Need stable network identities: 
    - Each node in the cluster might need a unique, persistent hostname (e.g., db-0, db-1, db-2) to find and communicate with its peers. 
    - If a Pod restarts, it needs to come back with the same identity.

  - Require persistent storage: 
    - The data must survive Pod restarts or rescheduling to different nodes. 
    - Each instance often needs its own dedicated, persistent storage volume.

  - Demand ordered deployment/scaling: 
    - For some distributed systems, the order in which nodes start or stop matters (e.g., a primary database node must be up before replicas, or specific nodes must shut down gracefully).

  - Unique identification: 
    - Each instance is not interchangeable; it holds a specific part of the distributed state or has a unique role.

- Traditional Deployments simply create interchangeable Pods. 
- If a Pod dies, a new one is created, often with a different name and IP, and its local storage is lost. 
- This is unacceptable for stateful applications. 
- StatefulSet solves these problems.

# Core Concepts 

**1. Stable, Unique Network Identifiers:**

- Each Pod in a StatefulSet is assigned a predictable name based on its StatefulSet name and an ordinal index (e.g., my-app-0, my-app-1, my-app-2).

- This identity is maintained even if the Pod is rescheduled to a different node.

- Headless Service: 
  - To enable stable network identities and peer discovery among StatefulSet Pods, you must create a Headless Service (a Service with clusterIP: None) that targets your StatefulSet. 
  - This service creates DNS entries for each Pod (e.g., my-app-0.my-headless-service.my-namespace.svc.cluster.local).

**2. Stable, Persistent Storage:**

  - StatefulSets typically use PersistentVolumeClaims (PVCs) to provision and manage dedicated PersistentVolumes (PVs) for each Pod.
  - You define volumeClaimTemplates within the StatefulSet specification. 
  - Kubernetes then automatically creates a PVC for each Pod (e.g., www-my-app-0, www-my-app-1).
  - When a Pod is restarted or rescheduled, its corresponding PVC ensures that it re-attaches to the same PV and thus to its original data.

- Important: 
  - Deleting a StatefulSet does not delete its associated PVCs or PVs. 
  - This is a safety mechanism to prevent accidental data loss. 
  - You must manually delete them after the StatefulSet is gone if you don't need the data.

**3. Ordered, Graceful Deployment and Scaling:**

  - Deployment: 
    - Pods are created sequentially, in ascending order of their ordinal index (0, then 1, then 2...). 
    - A Pod is only created after its predecessor is Running and Ready. 
    - This ensures that a primary node can initialize before replicas attempt to join.

  - Scaling Down: 
    - Pods are terminated in reverse ordinal order (N-1, then N-2...). 
    - A Pod is only terminated after all its successors have been completely shut down. 
    - This allows for graceful shutdown and data consistency.

  - Rolling Updates: 
    - StatefulSets support rolling updates, where Pods are updated in reverse ordinal order by default. 
    - This ensures that the application remains available during updates.

  *Scaling Down order? rolling update order ?*

**4. Pod Management Policy:**

  - OrderedReady (default): 
    - Enforces the strict ordering for creation and termination.

  - Parallel: 
    - Allows Pods to be created or terminated in parallel. 
    - Use this only if your application can handle parallel operations and doesn't rely on strict ordering during scale up/down.

*Example Applications*

#  Deploy a StatefulSet

- To deploy a StatefulSet, you'll typically need two main Kubernetes manifest files:
**1. A Headless Service Manifest:**
    - This service will manage the network identity of your StatefulSet's Pods.
**2. A StatefulSet Manifest:**
    - This defines the stateful application, its Pod template, and its storage requirements.
    - *storageClassName:*
      - This refers to a StorageClass object in your Kubernetes cluster.
      - which abstracts the underlying storage provisioner (e.g., AWS EBS, GCP Persistent Disk, Azure Disk, Rook-Ceph, Portworx). 
      - Ensure you have a StorageClass configured in your cluster. 
      - If omitted, the default StorageClass will be used.

---

## StatefulSet YAML — Full Example (PostgreSQL)

```yaml
# 1. Headless Service — stable DNS per Pod
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  labels:
    app: postgres
spec:
  clusterIP: None          # headless — no virtual IP
  selector:
    app: postgres
  ports:
    - name: postgres
      port: 5432
---
# 2. StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: "postgres-headless"    # must match headless service name
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "4Gi"
          readinessProbe:
            exec:
              command: ["pg_isready", "-U", "postgres"]
            initialDelaySeconds: 10
            periodSeconds: 5
  volumeClaimTemplates:               # creates PVC for EACH pod
    - metadata:
        name: postgres-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "gp3"
        resources:
          requests:
            storage: 20Gi
```

This creates: `postgres-0`, `postgres-1`, `postgres-2` each with their own PVC (`postgres-data-postgres-0`, `postgres-data-postgres-1`, `postgres-data-postgres-2`).

## DNS for StatefulSet Pods

```bash
# Pod DNS pattern:
# <pod-name>.<headless-service>.<namespace>.svc.cluster.local

postgres-0.postgres-headless.default.svc.cluster.local
postgres-1.postgres-headless.default.svc.cluster.local
postgres-2.postgres-headless.default.svc.cluster.local

# Use this for peer discovery in distributed systems
# Example: Kafka broker config points to:
# kafka-0.kafka-headless.kafka.svc.cluster.local:9092
# kafka-1.kafka-headless.kafka.svc.cluster.local:9092
```

## StatefulSet vs Deployment

| Feature | StatefulSet | Deployment |
|---------|------------|-----------|
| Pod identity | Stable (pod-0, pod-1...) | Random (pod-abc12, pod-def34) |
| Storage | Per-pod PVC (persistent) | Shared or ephemeral |
| Scaling | Ordered (0→1→2) | Parallel |
| Scale down | Reverse order (2→1→0) | Any pod deleted |
| DNS | Per-pod DNS via headless service | Service VIP (load balanced) |
| Use case | Databases, Kafka, Zookeeper | Stateless APIs, web servers |

## Update Strategies

```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 2    # only update pods with ordinal >= 2
                      # pods 0,1 keep old version (canary/staged rollout)
```

```bash
# Manual rollout (update one pod at a time)
kubectl rollout status statefulset/postgres

# Force pod recreation (useful if pod is stuck)
kubectl delete pod postgres-2

# Scale StatefulSet
kubectl scale statefulset postgres --replicas=5

# Pause rollout at partition=2 (rollout only pods >= 2)
kubectl patch statefulset postgres -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'
```

## Common Interview Questions

**Q: StatefulSet vs Deployment — when to use each?**
Use Deployment for stateless apps where any pod can serve any request (APIs, web servers). Use StatefulSet when each instance needs: (1) stable hostname (peer discovery in clusters like Kafka, Zookeeper, Cassandra), (2) dedicated persistent storage that survives pod restarts, (3) ordered startup/shutdown (primary must be up before replicas). If you just need persistent storage but not stable identity, a Deployment with a single PVC can work.

**Q: What happens to PVCs when you delete a StatefulSet?**
PVCs are NOT deleted — this is intentional to prevent data loss. You must manually delete them: `kubectl delete pvc -l app=postgres`. This is one of the most common operational gotchas: after deleting and recreating a StatefulSet (e.g., for a name change), the new pods re-attach to the old PVCs if they have the same name pattern.

**Q: What is the `partition` field in rolling updates?**
`partition: N` means only pods with ordinal index >= N get the new version. Pods 0 through N-1 keep the old version. Use for canary rollouts: set partition=2 on a 3-replica StatefulSet → only pod-2 updates. After validating, set partition=0 → pods 1 and 0 update. This gives fine-grained control that Deployments don't have.
