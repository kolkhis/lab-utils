# HAProxy Troubleshooting

## Error:
Permission is being denied, and the k8s_backend is not being recognized.  
```bash
[kolkhis@haproxy-lb1 haproxy_k8s_keepalived]$ sudo systemctl status haproxy --no-pager -l
● haproxy.service - HAProxy Load Balancer
     Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; preset: disabled)
     Active: active (running) since Fri 2025-02-14 15:57:59 EST; 11min ago
   Main PID: 189434 (haproxy)
      Tasks: 3 (limit: 10948)
     Memory: 75.5M
        CPU: 433ms
     CGroup: /system.slice/haproxy.service
             ├─189434 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -f /etc/haproxy/conf.d -p /run/haproxy.pid
             └─189436 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -f /etc/haproxy/conf.d -p /run/haproxy.pid

Feb 14 15:57:59 haproxy-lb1 systemd[1]: Starting HAProxy Load Balancer...
Feb 14 15:57:59 haproxy-lb1 haproxy[189434]: [NOTICE]   (189434) : New worker #1 (189436) forked
Feb 14 15:57:59 haproxy-lb1 systemd[1]: Started HAProxy Load Balancer.
Feb 14 15:57:59 haproxy-lb1 haproxy[189436]: [WARNING]  (189436) : Server k8s_backend/worker1 is DOWN, reason: Layer4 connection problem, info: "General socket error (Permission denied)", check duration: 0ms. 1 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
Feb 14 15:57:59 haproxy-lb1 haproxy[189436]: [NOTICE]   (189436) : haproxy version is 2.4.22-f8e3218
Feb 14 15:57:59 haproxy-lb1 haproxy[189436]: [NOTICE]   (189436) : path to executable is /usr/sbin/haproxy
Feb 14 15:57:59 haproxy-lb1 haproxy[189436]: [ALERT]    (189436) : sendmsg()/writev() failed in logger #1: No such file or directory (errno=2)
Feb 14 15:58:00 haproxy-lb1 haproxy[189436]: [WARNING]  (189436) : Server k8s_backend/worker2 is DOWN, reason: Layer4 connection problem, info: "General socket error (Permission denied)", check duration: 0ms. 0 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
Feb 14 15:58:00 haproxy-lb1 haproxy[189436]: [ALERT]    (189436) : backend 'k8s_backend' has no server available!
```

### Troubleshooting
Check selinux:
```bash
getenforce
```
It was on. Switch to permissive:
```bash
sudo setenforce 0
```
Reload, still wasn't working.

Check firewalld rules:
```bash
[kolkhis@haproxy-lb1 haproxy_k8s_keepalived]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens18
  sources:
  services: cockpit dhcpv6-client ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
[kolkhis@haproxy-lb1 haproxy_k8s_keepalived]$ sudo firewall-cmd --list-ports

```
No ports open. 

Add port 443 and 80
```bash
sudo firewall-cmd --add-port={443,80,31890}/tcp --permanent
sudo firewall-cmd --reload
```

Works now.


