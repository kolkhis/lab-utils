# Ubuntu Patching with Ansible

Contained is a set of roles used in a playbook to patch Ubuntu servers to the
latest versions of packages.  

## Inventory

This patching playbook relies on two separate inventories containing two distinct groups:

- `production`
- `non_production`  

The inventory provided should contain **a single one** of these groups.  

> **NOTE:** For added safety, it is recommended to use two separate inventory 
> files for prod and non-prod hosts.  
> The separate inventories should still contain the `production` and
> `non_production` host groups.  

For instance, `./inventories/prod.ini` for production and
`./inventories/dev.ini` for non-production. 

Example `prod.ini` inventory:
```ini
[production]
prod-server1 ansible_hostname=192.168.1.100
prod-server2 ansible_hostname=192.168.1.101
prod-server3 ansible_hostname=192.168.1.102
```

Example `dev.ini` file:
```ini
[non_production]
nonprod-server1 ansible_hostname=192.168.1.103
nonprod-server2 ansible_hostname=192.168.1.104
nonprod-server3 ansible_hostname=192.168.1.105
```

Supply these inventories at runtime with the `-i` option.  

## Tags

This playbook uses inventory group names to determine whether or not to run 
certain runtime tasks, as well as perform safety checks and automatic failures.  

There are a few tags available to modify the behavior of the play.  
Available tags:

- `reboot`: Will reboot **non-production** hosts if supplied.  
    - Production hosts will never be rebooted.  
- `dry_run`: Skip the `apt update`, `autoremove`, `autoclean`, and `upgrade` tasks, and skip `reboot` tasks.  
    - If the `reboot` tag is provided alongside the `dry_run` tag, no reboots will occur.  

## Invocation

If running against non-production servers, these servers should be in the
`non_production` group in the inventory.  
```bash
ansible-playbook -i inventories/dev.ini patch.yml -K
```

