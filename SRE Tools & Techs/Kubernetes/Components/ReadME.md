# Components
1. **Pod**
    - The smallest deployable unit.
    - Contains one or more containers that share storage and networking.
    - Each pod gets its own ip & a new ip on recreation
2. **Deployment**
    - Manages the rollout of new application versions.
    - Ensures a specified number of pod replicas run at all times.
    - Deployment manages a Replicaset & Replicaset manages the pod replicas
    -  It provides declarative updates for applications and ensures that the desired state is maintained automatically.
    -  **Key Features of Deployments**
       -  *Replica Management* – Ensures a specified number of Pod replicas are running.
       -  *Rolling Updates* – Supports zero-downtime application updates.
       -  *Rollback* – Allows reverting to a previous version if the update fails.
       -   *Scaling* – Easily scale applications up or down.
       -   *Self-Healing* – Restarts failed Pods automatically.
   - **Deployment Structure**
       - *Metadata* – Name, labels, and other identifying information.
       - *Pod Template* – Defines the container(s) to run, along with configurations.
       - *ReplicaSet* – Ensures the desired number of Pods are running.
       - *Selector* – Identifies which Pods are managed by this Deployment.
       - *Update Strategy* – Defines how updates are applied. 
   - **Deployment Strategies**
     - *Rolling Update (Default)*
       - Updates Pods one by one to ensure zero downtime.
       - New Pods are created while old Pods are terminated.
       - Controlled by maxSurge and maxUnavailable.
     - *Recreate Strategy*
       - Deletes all existing Pods first before creating new ones.
       - Causes downtime.
   - **Rolling Back a Deployment**
     - If a new Deployment version causes issues, you can rollback to a previous working version.
     - Check Deployment History
       - `kubectl rollout history deployment my-app`
     - Rollback to Previous Version
       - `kubectl rollout undo deployment my-app`
   - **Affinity & Anti-affinity**
     - *Node Affinity*
       - Ensures Pods are scheduled on specific nodes based on node labels.
       - *Node Affinity Types*
         - requiredDuringSchedulingIgnoredDuringExecution
           - Mandatory rule. Pod will not schedule if conditions are not met.
         - preferredDuringSchedulingIgnoredDuringExecution
           - Soft rule. Scheduler will try to place Pods accordingly but will still run them if constraints aren’t met.
     - *Pod Affinity (Pods are scheduled together)*
       - Ensures Pods are scheduled on the same nodes as other Pods based on labels.
     - *Pod Anti-affinity (Pods are scheduled apart)*
       - Prevents certain Pods from running on the same node.
   - **Taints & Tolerations**
     - Taints and tolerations prevent Pods from being scheduled on specific nodes unless explicitly allowed.
     - *Taint a Node (Prevent Scheduling)*
       - Taints repel Pods from running on a node unless they tolerate the taint.
     - `kubectl taint nodes node1 key=value:NoSchedule`
       - NoSchedule → No Pod can be scheduled unless it has a toleration.
     - *Toleration (Allow Scheduling on Tainted Nodes)*
       - Pods must have a toleration to be scheduled on a tainted node.
   - **Probes (Health Checks)**
     - *Liveness Probe (Restart on Failure)*
       -  Restarts a Pod if it becomes unresponsive.
       -  Checks if the container is still running. Restarts the Pod if it fails.
    - *Readiness Probe (Traffic Control)*
      - Ensures the Pod is ready before receiving traffic.
    - *Startup Probe (Slow Apps)*
      - Allows slow-starting apps to initialize without being restarted.
      - Application starts up slowly → Probe keeps retrying.
      - Once /startup responds with 200 OK, the probe passes.
   - **nodeSelector**
     - nodeSelector is a simple way to tell Kubernetes which nodes a Pod should run on. It selects nodes based on key-value labels.
     -  If no node has that label, the Pod stays pending.

3. **StatefulSet**
    - Used for stateful applications (e.g., databases).
    - Ensures stable pod identities and persistent storage.
4. **DaemonSet**
    - Runs a copy of a pod on every node (or a subset of nodes).
    - Common for monitoring/logging agents like Fluent Bit, Prometheus Node Exporter.
5. **Job & CronJob**
    - Job: Runs a task to completion (e.g., data processing).
    - CronJob: Schedules jobs at specified intervals.
    - cron job creates a job and job creates pods 
6. **ConfigMap & Secret**
    - ConfigMap: Stores non-sensitive configuration data.
    - Secret: Stores sensitive data like API keys and credentials.
7. **Service**
    - Exposes pods within or outside the cluster.
    - Types:
        - ClusterIP (default): Internal communication.
        - NodePort: Exposes service on a static port on each node.
        - LoadBalancer: Uses cloud provider’s load balancer.
        - ExternalName: Maps a service to an external DNS.
8. **Ingress**
    - Manages HTTP/HTTPS traffic.
    - Routes requests to services based on rules.
9. **Persistent Volume (PV) & Persistent Volume Claim (PVC)**
    - PV: Cluster-wide storage resource.
    - PVC: Pod’s request for storage.
10. **Storage Class**
    - jj
11. **Network Policy**
    - Defines rules for pod-to-pod or pod-to-external communication.
    - Used to enforce security policies.
12. **HPA**
    - Adjusts the number of pod replicas based on CPU/memory utilization.
13. **VPA**
    - Adjusts CPU/memory requests for pods dynamically.
14. **Cluster Autoscaler**
    - Scales the number of worker nodes based on resource demands.