

## Installing Cilium
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
curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
tar -xzvf /tmp/cilium-install/cilium-linux-amd64.tar.gz
sudo cp /tmp/cilium-install/cilium /usr/local/bin
cilium install
```

## Troubleshooting Cilium
### Cilium Errors
#### Ping Errors
Only on master node:
```bash
cilium install [--set kubeProxyReplacement=strict]
```
- then join workers

When running:
`cilium connectivity test`

I got the following errors:
```
.  ❌ command "ping -c 1 -W 2 192.168.4.67" failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 1


.⚠️  cilium-health validation failed: "cilium-agent 'kube-system/cilium-bhbjm': connectivity to path 'kubernetes/worker-node1.host.primary-address.icmp.status' is unhealthy: 'Connection timed out'", retrying...

⚠️  cilium-health validation failed: "cilium-agent 'kube-system/cilium-bhbjm': connectivity to path 'kubernetes/worker-node1.host.primary-address.icmp.status' is unhealthy: 'Connection timed out'", retrying...

```
When canceling with C-c:
```
^C🟥 cilium-health probe on 'kube-system/cilium-bhbjm' failed: cilium-agent 'kube-system/cilium-bhbjm': connectivity to path 'kubernetes/worker-node1.host.primary-address.icmp.status' is unhealthy: 'Connection timed out'
```

However, when running `cilium status`, I get no errors:
```bash
[kolkhis@control-node1 manifests]$ cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium             Desired: 2, Ready: 2/2, Available: 2/2
DaemonSet              cilium-envoy       Desired: 2, Ready: 2/2, Available: 2/2
Deployment             cilium-operator    Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium             Running: 2
                       cilium-envoy       Running: 2
                       cilium-operator    Running: 1
Cluster Pods:          5/5 managed by Cilium
Helm chart version:    1.16.6
Image versions         cilium             quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da: 2
                       cilium-envoy       quay.io/cilium/cilium-envoy:v1.30.9-1737073743-40a016d11c0d863b772961ed0168eea6fe6b10a5@sha256:a69dfe0e54b24b0ff747385c8feeae0612cfbcae97bfcc8ee42a773bb3f69c88: 2
                       cilium-operator    quay.io/cilium/operator-generic:v1.16.6@sha256:13d32071d5a52c069fb7c35959a56009c6914439adc73e99e098917646d154fc: 1
```

### Cilium Connectivity Ping Errors Remediation Steps
- Ping test to worker-node1:
  ```bash
  [kolkhis@control-node1 manifests]$ ping -c 1 192.168.4.67                                                          
  PING 192.168.4.67 (192.168.4.67) 56(84) bytes of data.
  From 192.168.4.67 icmp_seq=1 Packet filtered
  ```
- Check firewalld rules
  ```bash
  [kolkhis@worker-node1 haproxy_k8s_keepalived]$ sudo firewall-cmd --list-all
  public (active)
    target: default
    icmp-block-inversion: yes
    interfaces: ens18
    sources:
    services: cockpit dhcpv6-client ssh
    ports: 179/tcp 10250/tcp 30000-32767/tcp 4789/udp 4240/tcp 8472/udp 6081/udp
    protocols:
    forward: yes
    masquerade: yes
    forward-ports:
    source-ports:
    icmp-blocks:
    rich rules:
  ```
    - `icmp-block-inversion: yes`: ICMP block enversion is enabled.
        - This means only explicitly allowed ICMP types are permitted and all others
          are blocked. 
        - 100% packet loss could be because the ICMP types
          `echo-request`/`echo-reply` are blocked. 

- Disable ICMP block inversion
  ```bash
  sudo firewall-cmd --zone=public --remove-icmp-block-inversion --permanent
  sudo firewall-cmd --reload
  ```
    - This allowed the ping to go through.  

#### Curl Timeout Errors
Errors:
```bash
  ℹ️  📜 Applying CiliumNetworkPolicy 'echo-ingress-l7-http' to namespace 'cilium-test-1' on cluster kubernetes..
  [-] Scenario [echo-ingress-l7/pod-to-pod-with-endpoints]
  [.] Action [echo-ingress-l7/pod-to-pod-with-endpoints/curl-ipv4-0-public: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-public (10.0.1.231:8080)]
  [.] Action [echo-ingress-l7/pod-to-pod-with-endpoints/curl-ipv4-0-private: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-private (10.0.1.231:8080)]
  [.] Action [echo-ingress-l7/pod-to-pod-with-endpoints/curl-ipv4-0-privatewith-header: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-privatewith-header (10.0.1.231:8080)]
  [.] Action [echo-ingress-l7/pod-to-pod-with-endpoints/curl-ipv4-1-public: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-public (10.0.1.231:8080)]
  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 http://10.0.1.231:8080/public" failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28
