# Misc Notes

A collection of personal notes.  

---

`sudo kubeadm reset` to undo the `init`. Also delete `~/.kube/config`

## TODO
- Create the containerd config file and enable systemd cgroup.  
  ```bash
  containerd config default | sudo tee /etc/containerd/config.toml
  sudo sed -i -e '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml
  ```

* [k3s-ansible](https://github.com/k3s-io/k3s-ansible)
* [kubespray](https://github.com/kubernetes-sigs/kubespray)


---
Add each new app to new namespace.  
```bash
kubectl get ns
```

- [x] Add the 'overlay' kernel module 
  ```bash
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
  br_netfilter
  overlay
  EOF
  ```
    - Needed for container storage in containerd/docker.  
    - This enables OverlayFS (filesystem) which is used to manage container layers.  

- [x] Enable IP Forwarding in iptables
  ```bash
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
  net.ipv4.ip_forward = 1
  EOF
  ```

- [x] Add ports to firewalld
    - WORKER NODES ONLY:
      ```bash
      sudo firewall-cmd --permanent --add-port={179,10250,30000-32767}/tcp
      sudo firewall-cmd --permanent --add-port=4789/udp
      sudo firewall-cmd --reload
      ```
    - MASTER NODE(S) ONLY:
      ```bash
      sudo firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252,10257,10259,179}/tcp
      sudo firewall-cmd --permanent --add-port=4789/udp
      sudo firewall-cmd --reload
      ```
        - `6443/tcp`: Kubernetes API server (control plane)
        - `2379-2380/tcp`: `etcd` database communication
        - `10250/tcp`: Kubelet API (for node communication)
        - `10251/tcp`: KLube-scheduler
        - `10257/tcp`: `kube-apiserver` authentication webhook
        - `10259/tcp`: `kube-controller` authentication webhook
        - `179/tcp`: BGP (for Calico networking)
        - `4789/udp`: VXLAN (Overlay networking, used by Flannel and Calico)
        - `30000-32767/tcp`: NodePort Services (worker nodes)

Ensure iptables is correctly handling bridged traffic:
```bash
sudo firewall-cmd --permanent --add-masquerade
sudo firewall-cmd --reload
```

- [x] Add containerd runtime repo
  ```bash
  sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  ```
    * install containerd `sudo dnf install containerd -y`

- [x] Configure containerd so that it will use `systemdcgroup` (TODO: ??)
  ```bash
  containerd config default | sudo tee /etc/containerd/config.toml > /dev/null 2>&1
  #sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
  sudo sed -i '/SystemdCgroup/s/false/true/'
  ```
    - This is necessary for k8s to manage container resources correctly. 
    - Cgroups (Control Goups) allow k8s to control system resources (CPU, mem, etc)
    - It ensures that containerd uses `systemd` for cgroup management.
    - Two common ways to manage cgroups
        - Systemd (recommended for k8s)
        - cgroupfs (default in containerd, but not the recommended for k8s)
    - k8s exprects systemd to manage cgroups.
    - This should not be the `disable_cgroup` option under `[plugins."io.containerd.grpc.vi.cri"]`
    - This should be the `SystemdCgroup` option under `[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]`

```bash
sudo sysctl --system
sudo systemctl restart containerd
sudo systemctl enable containerd --now
sudo systemctl status containerd
sudo crictl info  # if this fails, containerd is still misconfigured
```

https://github.com/justmeandopensource/kubernetes/tree/master/kubeadm-ha-keepalived-haproxy/external-keepalived-haproxy

### After `kubeadm init`
#### Command:
Old init command:
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

New init command (for using Cilium):
```bash
sudo kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --cri-socket=unix:///run/containerd/containerd.sock \
    --skip-phases=addon/kube-proxy
```

#### Output:

```plaintext
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.4.56:6443 --token OUTDATED.DIFFERENT \
            --discovery-token-ca-cert-hash sha256:OUTDATED
```


## Resources
Flannel Docs: https://github.com/flannel-io/flannel?tab=readme-ov-file
K8s with Cri-o and Cilium (Rocky): https://blog.andreev.it/2023/10/install-kubernetes-with-cri-o-and-cilium-on-rocky-linux-9/
K8s Install on Rocky9: https://www.linuxtechi.com/install-kubernetes-on-rockylinux-almalinux/


## Troubleshooting
### Kube-APIserver Not Responding
Problem: Kube-APIserver is not accessible. All attempts to connect to host 192.168.4.56:6443 have failed.  
```bash
[kolkhis@control-node1 haproxy_k8s_keepalived]$ kubectl get pods -n kube-system
E0206 11:53:09.033991 1354084 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
E0206 11:53:09.036449 1354084 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
E0206 11:53:09.038586 1354084 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
E0206 11:53:09.040521 1354084 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
E0206 11:53:09.042406 1354084 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
The connection to the server 192.168.4.56:6443 was refused - did you specify the right host or port?

[kolkhis@control-node1 haproxy_k8s_keepalived]$ curl -k https://192.168.4.56:6443/healthz
curl: (7) Failed to connect to 192.168.4.56 port 6443: Connection refused

[kolkhis@control-node1 haproxy_k8s_keepalived]$ sudo firewall-cmd --list-ports
179/tcp 2379/tcp 2380/tcp 6443/tcp 10250/tcp 10251/tcp 10252/tcp 10257/tcp 10259/tcp 4789/udp

[kolkhis@control-node1 haproxy_k8s_keepalived]$ kubectl cluster-info
E0206 11:54:29.258218 1354179 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
E0206 11:54:29.260553 1354179 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
E0206 11:54:29.262763 1354179 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
E0206 11:54:29.264802 1354179 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"
E0206 11:54:29.267010 1354179 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.4.56:6443/api?timeout=32s\": dial tcp 192.168.4.56:6443: connect: connection refused"

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
The connection to the server 192.168.4.56:6443 was refused - did you specify the right host or port?
```


Logs from systemd:
```bash
[kolkhis@control-node1 haproxy_k8s_keepalived]$ sudo systemctl status kubelet -l --no-pager
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: disabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Fri 2025-01-31 14:15:03 EST; 5 days ago
       Docs: https://kubernetes.io/docs/
   Main PID: 123350 (kubelet)
      Tasks: 13 (limit: 10948)
     Memory: 70.7M
        CPU: 4h 25min 13.180s
     CGroup: /system.slice/kubelet.service
             └─123350 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.10

Feb 06 11:52:25 control-node1 kubelet[123350]: E0206 11:52:25.334271  123350 kubelet.go:3008] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
Feb 06 11:52:26 control-node1 kubelet[123350]: E0206 11:52:26.429438  123350 kubelet_node_status.go:549] "Error updating node status, will retry" err="failed to patch status \"{\\\"status\\\":{\\\"$setElementOrder/conditions\\\":[{\\\"type\\\":\\\"MemoryPressure\\\"},{\\\"type\\\":\\\"DiskPressure\\\"},{\\\"type\\\":\\\"PIDPressure\\\"},{\\\"type\\\":\\\"Ready\\\"}],\\\"conditions\\\":[{\\\"lastHeartbeatTime\\\":\\\"2025-02-06T16:52:26Z\\\",\\\"type\\\":\\\"MemoryPressure\\\"},{\\\"lastHeartbeatTime\\\":\\\"2025-02-06T16:52:26Z\\\",\\\"type\\\":\\\"DiskPressure\\\"},{\\\"lastHeartbeatTime\\\":\\\"2025-02-06T16:52:26Z\\\",\\\"type\\\":\\\"PIDPressure\\\"},{\\\"lastHeartbeatTime\\\":\\\"2025-02-06T16:52:26Z\\\",\\\"type\\\":\\\"Ready\\\"}]}}\" for node \"control-node1\": Patch \"https://192.168.4.56:6443/api/v1/nodes/control-node1/status?timeout=10s\": dial tcp 192.168.4.56:6443: connect: connection refused"
Feb 06 11:52:26 control-node1 kubelet[123350]: E0206 11:52:26.430507  123350 kubelet_node_status.go:549] "Error updating node status, will retry" err="error getting node \"control-node1\": Get \"https://192.168.4.56:6443/api/v1/nodes/control-node1?timeout=10s\": dial tcp 192.168.4.56:6443: connect: connection refused"
Feb 06 11:52:26 control-node1 kubelet[123350]: E0206 11:52:26.431334  123350 kubelet_node_status.go:549] "Error updating node status, will retry" err="error getting node \"control-node1\": Get \"https://192.168.4.56:6443/api/v1/nodes/control-node1?timeout=10s\": dial tcp 192.168.4.56:6443: connect: connection refused"
Feb 06 11:52:26 control-node1 kubelet[123350]: E0206 11:52:26.431972  123350 kubelet_node_status.go:549] "Error updating node status, will retry" err="error getting node \"control-node1\": Get \"https://192.168.4.56:6443/api/v1/nodes/control-node1?timeout=10s\": dial tcp 192.168.4.56:6443: connect: connection refused"
Feb 06 11:52:26 control-node1 kubelet[123350]: E0206 11:52:26.432743  123350 kubelet_node_status.go:549] "Error updating node status, will retry" err="error getting node \"control-node1\": Get \"https://192.168.4.56:6443/api/v1/nodes/control-node1?timeout=10s\": dial tcp 192.168.4.56:6443: connect: connection refused"
Feb 06 11:52:26 control-node1 kubelet[123350]: E0206 11:52:26.432961  123350 kubelet_node_status.go:536] "Unable to update node status" err="update node status exceeds retry count"
Feb 06 11:52:26 control-node1 kubelet[123350]: I0206 11:52:26.855980  123350 scope.go:117] "RemoveContainer" containerID="f1695c012188934edbe8c865484399184e2410f15b9243812011c679718cca87"
Feb 06 11:52:26 control-node1 kubelet[123350]: E0206 11:52:26.856285  123350 dns.go:153] "Nameserver limits exceeded" err="Nameserver limits were exceeded, some nameservers have been omitted, the applied nameserver line is: 71.10.216.2 71.10.216.1 2607:f428:ffff:ffff::2"
Feb 06 11:52:26 control-node1 kubelet[123350]: E0206 11:52:26.856542  123350 pod_workers.go:1301] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"kube-controller-manager\" with CrashLoopBackOff: \"back-off 5m0s restarting failed container=kube-controller-manager pod=kube-controller-manager-control-node1_kube-system(0398b2e9018af8eaa7d2df621d63b6eb)\"" pod="kube-system/kube-controller-manager-control-node1" podUID="0398b2e9018af8eaa7d2df621d63b6eb"
```

Using `crictl` to get the status of all the pods:
```bash
[kolkhis@control-node1 haproxy_k8s_keepalived]$ sudo crictl pods
[sudo] password for kolkhis:
WARN[0000] Config "/etc/crictl.yaml" does not exist, trying next: "/usr/bin/crictl.yaml"
WARN[0000] runtime connect using default endpoints: [unix:///run/containerd/containerd.sock unix:///run/crio/crio.sock unix:///var/run/cri-dockerd.sock]. As the default settings are now deprecated, you should set the endpoint instead.
POD ID              CREATED              STATE               NAME                                    NAMESPACE           ATTEMPT             RUNTIME
a0cfc4bcd922f       7 seconds ago        Ready               kube-proxy-5kjhs                        kube-system         1370                (default)
5e0e7752052f4       About a minute ago   Ready               kube-scheduler-control-node1            kube-system         1647                (default)
8fd2224c594fb       About a minute ago   NotReady            kube-scheduler-control-node1            kube-system         1646                (default)
1177d2d9c719d       2 minutes ago        Ready               kube-controller-manager-control-node1   kube-system         1555                (default)
14b2fc1f6c0e9       3 minutes ago        Ready               kube-apiserver-control-node1            kube-system         937                 (default)
a0b0eddff4668       3 minutes ago        Ready               etcd-control-node1                      kube-system         1643                (default)
59ad328075fdf       5 minutes ago        NotReady            kube-proxy-5kjhs                        kube-system         1369                (default)
de4b4228b2741       8 minutes ago        NotReady            kube-controller-manager-control-node1   kube-system         1554                (default)
bdf08b00c8560       11 minutes ago       NotReady            etcd-control-node1                      kube-system         1642                (default)
a1e617e62fc7b       11 minutes ago       NotReady            kube-proxy-5kjhs                        kube-system         1368                (default)
13941229292fe       14 minutes ago       NotReady            kube-apiserver-control-node1            kube-system         936                 (default)
```
So this verifies that the pods are currently there. However, they're mostly in the "NotReady" state.  


Tried disabling firewalld:
```bash
[kolkhis@control-node1 haproxy_k8s_keepalived]$ sudo systemctl stop firewalld
[kolkhis@control-node1 haproxy_k8s_keepalived]$ sudo systemctl status firewalld
○ firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; preset: enabled)
     Active: inactive (dead) since Thu 2025-02-06 12:06:13 EST; 5s ago
   Duration: 2w 3d 20h 19min 16.216s
       Docs: man:firewalld(1)
    Process: 739 ExecStart=/usr/sbin/firewalld --nofork --nopid $FIREWALLD_ARGS (code=exited,>
   Main PID: 739 (code=exited, status=0/SUCCESS)
        CPU: 35.139s
```
Still no cmds can get through to the kube API server.  


### Solution - Containterd Cgroup
Enable `SystemdCgroup` in `/etc/containerd/config.toml`
```bash
[kolkhis@control-node1 haproxy_k8s_keepalived]$ less /etc/containerd/config.toml
[kolkhis@control-node1 haproxy_k8s_keepalived]$ grep -i SystemdCgroup /etc/containerd/config.toml
    SystemdCgroup = false
[kolkhis@control-node1 haproxy_k8s_keepalived]$ sudo sed -i_old '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml                                                                 
[kolkhis@control-node1 haproxy_k8s_keepalived]$ grep -i SystemdCgroup /etc/containerd/config.toml
    SystemdCgroup = true
```

Make sure kubelet is configured to use the same cgroup driver as containerd:
```bash
[kolkhis@control-node1 haproxy_k8s_keepalived]$ grep -i 'cgroup' /var/lib/kubelet/config.yaml
cgroupDriver: systemd
```

Restart containerd
```bash
sudo systemctl restart containerd
```

### Rollback - SSL errors
After rolling back the rocky control node to a snapshot, I'm getting all sorts of SSL errors. 
When trying to clone my repository:
```bash
[kolkhis@control-node1 ~]$ git clone https://github.com/kolkhis/scripts-playbooks.git
Cloning into 'scripts-playbooks'...
fatal: unable to access 'https://github.com/kolkhis/scripts-playbooks.git/': SSL certificate problem: certificate is not yet valid
```

When trying to install dependencies:
```bash
Curl error (60): SSL peer certificate or SSH remote key was not OK for https://mirrors.rockylinux.org/mirrorlist?arch=x86_64&repo=BaseOS-9 [SSL certificate problem: certificate is not yet valid]
```

### SSL Error Solution: Sync date time
Reboot right away? 
Enable Network Time Protocol (NTP)
NTP makes sure your system clock is synchronized with global time servers.  
```bash
sudo timedatectl status
sudo timedatectl set-ntp true
```

Then either wait or reboot to synchronize the clock.  

### Problem: Failed to download `/etc/pki/rpm-gpg/RPM-GPG-KEY-kubernetes`
When not using a remote link to a GPG key, specify that it's a file.  
Solution: Add `file://` to key in repository.  
```bash
cat <<- EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
...
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kubernetes
```

## Kubeadm Init Troubleshooting

```bash
# sudo kubeadm init --pod-network-cidr=10.244.0.0/16
[sudo] password for kolkhis:
[init] Using Kubernetes version: v1.32.1
[preflight] Running pre-flight checks
W0206 15:59:57.474036   12746 checks.go:1080] [preflight] WARNING: Couldn't create the interface used for talking to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/containerd/containerd.sock": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService
        [WARNING Firewalld]: firewalld is active, please ensure ports [6443 10250] are open or your cluster may not function correctly
        [WARNING Hostname]: hostname "control-node1" could not be reached
        [WARNING Hostname]: hostname "control-node1": lookup control-node1 on 71.10.216.2:53: no such host
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
error execution phase preflight: [preflight] Some fatal errors occurred:
failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/containerd/containerd.sock": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```

* Primary error:
    ```bash
    failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///var/run/containerd/containerd.sock": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService
    ```
    - Is `containerd` disabling the CRI plugin? Is it misconfigured?
    - Removed /etc/containerd/config.toml and the init worked.

* Hostname error:
    - Make sure the hostname (not necessarily FQDN) is pointed to the correct IP.
      ```bash
      sudo vi /etc/hosts
      ```
    - I added `control-node1` to the line that has `127.0.0.1` (`localhost`).  
    - `kubeadm init` then worked.  
    - Now I'm getting these errors with `kubectl get pods` (Connection refused)
    - Added a line `192.168.4.56 control-node1` 
        - This is wrong. It should only be pointed at localhost, right?

     ```bash
     [kolkhis@control-node1 haproxy_k8s_keepalived]$ kubectl get pods
     E0206 16:12:54.412351 15114 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp [::1]:8080: connect: connection refused"
     E0206 16:12:54.420031 15114 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp [::1]:8080: connect: connection refused"
     E0206 16:12:54.423633 15114 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp [::1]:8080: connect: connection refused"
     E0206 16:12:54.427354 15114 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp [::1]:8080: connect: connection refused"
     E0206 16:12:54.430104 15114 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp [::1]:8080: connect: connection refused"
     The connection to the server localhost:8080 was refused - did you specify the right host or port?
     ```

### Get Logs
```bash
sudo journalctl -xeu kubelet
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}')
```

## /etc/hosts mapping
I'm trying to get a kubernetes control plane up and running. The node's hostname is `control-node1`.  
I'm able to initialize a cluster -with `kubeadm init --pod-network-cidr=10.244.0.0/16`.  
Then I create the kubeconfig directory and copy over the `admin.conf`.  

Then, every call to kubectl keeps trying to hit `localhost:8080` for the kubernetes API server, rather than the network IP on port 6443. After copying the `admin.conf` over to kube/config then it pings the correct address/port.  

The `/etc/hosts` mapping should only point the $(hostname) to `127.0.0.1`, and NOT the node's network IP?

## Containerd Cgroup
There are two locations in `/etc/containerd/config.toml` that contain options for Systemd Cgroups.
The one that is PascalCase (`SystemdCgroup`) is the one that must be set to `true`.  
The one that is camel_case (`systemd_cgroup`) does not seem to be needed.  

fix: cgroup.

---

## INIT JOIN
After the `kubeadm init`, this outputs on success:

>Your Kubernetes control-plane has initialized successfully!

>To start using your cluster, you need to run the following as a regular user:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
>Alternatively, if you are the root user, you can run:

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```

>You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

>Then you can join any number of worker nodes by running the following on each as root:
```bash
kubeadm join 192.168.4.56:6443 --token OUTDATED \
        --discovery-token-ca-cert-hash sha256:OUTDATED
```

---

Cilium vs. Calico

## Cilium vs. Flannel vs. Calico
Networking model:
* Flannel: "Overlay" (VXLAN)
* Calico: Native L3 Routing, VXLAN
* Cilium: eBPF-based

Security: 
* Flannel: Basic
* Calico: Advanced (IPTables, eBPF)
* Cilium: Best (eBPF-native)

Performance:
* Flannel: moderate
* Calico: better than flannel
* Cilium: best (eBPF bypasses kernel limitations)

Observability
* Flannel: Limited
* Calico: decent via Felix
* Cilium: Great with Hubble for monitoring

Complexity:
* Flannel: Simple
* Calico: Moderate
* Cilium: Advanced

Integration
* Flannel: basic CNI
* Calico: good for cloud/on-prem
* Cilium: best for cloud-native environments


OVERALL
When to Choose Calico:
 * You need network policies and security: Flannel doesn’t provide robust NetworkPolicy support, whereas Calico has a mature implementation.
 * You're running hybrid or on-prem: Calico integrates well with traditional network setups, making it a solid choice for bare-metal Kubernetes clusters.
 * You want a familiar, widely used option: Calico is well-documented and widely adopted in enterprise Kubernetes deployments.

When to Choose Cilium:

* You want eBPF performance and scalability
    - Cilium is faster than Calico because it bypasses iptables and directly manipulates networking at the kernel level.
* You care about observability
    - Cilium comes with Hubble, which provides deep network monitoring, service discovery, and security insights.
* You plan to use service mesh or cloud-native security
    - It integrates seamlessly with Istio, Envoy, and Kubernetes network policies.
* More complex to set up than Calico, but worth it if you plan to run at scale.

---


## Order to INit
* Initialize the control plane first.
* Install Cilium before adding worker nodes.
* Join worker nodes to the cluster after Cilium is set up.

* TODO: Use helm?

### INIT
master node:
Cilium has `kube-proxy replacement`
If you want to use this, skip the default `kube-proxy` setup phase
```bash
kubeadm init --skip-phases=addon/kube-proxy
```

`--skip-phases=addon/kube-proxy` is necessary when letting Cilum handle the
kube-proxy functionality

### CONFIGURE

```bash
mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown "$(id -u):$(id -g)" ~/.kube/config
```

### INSTALL CILIUM

* IF you're using Helm:
    * Add Cilium helm repo
      ```bash
      help repo add cilium https://helm.cilium.io/
      ```
    * Use helm to install cilium in the `kube-system` namespace
    ```bash
    help install cilium cilium/cilium --version 1.17.0 --namespace kube-system
    ```

Or;
```bash
cilium install
```

---
### JOIN WORKERS
On each worker node, use the `kubeadm join` from the `kubeadm init` output
```bash
sudo kubeadm join $CONTROL_PLANE_IP:$PORT --token....
```

### VERIFY INSTALL
Check status of nodes
```bash
kubectl get nodes
```
Verify that Cilium pods are running
```bash
kubectl -n kube-system get pods -l k8s-app=cilium
```

### ERROR
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket=unix:///run/containerd/containerd.sock --skip-phases=addon/kube-proxy

[init] Using Kubernetes version: v1.32.1
[preflight] Running pre-flight checks
W0208 20:43:40.266669    3063 checks.go:1080] [preflight] WARNING: Couldn't create the interface used for talking to the container runtime: failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///run/containerd/containerd.sock": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService
        [WARNING Firewalld]: firewalld is active, please ensure ports [6443 10250] are open or your cluster may not function correctly
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connecti
on
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
error execution phase preflight: [preflight] Some fatal errors occurred:
failed to create new CRI runtime service: validate service connection: validate CRI v1 runtime API for endpoint "unix:///run/containerd/containerd.sock": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher



  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

```
[join command in join-nodes.md](./join-nodes.md)

## Nginx Demo Deployment
```bash
kubectl create deployment nginx-demo --image=nginx:stable
kubectl scale deployment nginx-demo --replicas=2
kubectl expose deployment nginx-demo --type=NodePort --port=80
kubectl get deployment nginx-demo
kubectl get svc nginx-demo
#NAME         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
#nginx-demo   NodePort   10.101.59.244   <none>        80:30189/TCP   21s
curl localhost:30189
# Nginx welcome page if successful
```

---
Manifests files:
`/etc/kubernetes/manifests/*.yaml`
  
  ---

