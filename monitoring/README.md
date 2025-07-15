# Automated System Monitoring Setup with Ansible

This is a collection of playbooks that I wrote to install, configure, and deploy a
set of monitoring tools on multiple nodes simultaneously.  

These provided a batteries-included approach to setting up a monitoring solution with
minimal user input.  

This was my final project for the ProLUG Sysadmin course.  

---


## Table of Contents
* [Monitoring Stack](#monitoring-stack) 
* [How to Use These Playbooks](#how-to-use-these-playbooks) 
    * [First Time Setup](#first-time-setup) 
    * [Adding New Nodes](#adding-new-nodes) 

## Overview

Throughout this document, I will be referring to your central monitoring hub as
"control node."  

This will be the server that hosts Grafana and the TSDBs (Prometheus, Loki).  

The playbook(s) should **only** be run from this control node.  

The playbooks can be run independently (in the `independent_playbooks` directory),
which also contains a `deploy_all.yml` playbook. This playbook will do just that,
deploy all services and agents across your inventory.  

There are playbooks for each one of the services.  

- `deploy_all.yml`: Deploys the whole stack at once. Same as running all the
  playbooks listed below sequentially.  

If you are using each playbook separately, they should be run in this order:

- `prometheus_setup_playbook.yml`
- `loki_setup_playbook.yml`
- `grafana_setup_playbook.yml`
- `node_exporter_setup_playbook.yml`
- `promtail_setup_playbook.yml`



## Monitoring Stack

This monitoring setup uses Grafana, Prometheus, Loki, Node_Exporter, and Promtail.  
* Grafana for visualizaitons.  
* Prometheus as the metrics time series database (TSDB). 
* Loki as the logging TSDB.
* Node_Exporter for collecting metrics.  
* Promtail for collecting logs.  



## How to Use These Playbooks
These playbooks use the **current machine** as the control node, meaning it will 
install Grafana, Prometheus, and Loki on whatever machine it's being run from.  

Node_Exporter and Promtail are installed on all nodes, including the control node.  

Always run from the control node. Otherwise Prometheus service discovery won't be updated and your targets won't be scraped. 

The control node must be named `control_node` in the inventory file for the node_exporter role
to properly append a new target to the `targets.json` file.  
To change this, set the `control_node_inventory_name` variable in `roles/node_exporter-deploy/vars/main.yml` to your preferred control node name.  


### First Time Setup
There are two ways to go about this:
1. Use each playbook to install each tool individually.  
2. Use the `deploy_all.yml` playbook to set up all tools on all nodes at once.  
Option 2 is preferred.  

```bash
ansible-playbook -i hosts.ini deploy_all.yml -K 
```
Your `hosts.ini` file (or `hosts.yml`, or whatever) can be formatted however you
prefer, since the playbook only uses the `localhost` and `all` groups.  

### Adding New Nodes
The plays to install Grafana/Prometheus/Loki are tagged with `control`.  

The plays for installing Node_Exporter and Promtail are tagged with `collector`.  


If you just want to add Node_Exporter and Promtail to new nodes in your inventory, use the tags.  
* Note: Reminder to always run these from the control node. 
```bash
# Skip installing Grafana/Prometheus/Loki, only install Node_Exporter/Promtail
ansible-playbook -i hosts.ini -K deploy_all.yml --skip-tags=control
# or
ansible-playbook -i hosts.ini -K deploy_all.yml --tags=collector
```


## Skipping SSH Fingerprint Prompts

If you've never used your control node to SSH into a new node yet, you can use
`ssh-keyscan` to grab the host's fingerprint and append it to the
`~/.ssh/known_hosts` file.  

For example:
```bash
for ip in {101..105}; do
    ssh-keyscan -H 192.168.4.$ip >> ~/.ssh/known_hosts
done
```
That will take the range `192.168.4.101-105` and get the fingerprints of all those
hosts and append them to the `known_hosts` file, preventing you from being prompted
to type `yes`.   

As a one-liner:
```bash
for ip in {101..105}; do ssh-keyscan -H 192.168.4.$ip >> ~/.ssh/known_hosts; done
```








