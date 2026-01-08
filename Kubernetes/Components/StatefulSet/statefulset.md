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