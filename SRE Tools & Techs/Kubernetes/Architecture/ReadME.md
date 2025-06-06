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

     