- The `-K`/`--ask-become-pass` is needed only if not using other methods of
  [secret management](#secret-management) for storing the `become` password.  


Likewise, if running against production servers, supply an inventory with the `production` group.
```bash
ansible-playbook -i inventories/prod.ini patch.yml -K
```

Pass the `dry_run` tag for dry run functionality (will not update apt cache or
install new updates, but will still produce logs).  
```bash
# Dry run on dev servers
ansible-playbook -i inventories/dev.ini patching.yml --tags dry_run

# Dry run on prod servers
ansible-playbook -i inventories/prod.ini patching.yml --tags dry_run
```

If reboot functionality is desired (non-prod), use the `reboot` tag on invocation.  
```bash
# Patch and reboot dev servers
ansible-playbook -i inventories/dev.ini patching.yml --tags reboot
```


## Reboot Logic

By default, this playbook will *not* reboot hosts.  
To reboot hosts, supply the `reboot` tag at runtime.  

If the `reboot` tag is provided, the playbook will reboot **non-production hosts only**. 

Production servers that need a reboot will show up in the post-patch report, as
well as roduce output at runtime.  

**All** hosts that require a reboot will show up in the post-patch report.  


## Roles

This playbook inherits the following roles (in this order):

- `precheck`: Perform check on inventory, check for proper group name
  (`production` or `non_production`).  
    - This will cause the play to fail if certain conditions are met.  
    - Failure conditions:
        - Neither the `production` nor `non_production` groups are defined.  
        - Targeting both the `production` and `non_production` groups at the same time.  
        - Targeting an empty inventory.

- `patch`: The actual patching logic. Updates packages on the remote host.  
    - Locks the packages listed in the `lock_package_list` variable, performs
      updates, then unlocks them.  
    - This temporarily disables the `unattended-upgrades` service to help prevent
      any errors with `dpkg` being in use (locked).  
        - **Note**: There are other mechanisms in place that may keep `dpkg`
          busy. If an error is thrown on package lock, cache update, or package
          upgrade, try it again after a few minutes. 

- `reboot`: Set variable `reboot_required` for each host (used in post-patch report).  
    - **If the `reboot` tag is passed**, additionally reboot non-production hosts.  
    - This role **will not reboot production hosts**, and **will not reboot
      *any* hosts if the `reboot` tag is not passed**.  

- `report`: Pull down remote logs to Ansible control node and generate a
  post-patch report.  

These roles rely on the variables set inside the `patch.yml` playbook.  

## Variables

There are four variables that must be set in the parent playbook.

The defaults, as specified in `patch.yml`:
```yaml
  vars:
    log_directory: "/var/log/patching"
    local_log_directory: "./log/patching"
    log_file: "{{ log_directory }}/ansible_patching_{{ ansible_date_time.date }}.log"
    lock_package_list:
      - kernel  # Specific kernel version will be calculated at runtime
      - postgresql
```
These can be left as-is, or customized. 

- The `log_directory` controls where logs will be located on the remote host.  

- The `local_log_directory` is where the logs will be copied into, and will 
  also be where the post-patch report is stored.  

- The `log_file` is the name of the log file on the remote host.  

- The `lock_package_list` list is used to exclude certain packages from upgrading
  when the system is patched.  
    - The `kernel` element in this list will be replaced with the **signed
      kernel package currently installed on the remote host**.  
      This entry, if present, will expand to:
      ```bash
      linux-image-$(uname -r)
      ```
      For example, `linux-image-5.15.0-164-generic`.  
    - Packages will be locked inside the `lock_packages` role before the patch
      process begins, and will be unlocked in the `unlock_packages` role.  


## Post-Patch Report

The playbook will produce a post-patch report once completed.  

This report will be generated in `./log/patching/` (or whichever destination
the `local_log_directory` variable points to).  
It will be named `patch_report_<TYPE>_<DATE>`, where `<TYPE>` is either `prod` or
`nonprod`, and the date is formatted as `YYYY-MM-DD` (e.g., `patch_report_prod_2026-01-12.txt`).  

This report will contain the following information regarding the patch cycle:

- Date
- Group that was targeted (production/non_production)
- Excluded packages
- Number and list of servers patched  
- Number and list of unreachable servers (hostname/IP)  
- List of production servers that require reboot (when run against the `production` group)  
- List of non-production servers that require reboot (when run against the `non_production` group)  

Each host will be listed by their `inventory_hostname`, followed by their IPv4
address (if available). This may appear as the node's IP address twice if the
`inventory_hostname` is the same as the IP.  

The format of the report can be edited in `./roles/report/templates/report.j2`.  

## Logs

This playbook generates logs on **each host** that is patched.  

The play logs when the patch cycle begins, the number of packages to be
updated, and when the patch cycle ends.  

These logs are generated in the `/var/log/patching` directory on the remote host.  
The logs from each host are additionally copied to the Ansible control node in
the same location as the post-patch report, into subdirectories named according
to the remote host's hostname.  

It is recommended to push out a logrotate configuration to each of the nodes
that are managed by this patching playbook.  

An example logrotate config, `/etc/logrotate.d/patching`:
```conf
/var/log/patching/*.log {
    weekly
    rotate 4
    missingok
    notifempty
    compress
    delaycompress
    dateext
    dateformat -%Y%m%d
    copytruncate
    create 0640 root adm
    su root adm
}
```
This configuration will rotate once per week and keep 4 weeks worth of logs
compressed.  


## Additional Notes

### Note on Ansible Version
When running Ansible playbooks against Ubuntu 24+, the Ansible version **must** 
be over 2.10 (>= ~2.11/2.12).  
Older versions of Ansible expect the `six` module to exist within Python.  
Ubuntu 24+ ships with Python 3.12, which removed the `six` module.  

### Secret Management

The `become_pass` should not be hardcoded in vars.  

Avoid this in one of two ways:

1. Invoke Ansible with `-K`/`--ask-become-pass` if running patch job manually.  

2. Use Ansible Vault or Hashicorp Vault to store the `become` password and
   fetch programmatically.  
    - This is a good resource: <https://eengstrom.github.io/musings/ansible-sudo-var>

Recommendation: 

- Store `ansible_become_pass` in an encrypted vars file (group_vars/host_vars or a dedicated credentials.yml) using ansible-vault encrypt.
- Load it via `vars_files` or `-e @secrets.enc`, and provide the vault password 
  non‑interactively using a `--vault-password-file` for cron/CI runners with tight 
  file permissions (`0600`).

