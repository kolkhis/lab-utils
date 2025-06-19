# Chroot Jail Setup Scripts

These are a collection of scripts that will configure a chroot jail on a Linux system
to act as a bastion/jumpbox.  

## Overview

This script sets up:

- A jailed user account with `chroot` restrictions
- A restricted environment at `/var/chroot`
- A custom shell for SSH forwarding
- A parsed list of destinations from an SSH config file
- SSH key fingerprints for those destinations

The setup script is self-documenting. Run `./setup-chroot-jail --help` for usage.  


## Basic Usage

To set up the chroot jail, use the `setup-chroot-jail` script:
```bash
./setup-chroot-jail
# or, for verbose output
./setup-chroot-jail -v
```
This can be run without any arguments to use all default values. E.g., the chroot
directory will be `/var/chroot` and the jailed user will be named `juvie`.  

It will also parse your `~/.ssh/config` file for destinations to present to the user
as options when SSHing into that machine as that user.  

This will prompt you for a password for the new user, and everything will be
configured.  

> Note: The `./generate-destinations` script is a helper script used to generate
> destinations from your SSH config file. It does not need to be run separately.  

---

If you want to remove the `chroot` jail from your system, you can use the
`reset-chroot-jail` script.  
```bash
./reset-chroot-jail
```

This will remove the `/var/chroot` directory as well as the jailed user account.  

> Note: This will not remove the `Match` rule in `/etc/ssh/sshd_config`. This needs
> to be removed manually (for now).  


## Advanced Usage

If you want your jail to be located somewhere other than `/var/chroot`, or if you
want to use a different name for your jailed user, you can specify those options to
`setup-chroot-jail`.  

```bash
./setup-chroot-jail --chroot-dir /var/jail --jailed-user admin
```

This will create your jail at `/var/jail` instead of `/var/chroot`, and will give
your jailed user the name `admin` instead of `juvie`.  

The short options for these are `-c` and `-u` (respectively).  

These same options are available for the `reset-chroot-jail` script.  

For a full list of available options, use:
```bash
./setup-chroot-jail --help
```

---

## Synopsis

This synopsis is printed to the terminal when run with `./setup-chroot-jail --help`: 

```text
Usage: ./setup-chroot-jail [OPTIONS]

Automates the creation of a chroot jail and SSH-based bastion host.

Options:
  -c, --chroot-dir <DIR>         Specify the chroot jail directory (default: /var/chroot)
  -u, --jailed-user <USER>       Username to create inside the chroot jail (default: juvie)
  -v, --verbose                  Enable verbose debug output
  -s, --bastion-script <SCRIPT>  Path to the custom bastion shell script to install (default: ./bastion.sh)
  -S, --ssh-config-file <FILE>   Path to SSH config file to parse for destination targets (default: ~/.ssh/config)
  -h, --help                     Show this help message and exit

This script sets up:
  - A jailed user account with chroot restrictions
  - A restricted environment at /var/chroot
  - A custom shell for SSH forwarding
  - A parsed list of destinations
  - SSH key fingerprints for those destinations

```