.  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 http://10.0.1.231:8080/private" failed with unexpected exit code: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28 (expected 22, found 28)
  [.] Action [echo-ingress-l7/pod-to-pod-with-endpoints/curl-ipv4-1-privatewith-header: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-privatewith-header (10.0.1.231:8080)]
.  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 -H X-Very-Secret-Token: 42 http://10.0.1.231:8080/private" failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28
  ℹ️  curl stdout:
  :0 -> :0 = 000
  ℹ️  curl stderr:
  curl: (28) Failed to connect to 10.0.1.231 port 8080 after 2002 ms: Timeout was reached

  ℹ️  📜 Deleting CiliumNetworkPolicy 'echo-ingress-l7-http' in namespace 'cilium-test-1' on cluster kubernetes..
[=] [cilium-test-1] Skipping test [echo-ingress-l7-via-hostport] [65/105] (skipped by condition)
[=] [cilium-test-1] Test [echo-ingress-l7-named-port] [66/105]
....
  ℹ️  curl stdout:
  :0 -> :0 = 000
  ℹ️  curl stderr:
  curl: (28) Failed to connect to 10.0.1.231 port 8080 after 2002 ms: Timeout was reached

  [.] Action [echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-1-private: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-private (10.0.1.231:8080)]
  ℹ️  📜 Applying CiliumNetworkPolicy 'echo-ingress-l7-http-named-port' to namespace 'cilium-test-1' on cluster kubernetes..
  [-] Scenario [echo-ingress-l7-named-port/pod-to-pod-with-endpoints]
  [.] Action [echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-0-public: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-public (10.0.1.231:8080)]
  [.] Action [echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-0-private: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-private (10.0.1.231:8080)]
  [.] Action [echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-0-privatewith-header: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-privatewith-header (10.0.1.231:8080)]
  [.] Action [echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-1-public: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-public (10.0.1.231:8080)]
  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 http://10.0.1.231:8080/public" failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28
.  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 http://10.0.1.231:8080/private" failed with unexpected exit code: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28 (expected 22, found 28)
  [.] Action [echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-1-privatewith-header: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-privatewith-header (10.0.1.231:8080)]
.  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 -H X-Very-Secret-Token: 42 http://10.0.1.231:8080/private" failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28
  ℹ️  curl stdout:
  :0 -> :0 = 000
  ℹ️  curl stderr:
  curl: (28) Failed to connect to 10.0.1.231 port 8080 after 2001 ms: Timeout was reached

  ℹ️  📜 Deleting CiliumNetworkPolicy 'echo-ingress-l7-http-named-port' in namespace 'cilium-test-1' on cluster kubernetes..
