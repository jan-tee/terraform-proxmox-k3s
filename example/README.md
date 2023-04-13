# Proxmox/K3s Example

This is an example project for setting up a K3s cluster on VMs in Proxmox.

## Requirements

This requires Terraform 1.30+.

## Summary

### VMs

This will spin up:

- 1 support VM with API load balancer and k3s database with 2 cores and 4 GB
  RAM
- 2 master nodes with 2 cores and 4 GB mem
- 1 node pool with 25 worker nodes each having 2 cores and 2 GB mem
- 1 node pool with 2 worker nodes each having 4 cores and 10 GB mem

### Networking

- The support VM will be spun up on `10.10.10.1`
- The master VMs will be spun up on `10.10.10.2.`, `10.10.3`
- The worker VMs in pool `small` will be spun up on `10.10.10.10` ... `10.10.10.34`
- The worker VMs in pool `large` will be spun up on `10.10.10.100` ...
  `10.10.10.101`

*Note:* To avoid conflicts with other computers on your network, make soure to
exclude these IP ranges in your DHCP server.

## Usage

To run this example, copy the content of the `example` directory to its new,
permanent home that will also keep Terraform state files for the lifetime of
your cluster. Like with all Terraform projects, make sure you keep this
permanently.

1. Copy `terraform.vars.sample` to `terraform.vars`. Edit it to reflect your
   desired settings
1. Copy your public key to the `authorized_keys` variable in `terraform.tfvars`.
   In most cases, you should be able to get this key by running
   `cat ~/.ssh/id_rsa.pub`.
1. Make sure SSH agent is running so that the key can be used to authenticate to
   your VMs. It _may_ be a good idea, if you are runnig this on a permanent
   "admin" VM, to add this to your `~/.profile` as well:  
   ```bash
   eval `ssh-agent`
   ssh-add ~/.ssh/id_rsa
   ```
1. Find your Proxmox API URL. It should look something like
   `https://192.168.0.25:8006/api2/json`. Once you found it, set the
   values to the env vars: `PM_API_URL`, `PM_API_TOKEN_ID` and
   `PM_API_TOKEN_SECRET`.  
    It might be a good idea to put this in your shell's `.profile`, too.
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
1. If all went well, you can run `./config.sh <cluster name> <user name>`
   and it will output the `kubectl` commands you can use to create
   the context to connect to this cluster on any platform that runs
   `kubectl`.
