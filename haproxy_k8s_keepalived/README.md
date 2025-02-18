# High Availability Kubernetes Cluster

These scripts and playbooks are part of a high availability infrastructure setup for
a simple web application.  

It uses a Kubernetes cluster with Cilium networking, initially tested and deployed on Rocky Linux 9.4. 

---

A basic deployment consists of 5 nodes.  
- 1 K8s control plane.  
    - This is the control node for the k8s cluster.  
    - More control nodes can be added as backups.
- 2 K8s worker nodes.
    - Traffic will be forwarded to these nodes via the load balancers.  
- 2 HAProxy/keepalived nodes.
    - Keepalived generates a virtual IP (VIP) address that will allow one IP to be
      used to access the application.  

Below is a (poorly illustrated) visual representation of the flow of traffic:
```bash
            Client
              |   
   .----Keepalived(VIP)----.
   |                       |
HAProxy-LB1           HAProxy-LB2
   |     Control-Plane     |
   |     |           |     |
   Worker1           Worker2
```

