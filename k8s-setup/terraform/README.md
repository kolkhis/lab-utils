# Terraform Config for K8s

This is a Terraform configuration for provisioning VMs to use in a Kubernetes
cluster.  

Default setup is 5 VMs total:

- 1 control node
- 2 worker nodes
- 2 load balancer nodes

Each node is provisioned with the resources defined in the `locals` block
within [`main.tf`](./main.tf).  


