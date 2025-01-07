# Automated System Monitoring Setup with Ansible

This is a collection of playbooks that I wrote to install, configure, and deploy a
set of monitoring tools on multiple nodes simultaneously.  

These provided a batteries-included approach to setting up a monitoring solution with
minimal user input.  

This was my final project for the ProLUG Sysadmin course.  

## Table of Contents
* [Monitoring Stack](#monitoring-stack) 
* [How to Use These Playbooks](#how-to-use-these-playbooks) 
    * [First Time Setup](#first-time-setup) 
    * [Adding New Nodes](#adding-new-nodes) 

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









