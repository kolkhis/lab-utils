# Automated System Monitoring Setup with Ansible

This is a collection of playbooks that I wrote to install, configure, and deploy a
set of monitoring tools on multiple nodes simultaneously.  

These provided a batteries-included approach to setting up a monitoring solution with
minimal user input.  

This was my final project for the ProLUG Sysadmin course.  

---

## Table of Contents
- [Overview](#overview) 
- [Monitoring Stack](#monitoring-stack) 
- [How to Use These Playbooks](#how-to-use-these-playbooks) 
    - [First Time Setup](#first-time-setup) 
    - [Adding New Nodes](#adding-new-nodes) 
- [Skipping SSH Fingerprint Prompts](#skipping-ssh-fingerprint-prompts) 


## Overview

Throughout this document, I will be referring to your central monitoring hub as
"control node."  

This will be the server that hosts Grafana and the TSDBs (Prometheus, Loki).  

The playbook(s) should **only** be run from this control node.  

The playbooks can be run independently (in the `independent_playbooks` directory),
which also contains a `deploy_all.yml` playbook. This playbook will do just that,
deploy all services and agents across your inventory.  

There are playbooks for each one of the services.  

- `./playbooks/independent_playbooks/deploy_all.yml`: Deploys the whole stack 
  at once.  
    - Same as running all the playbooks listed below sequentially.  

If you are using each playbook separately, they should be run in the following order:

- `prometheus_setup_playbook.yml`
- `loki_setup_playbook.yml`
- `grafana_setup_playbook.yml`
- `node_exporter_setup_playbook.yml`
- `promtail_setup_playbook.yml`



## Monitoring Stack

This monitoring setup uses Grafana, Prometheus, Loki, Node_Exporter, and Promtail.  
- Grafana for visualizaitons.  
- Prometheus as the metrics time series database (TSDB). 
- Loki as the logging TSDB.
- Node_Exporter for collecting metrics.  
- Promtail for collecting logs.  



## How to Use These Playbooks
Provided are both independent playbooks that can be run, or roles that can be
inherited.  

These playbooks and roles use the **current machine** as the control node, 
meaning it will install Grafana, Prometheus, and Loki on whatever machine it's 
being run from.  

Node_Exporter and Promtail are installed on all nodes, including the control node.  

Always execute these roles/playbooks from the control node. Otherwise 
Prometheus service discovery won't be updated and your targets won't be scraped. 

The control node must be named `control_node` in the inventory file for the 
node_exporter role to properly append a new target to the `targets.json` file.  

To change this:

- If you're using the roles, set the `control_node_inventory_name` variable 
  in `roles/node_exporter-deploy/vars/main.yml` to your preferred control node 
  name.  

- If you're using the `deploy_all.yml` playbook, change first task "Set the control node".  

- If using the `node_exporter-deploy.yml` playbook, change the `control_node_inventory_name` 
  variable, set at the top of the file.  


### First Time Setup

There are three ways to go about deploying these services for the first time:

1. Use the `./playbooks/independent_playbooks/deploy_all.yml` playbook to set 
   up all tools on all nodes at once.  
2. Use the `deploy_all_roles.yml` to execute each role.  
3. Use each playbook to install each tool individually.  

Option 1 is preferred (fully tested).  

```bash
ansible-playbook -i hosts.ini deploy_all.yml -K 
```

Your `hosts.ini` file (or other inventory filename) can be formatted however you
prefer, since the playbook(s) only use the `localhost` and `all` groups.  

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

### Using the Provided Script
I've provided a script that will parse your Ansible inventory file, or SSH
configuration file, to then add all of the remote host's SSH fingerprints to
your `known_hosts` file.  

Simply run:
```bash
./add-ssh-fingerprints -i ./hosts.ini
```
To see a full list of options:
```bash
./add-ssh-fingerprints --help
```
If you prefer to add them manually, use `ssh-keyscan` (see below). 

---
### Using `ssh-keyscan`

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