[=] [cilium-test-1] Test [client-egress-l7-method] [67/105]
....
  ℹ️  curl stdout:
  :0 -> :0 = 000
  ℹ️  curl stderr:
  curl: (28) Failed to connect to 10.0.1.231 port 8080 after 2002 ms: Timeout was reached

  [.] Action [client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-1-private: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-private (10.0.1.231:8080)]
  ℹ️  📜 Applying CiliumNetworkPolicy 'client-egress-only-dns' to namespace 'cilium-test-1' on cluster kubernetes..
  ℹ️  📜 Applying CiliumNetworkPolicy 'client-egress-l7-http-method' to namespace 'cilium-test-1' on cluster kubernetes..
  [-] Scenario [client-egress-l7-method/pod-to-pod-with-endpoints]
  [-] Scenario [client-egress-l7-method/pod-to-pod-with-endpoints]
  [.] Action [client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-0-public: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-public (10.0.1.231:8080)]
  [.] Action [client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-0-private: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-private (10.0.1.231:8080)]
  [.] Action [client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-0-privatewith-header: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> curl-ipv4-0-privatewith-header (10.0.1.231:8080)]
  [.] Action [client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-1-public: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-public (10.0.1.231:8080)]
  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 -X POST http://10.0.1.231:8080/public" failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28
.  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 -X POST http://10.0.1.231:8080/private" failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28
  ℹ️  curl stdout:
  :0 -> :0 = 000
  ℹ️  curl stderr:
  curl: (28) Failed to connect to 10.0.1.231 port 8080 after 2002 ms: Timeout was reached

  [.] Action [client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-1-privatewith-header: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-privatewith-header (10.0.1.231:8080)]
.  ❌ command "curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 -X POST -H X-Very-Secret-Token: 42 http://10.0.1.231:8080/private" failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28
  ℹ️  curl stdout:
  :0 -> :0 = 000
  ℹ️  curl stderr:
  curl: (28) Failed to connect to 10.0.1.231 port 8080 after 2001 ms: Timeout was reached

  ℹ️  📜 Deleting CiliumNetworkPolicy 'client-egress-only-dns' in namespace 'cilium-test-1' on cluster kubernetes..
  ℹ️  📜 Deleting CiliumNetworkPolicy 'client-egress-l7-http-method' in namespace 'cilium-test-1' on cluster kubernetes..

```
Command failing:
```bash
curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 -X POST http://10.0.1.231:8080/public

curl -w %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port} = %{response_code} --silent --fail --show-error --output /dev/null --connect-timeout 2 --max-time 10 -X POST -H X-Very-Secret-Token: 42 http://10.0.1.231:8080/private
# failed: command failed (pod=cilium-test-1/client2-66475877c6-jkjb6, container=client2): command terminated with exit code 28
```

#### Troubleshooting Curl Errors
Checking connectivity
```bash
curl 10.0.1.231:8080
```
This returned an html page saying (among other things):
```html
<p>
  You're successfully running JSON Server
  <br />
  ✧*｡٩(ˊᗜˋ*)و✧*｡
</p>
```
So, a basic curl is working. The curls that were done on the test seem to not be
working.  
<!-- TODO: Explain the syntax that is being used here -->

Using the endpoints specified in the cmds (`/public` && `/private`]):
```bash
}[kolkhis@control-node1 manifests]$
`[kolkhis@control-node1 manifests]$ curl -X POST 10.0.1.231:8080
{}[kolkhis@control-node1 manifests]$ curl -X POST 10.0.1.231:8080/public
{
  "id": 2
}[kolkhis@control-node1 manifests]$ curl -X POST -H "X-Very-Secret-Token: 42" http://10.0.1.231:8080/private
{
  "id": 3
}[kolkhis@control-node1 manifests]$ curl -X POST -H "X-Very-Secret-Token: 42" http://10.0.1.231:8080/private
{
  "id": 4
}[kolkhis@control-node1 manifests]$ curl http://10.0.1.231:8080/public
[
  {
    "id": 1,
    "body": "public information"
  },
  {
    "id": 2
  }
][kolkhis@control-node1 manifests]$ curl https://10.0.1.231:8080/public
curl: (35) error:0A0000C6:SSL routines::packet length too long

```
These endpoints are responding.  
However, when adding either `http://` or `https://` to the IPs, they stop responding.  
```bash
[kolkhis@control-node1 manifests]$ curl -X POST -H "X-Very-Secret-Token: 42" https://0.0.1.231:8080/private
# It just hangs.
```


