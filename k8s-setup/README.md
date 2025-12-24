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

## `./install-k8s`

> **Note**: This script has only been tested on RedHat-based operating
> systems (Rocky Linux).  
> The Debian-based installation process is present but untested.  

This script configures the system for Kubernetes and installs the necessary
tools:

- `kubelet`  
- `kubectl`  
- `kubeadm`  
- `containerd`  

The container runtime engine used in this installation is `containerd`, which
is additionally installed alongside K8s administration tools.    

System configuration performed:

- Disable swap  
- Enable necessary kernel modules  
- Configure network bridge for iptables, enable IP forwarding in `sysctl`
    - `net.bridge.bridge-nf-call-ip6tables`  
    - `net.bridge.bridge-nf-call-iptables`  
    - `net.ipv4.ip_forward`  
    - In case modification is needed, this process saves the iptables configuration 
      into `/etc/sysctl.d/k8s.conf`.  
- Open ports required for Kubernetes and Cilium (with `firewalld`, RHEL only)  
- Configure `systemd` to use `systemdcgroup`  
    - This configuration is stored in `/etc/containerd/config.toml`.  

## `./install-cilium`

This is a helper script used to install the Cilium CNI (Container Network
Interface). This script should only be run on the K8s control node.  

It should be invoked directly on the control node:
```bash
./install-cilium
```

By default, this script is equipped with a safety mechanism that checks the
hostname of the machine it's currently be run on, and will not proceed with the
installation unless the hostname contains either of the words "control" or 
"master." To disable this behavior, pass in the `-i` or `--ignore-hostname`
option on invocation.  

```bash
./install-cilium -i
```

This downloads and installs the latest Cilium CLI release from GitHub.  

By default it utilizes the `/tmp/cilium-install` temporary directory to store
the tarball file. It deletes this directory and the tarball automatically after 
installation.  

To change the Cilium version that is downloaded and installed, modify the value 
of the `CILIUM_DOWNLOAD_LINK` variable to store the download link for the desired
version.  




