# AWX on Proxmox

AWX is the upstream project for Ansible Automation Platform (AAP), previously Ansible
Tower, from RedHat.  

It is free, open-source software that provides a web UI and REST API for 
managing Ansible across environments.

## Setup

AWX is typically run in a Kubernetes cluster using the AWX Operator.  
It can be deployed with Docker/Compose for labs or testing purposes, but in
production environments it is run on Kubernetes (k8s, OpenShift, k3s, etc.).

For simplicity, k3s can be used. Installation is simply running a single
script:
```bash
curl -fsSL https://get.k3s.io | sh -
```
Then verify:
```bash
kubectl --version
kubectl get nodes
```

