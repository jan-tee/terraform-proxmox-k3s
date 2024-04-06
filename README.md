# terraform-proxmox-k3s

A module for spinning up an expandable and flexible K3s server for a lab.
Uses `bpg/terraform-provider-proxmox` (historically used the
`Telmate/terraform-provider-proxmox`, but experience with that has been
truly horrible, full of regressions over time).

## Features

- Fully automated. No need to remote into VMs to set up k3s.
- Built in and automatically configured external loadbalancer (both K3s API and ingress)
- Node pools to easily scale and to handle many kinds of workloads
- Pure Terraform - no Ansible needed.
- Support for a private Docker registry (performs local changes on each node)

## Prerequisites

- Proxmox node(s) with sufficient capacity for all nodes
- SSH agent level trust for a user `terraform` on all Proxmox nodes.
- A cloneable or template VM with a size that does not exceed the smallest node size (10G
  currently) that supports cloud-init and is based on Debian (ideally Ubuntu Server LTS)
- Static IP address ranges for nodes excluded from DHCP
- SSH agent configured for a private key to authenticate to K3s nodes

### Set up the SSH user on PVE nodes

1. In accordance with the reasons set out
   [here](https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/index.md),
   make sure to create a SSH user for this Terraform project to use on the
   Proxmox server. There are ways around this, but it is much more
   comfortable to set it up this way:
   ```bash
   sudo useradd -m terraform
   cat > /etc/sudoers.d/terraform <<EOM
   terraform ALL=(root) NOPASSWD: /sbin/pvesm
   terraform ALL=(root) NOPASSWD: /sbin/qm
   terraform ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/*
   EOM```
2. Add you SSH key to the `authorized_keys` of the `terraform` user on PVE.
3. Make this SSH key available via `ssh-agent`.

## Usage

See the [example ](example/) for details.

## Runbooks and Documents

- [Cluster example](example)
- [How to roll (update) your nodes](docs/roll-node-pools.md)
