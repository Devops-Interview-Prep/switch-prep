---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: ${client_name}-general
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: ${ami_alias}
  role: ${node_role_name}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${cluster_name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${cluster_name}
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 1
    httpTokens: required
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 100Gi
        volumeType: gp3
        deleteOnTermination: true
        encrypted: true
  tags:
    Environment: ${client_name}
    karpenter.sh/discovery: ${cluster_name}
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: ${client_name}-devops-infra
spec:
  amiFamily: AL2023
  amiSelectorTerms:
    - alias: ${ami_alias}
  role: ${node_role_name}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${cluster_name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${cluster_name}
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 1
    httpTokens: required
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 50Gi
        volumeType: gp3
        deleteOnTermination: true
        encrypted: true
  tags:
    Environment: ${client_name}
    karpenter.sh/discovery: ${cluster_name}
    NodeType: devops-infra