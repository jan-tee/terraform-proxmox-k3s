# terraform-proxmox-k3s

A module for spinning up an expandable and flexible K3s server for a lab.

## Features

- Fully automated. No need to remote into VMs.
- Built in and automatically configured external loadbalancer (both K3s API and ingress)
- Static(ish) MAC addresses for reproducible DHCP reservations
- Node pools to easily scale and to handle many kinds of workloads
- Pure Terraform - no Ansible needed.
- Support for a private Docker registry (performs local changes on each node)

## Prerequisites

- A Proxmox node with sufficient capacity for all nodes
- A cloneable or template VM with a size that does not exceed the smallest node size (10G
  currently) that supports cloud-init and is based on Debian (ideally Ubuntu Server LTS)
- Static IP address ranges for nodes excluded from DHCP
- SSH agent configured for a private key to authenticate to K3s nodes

## Usage

> Take a look at the complete auto-generated docs on the
[Official Registry Page](https://registry.terraform.io/modules/fvumbaca/k3s/proxmox/latest).

1. Set environment variables to access Proxmox VE:
   ```sh
   export PM_API_URL="https://your.proxmox.server:8006/api2/json"
   export PM_API_TOKEN_ID="<proxmox token ID>"
   export PM_API_TOKEN_SECRET="<proxmox token secret>"
   ```
1. Set up SSH trust (see [example](example))
1. Set up Terraform vars in `terraform.tfvars`.  
   Use the file from [example/](example/terraform.tfvars.sampe) as a starter.
1. Set up a `main.tf` to use the module. Edit as needed (for cluster size, node pool configuration).  
   Use the file from [example/](example/main.tf) as a starter.
1. Run `terraform plan`, `terraform apply`.
1. Retrieve the `kubeconfig` file from the terraform outputs:  
  ```sh
  terraform output -raw kubeconfig > config.yaml
  # Test out the config:
  kubectl --kubeconfig config.yaml get nodes
  ```
  or use the script provided in [example/config.sh](example/config.sh) to more easily
  export `kubectl` config.

> Make sure your support node is routable from the computer you are running the command on!

## Runbooks and Documents

- [Cluster example](example)
- [How to roll (update) your nodes](docs/roll-node-pools.md)
