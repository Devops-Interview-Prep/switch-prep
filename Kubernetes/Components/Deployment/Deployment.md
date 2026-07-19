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

---

## Full Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-server
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # at most 1 extra pod above desired during update
      maxUnavailable: 0    # never drop below desired count (zero downtime)
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
        - name: api
          image: my-registry/api:v1.2.3
          ports:
            - containerPort: 8080
          env:
            - name: DB_URL
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: url
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          startupProbe:
            httpGet:
              path: /healthz
              port: 8080
            failureThreshold: 30    # 30 * 10s = 5 min for slow startup
            periodSeconds: 10
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values: [api-server]
                topologyKey: kubernetes.io/hostname  # spread across nodes
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: api-server
```

## Rolling Update Mechanics

```
Before update (3 replicas, maxSurge=1, maxUnavailable=0):
  [v1] [v1] [v1]   total=3

Step 1 — add 1 new pod (surge):
  [v1] [v1] [v1] [v2]   total=4

Step 2 — remove 1 old pod:
  [v1] [v1] [v2]   total=3

Step 3 — add another new pod:
  [v1] [v1] [v2] [v2]   total=4

Step 4 — remove old pod, and so on...
  [v2] [v2] [v2]   total=3 ✅
```

## Essential Rollout Commands

```bash
# Watch rollout progress
kubectl rollout status deployment/api-server

# View rollout history (requires --record flag on apply, or use annotations)
kubectl rollout history deployment/api-server

# Rollback to previous version
kubectl rollout undo deployment/api-server

# Rollback to specific revision
kubectl rollout undo deployment/api-server --to-revision=3

# Pause rollout mid-update (for investigation)
kubectl rollout pause deployment/api-server

# Resume paused rollout
kubectl rollout resume deployment/api-server

# Scale immediately
kubectl scale deployment/api-server --replicas=5

# Force redeploy with same image (e.g., updated ConfigMap)
kubectl rollout restart deployment/api-server
```

## Taints & Tolerations Example

```yaml
# Taint a node for GPU workloads
# kubectl taint nodes gpu-node-1 nvidia.com/gpu=true:NoSchedule

# Pod toleration to schedule on that node
spec:
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
  nodeSelector:
    nvidia.com/gpu: "true"   # also constrain to GPU nodes
```

## Common Interview Questions

**Q: maxSurge vs maxUnavailable — which to tune for zero-downtime?**
`maxUnavailable: 0` ensures no pod goes down before a replacement is ready → zero downtime. `maxSurge: 1` allows one extra pod during rollout (needs headroom for +1 pod). For critical services: `maxSurge=1, maxUnavailable=0`. For fast rollouts where brief capacity dip is acceptable: `maxSurge=0, maxUnavailable=1` (uses no extra capacity but serves with one fewer pod during update).

**Q: Liveness vs Readiness vs Startup probes?**
Liveness: "is the container healthy?" — if it fails, kubelet restarts the container. Use for detecting deadlocks. Readiness: "is the container ready to serve traffic?" — if it fails, pod is removed from Service endpoints (no new traffic), but NOT restarted. Use for graceful startup and temporary overload. Startup: "has the container finished starting?" — blocks liveness/readiness checks during slow startup to prevent premature restarts. Set `failureThreshold × periodSeconds` to your max startup time.

**Q: How do you spread pods across availability zones?**
Use `topologySpreadConstraints` with `topologyKey: topology.kubernetes.io/zone` and `maxSkew: 1`. This limits the difference in pod count between any two AZs to 1. More flexible than `podAntiAffinity` (which only prevents co-location, doesn't ensure even spread). Set `whenUnsatisfiable: DoNotSchedule` for hard constraint, or `ScheduleAnyway` for soft (schedule even if imbalanced).
