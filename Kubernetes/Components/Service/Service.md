
- In Kubernetes, a Service is an abstraction that defines a logical set of Pods and a policy by which to access them. It enables network communication to Pods in a consistent and reliable way — even if the underlying Pods change (due to rescheduling, scaling, etc.).

- Expose an application running in your cluster behind a single outward-facing endpoint, even when the workload is split across multiple backends.

- Group Pods by a label selector.

- Pods can discover and talk to Services using these DNS names.    
  Ex. `http://my-service.my-namespace.svc.cluster.local`

- For ClusterIP and NodePort, kube-proxy sets up iptables or IPVS rules to route traffic to the correct Pod IPs.

- For loadbalncer service, the traffic comes to loadbalncer according to that traffic goes to the target group nodes on particular nodeport according to the policy defined at lb level, from where the kube-proxy take over and distributes the traffic on pods on that particular node.

- externalTrafficPolicy: Cluster
  - Any Kubernetes node can accept traffic on the NodePort and then forward it internally to a Pod running anywhere in the cluster.

  - So even if the Pod isn’t on that node, the traffic is still forwarded internally using Kubernetes networking.

  - Thats what exactly happens in the case of ingress controller, nlb/alb will have all the nodes as target group but the nodeport is the port where ingress controller is exposed, so if the request lands on any node works and all the target groups visibly healthy

**Types of Service**

*1. ClusterIP*

- Exposes the Service on a cluster-internal IP. 
  
- Choosing this value makes the Service only reachable from within the cluster. 
  
- This is the default that is used if you don't explicitly specify a type for a Service.

-  You can expose the Service to the public internet using an Ingress or a Gateway.
   

*2. NodePort*

- Exposes the Service on each Node's IP at a static port (the NodePort). 
  
- To make the node port available, Kubernetes sets up a cluster IP address, the same as if you had requested a Service of type: ClusterIP.

- Allocates a port on each Node (between 30000–32767) and forwards traffic to the Service.

*3. LoadBalancer*

- Exposes the Service externally using an external load balancer. 
  
- Kubernetes does not directly offer a load balancing component; you must provide one, or you can integrate your Kubernetes cluster with a cloud provider.

*4. ExternalName*

- Maps the Service to the contents of the externalName field (for example, to the hostname api.foo.bar.example). 
  
- The mapping configures your cluster's DNS server to return a CNAME record with that external hostname value. No proxying of any kind is set up.

- Inside your cluster, a DNS request for: external-db.my-namespace.svc.cluster.local Will resolve to: db.example.com and traffic will go directly to db.example.com (bypassing Kubernetes proxying, kube-proxy, etc.)

- Usecases:
  
  - Unified DNS for Apps:
  
    - No app-level awareness that this is external.
  
    -  If later you migrate the DB into the cluster  you just change the Service type. No code changes.
  
 -  Central Configuration:
  
    -  Imagine you have 10 microservices accessing an external payment gateway (payments.acme.com).
  
    -  Without ExternalName: all services must be configured with that external hostname.
  
    -  With ExternalName: services just use payments-service.default.svc.cluster.local
  
    -  If the vendor changes DNS name, you only change one YAML.
  
    -   Better separation of infra and app logic.

*5. Headless*

- A Headless Service is a service without a cluster IP.

- Instead of load-balancing, it directly returns the IPs of the matching pods, allowing the client to connect to them directly.

- We can use it for StatefulSets (like databases, Kafka, etc.) and to do DNS-based service discovery

```
kind: StatefulSet
metadata:
  name: redis
spec:
  serviceName: redis-headless
  replicas: 3
```

The DNS names become:

```
redis-0.redis-headless.default.svc.cluster.local
redis-1.redis-headless.default.svc.cluster.local
redis-2.redis-headless.default.svc.cluster.local
```
