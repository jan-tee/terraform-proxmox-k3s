# Proxmox/K3s Example

This is an example project for setting up your own K3s cluster at home.

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


*Note:* To eliminate potential IP clashing with existing computers on your
network, it is **STRONGLY** recommended that you take the IP ranges out of
your DHCP server's rotation. Otherwise other computers in your network may
already be using these IPs and that will create conflicts!

Check your router's manual or google it for a step-by-step guide.

## Usage

To run this example, make sure you `cd` to this directory in your terminal,
then
1. Copy your public key to the `authorized_keys` variable in `terraform.tfvars`.
   In most cases, you should be able to get this key by running 
   `cat ~/.ssh/id_rsa.pub > authorized_keys`.
2. Make sure SSH agent is running so that the key can be used to authenticate to
   your VMs:  
   ```bash
   eval `ssh-agent`
   ssh-add ~/.ssh/id_rsa
   ```
2. Find your Proxmox API. It should look something like
   `https://192.168.0.25:8006/api2/json`. Once you found it, set the
   values to the env vars: `PM_API_URL`, `PM_API_TOKEN_ID` and
   `PM_API_TOKEN_SECRET`. It might be a good idea to put this in your shell's
   `.profile`, actually.
3. Run `terraform init` (only needs to be done the first time)
4. Run `terraform apply`
5. Review the plan. Make sure it is doing what you expect! The defaults in
   the example might be too large, and you might want to adjust IP
   addresses. Now is the time to adjust `terraform.tfvars` to accomodate.
6. Run `terraform apply` again. If all is as expected, then enter `yes` in the
   prompt and wait for your cluster to spin up.
7. Retrieve your kubecontext by running
   `config.sh my-cluster-name my-cluster-user`. Replace `my-cluster-name`
   and `my-cluster-user` with desired (arbitrary) names. These are used
   by `kubectl`, `k9s` and other Kubernetes tools to refer to this context.
8. Take the output, and run it on any system you want to use Kubernetes
   tools to access this cluster.