---


## Cilium Connectivity Test Results
```bash
📋 Test Report [cilium-test-1]
❌ 8/56 tests failed (21/243 actions), 49 tests skipped, 0 scenarios skipped:
Test [echo-ingress-l7]:
  ❌ echo-ingress-l7/pod-to-pod-with-endpoints/curl-ipv4-1-public: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-public (10.0.1.231:8080)
  ❌ echo-ingress-l7/pod-to-pod-with-endpoints/curl-ipv4-1-private: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-private (10.0.1.231:8080)
  ❌ echo-ingress-l7/pod-to-pod-with-endpoints/curl-ipv4-1-privatewith-header: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-privatewith-header (10.0.1.231:8080)
Test [echo-ingress-l7-named-port]:
  ❌ echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-1-public: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-public (10.0.1.231:8080)
  ❌ echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-1-private: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-private (10.0.1.231:8080)
  ❌ echo-ingress-l7-named-port/pod-to-pod-with-endpoints/curl-ipv4-1-privatewith-header: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-privatewith-header (10.0.1.231:8080)
Test [client-egress-l7-method]:
  ❌ client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-1-public: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-public (10.0.1.231:8080)
  ❌ client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-1-private: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-private (10.0.1.231:8080)
  ❌ client-egress-l7-method/pod-to-pod-with-endpoints/curl-ipv4-1-privatewith-header: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> curl-ipv4-1-privatewith-header (10.0.1.231:8080)
Test [client-egress-l7]:
  ❌ client-egress-l7/pod-to-world/http-to-one.one.one.one.-1: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> one.one.one.one.-http (one.one.one.one.:80)
  ❌ client-egress-l7/pod-to-pod/curl-ipv4-0: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> cilium-test-1/echo-same-node-6c545975c6-bxbrb (10.0.1.231:8080)
Test [client-egress-l7-named-port]:
  ❌ client-egress-l7-named-port/pod-to-pod/curl-ipv4-1: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> cilium-test-1/echo-same-node-6c545975c6-bxbrb (10.0.1.231:8080)
  ❌ client-egress-l7-named-port/pod-to-world/http-to-one.one.one.one.-1: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> one.one.one.one.-http (one.one.one.one.:80)
Test [client-egress-tls-sni]:
  ❌ client-egress-tls-sni/pod-to-world/https-to-one.one.one.one.-0: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> one.one.one.one.-https (one.one.one.one.:443)
  ❌ client-egress-tls-sni/pod-to-world/https-to-one.one.one.one.-index-0: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> one.one.one.one.-https-index (one.one.one.one.:443)
  ❌ client-egress-tls-sni/pod-to-world/https-to-one.one.one.one.-1: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> one.one.one.one.-https (one.one.one.one.:443)
  ❌ client-egress-tls-sni/pod-to-world/https-to-one.one.one.one.-index-1: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> one.one.one.one.-https-index (one.one.one.one.:443)
Test [client-egress-tls-sni-denied]:
  ❌ client-egress-tls-sni-denied/pod-to-world-2/https-cilium.io.-0: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> cilium.io.-https (cilium.io.:443)
  ❌ client-egress-tls-sni-denied/pod-to-world-2/https-cilium.io.-1: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> cilium.io.-https (cilium.io.:443)
Test [to-fqdns]:
  ❌ to-fqdns/pod-to-world/http-to-one.one.one.one.-0: cilium-test-1/client-645b68dcf7-dgqb4 (10.0.1.56) -> one.one.one.one.-http (one.one.one.one.:80)
  ❌ to-fqdns/pod-to-world/http-to-one.one.one.one.-1: cilium-test-1/client2-66475877c6-jkjb6 (10.0.1.55) -> one.one.one.one.-http (one.one.one.one.:80)

[cilium-test-1] 8 tests failed
```


## Links
* [Cilium Docs: Quick install](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)
* [Cilium Docs: Troubleshooting](https://docs.cilium.io/en/stable/operations/troubleshooting/)

