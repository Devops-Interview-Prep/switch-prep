---
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default-on-demand
spec:
  weight: 10
  template:
    metadata:
      labels:
        node-type: default
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: ${client_name}-general
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["t", "m", "r", "c"]
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
---
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: ${client_name}-general-purpose
spec:
  weight: 20
  template:
    metadata:
      labels:
        node-type: general-purpose
    spec:
      expireAfter: 120h
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: ${client_name}-general
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["t", "m", "r", "c"]
  limits:
    cpu: "1000"
    memory: 1000Gi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
---
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: ${client_name}-devops-infra
spec:
  weight: 30
  template:
    metadata:
      labels:
        node-type: devops-infra
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: ${client_name}-devops-infra
      taints:
        - key: type
          value: ${client_name}-devops-infra
          effect: NoSchedule
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["t", "m", "r", "c"]
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s