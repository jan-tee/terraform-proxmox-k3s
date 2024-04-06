# Proxmox/k3s Example

This is an example project for setting up a k3s cluster on VMs in Proxmox.

## Requirements

This requires Terraform 1.7.5+.

## Summary

### VMs

This will spin up:

- 1 support VM with API load balancer and k3s database with 2 cores and 4 GB
  RAM
- 2 master nodes with 2 cores and 4 GB mem
- 1 node pool with 25 worker nodes each having 2 cores and 2 GB mem
- 1 node pool with 2 worker nodes each having 4 cores and 10 GB mem

### Networking

*Note:* To avoid conflicts with other computers on your network, make soure to
exclude the IP ranges in your DHCP server.

## Usage

To run this example, copy the content of the `example` directory to its new,
permanent home that will also keep Terraform state files for the lifetime of
your cluster. Like with all Terraform projects, make sure you keep this
permanently.

1. Edit `main.tf` to reflect your desired settings, e.g.
   - desired subnet and DNS details
   - VM ID ranges and IP offsets for support (DB) node, master nodes, worker pools
   - sizing defaults for VMs
   - sizing of master, support, and worker pools
1. If you want to use a different SSH key for the created VMs than
   `~/.ssh/id_rsa.pub`, set `cluster.ssh_key_path`.
1. Make sure SSH agent is running so that this same key can be used to authenticate to
   your VMs. It _may_ be a good idea, if you are runnig this on a permanent
   "admin" VM, to add this to your `~/.profile` as well:  
   ```bash
   eval `ssh-agent`
   ssh-add ~/.ssh/id_rsa
   ```
1. Find your Proxmox API URL. It should look something like
   `https://192.168.0.25:8006/api2/json`. Once you found it, set the
   values to the env vars: `TF_VAR_pm_api_url`, `TF_VAR_pm_api_token_id` and
   `TF_VAR_pm_api_token_secret`.  
   It may be a good idea to put this in your shell's `.profile`, too.
1. Run `terraform init`  
   This will download the required dependencies, such as this module.
1. Run `terraform plan`
1. Review the plan. Make sure it is doing what you expect! The defaults in
   the example might be too large, and you might want to adjust IP
   addresses. _Now_ is the time to adjust `terraform.tfvars` to accomodate
   any changes you want to make.
1. Run `terraform apply`.  
   If all is as expected, then enter `yes` in the
   prompt and wait for your cluster to spin up.
1. If all went well, you can run `./config.sh <arbitrary name for your cluster> <arbitrary name for your user>`
   and it will output the `kubectl` commands you can use to create
   the context to connect to this cluster on any platform that runs
   `kubectl`.
