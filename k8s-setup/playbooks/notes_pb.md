
Ansible failed to SSH to all nodes:
```bash
TASK [Gathering Facts] ************************************************************
fatal: [control-node1]: FAILED! => {"msg": "to use the 'ssh' connection type with passwords, you must install the sshpass program"}
fatal: [worker-node1]: FAILED! => {"msg": "to use the 'ssh' connection type with passwords, you must install the sshpass program"}
fatal: [worker-node2]: FAILED! => {"msg": "to use the 'ssh' connection type with passwords, you must install the sshpass program"}
fatal: [haproxy-lb1]: FAILED! => {"msg": "to use the 'ssh' connection type with passwords, you must install the sshpass program"}
fatal: [haproxy-lb2]: FAILED! => {"msg": "to use the 'ssh' connection type with passwords, you must install the sshpass program"}
```
