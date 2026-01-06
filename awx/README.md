# AWX on Proxmox

AWX is the upstream project for Ansible Automation Platform (AAP), previously Ansible
Tower, from RedHat.  

It is free, open-source software that provides a web UI and REST API for 
managing Ansible across environments.

## Manual Setup

AWX is typically run in a Kubernetes cluster using the AWX Operator.  
It can be deployed with Docker/Compose for labs or testing purposes, but in
production environments it is run on Kubernetes (k8s, OpenShift, k3s, etc.).

### K3s Setup
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

### Install AWX Operator

AWX is deployed via an **Operator**, which is a Kubernetes controller.  
It can be cloned directly from Github:  
```bash
git clone https://github.com/ansible/awx-operator.git
cd awx-operator
```
Then we can deploy it.  
```bash
make deploy
```

This installs the Custom Resource Definitions (CRDs), and the operator pod
starts watching for AWX resources.  

- Essentially, the custom resource is used to interact with the operator.  
- An operator is a piece of software that turns a complex application into a 
  native K8s **object** that can be controlled with yaml.  


### Deploy AWX
Now that k3s is set up and the AWX operator is installed, we can deploy AWX
itself.  

First, create a namespace for AWX.  
```bash
kubectl create ns awx
```
Then we create an AWX **Custom Resource (CR)** file named `awx.yaml`.  
```bash
touch awx.yaml
vi awx.yaml
```
Add the configuration:
```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: nodeport
  replicas: 1
```

Then we can `apply` it.  
```bash
kubectl apply -f awx.yaml
```

Watch for it to come up.
```bash
kubectl get pods -n awx -w
```
It may take a couple minutes for it to fully come online.  


---



