module "k3s" {
  # source  = "github.com/jan-tee/terraform-proxmox-k3s"
  source = "../"

  proxmox = {
    endpoint = var.pm_api_url
    api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  }

  cluster = {
    name                   = "bart"        # K8s cluster name
    target_node            = "laszlo"      # PVE target node name
    master_nodes_count     = 2
    insecure_registries    = [ "registry.k8s.lab", "registry.at.home", "registry.customer.lab" ]

    # Disable default traefik and servicelb installs for metallb and traefik 2
    k3s_disable_components = [ "traefik", "servicelb" ]
  }

  image = { }

  default_node_settings = {
    nameserver   = "10.10.0.1"
    searchdomain = "k8s.lab"
    node  = "laszlo"
    pool  = "k8s"
    disk_size    = 30
    memory       = 4096
    storage_id   = "vms-01"
    subnet       = "10.10.0.0/16"
    gw           = "10.10.0.1"
    ciuser       = "terraform"
    network_bridge = "vmbr0"
  }

  support_node_settings = {
    vm_id      = 4000,
    ip_offset = 10 * 256 + 100
    memory    = 2048
  }

  master_node_settings = {
    vm_id      = 4001,
    count     = 2
    ip_offset = 10 * 256 + 101
    memory    = 2048
  }

  node_pools           = [
    {
      vm_id      = 4010,
      name      = "small"
      cores     = 2
      size      = 0
      disk_size = 20 
      ip_offset = 10 * 256 + 110
      memory    = 4096
      node_labels = [ "tietze.io/instance-type=small" ]
    },
    {
      vm_id      = 4040,
      name      = "large"
      cores     = 4
      size      = 0
      disk_size = 20
      ip_offset = 10 * 256 + 150
      memory    = 10000
      node_labels = [ "tietze.io/instance-type=large" ]
    },
    {
      vm_id      = 4080,
      node = "laszlo"
      name      = "x-small"
      cores     = 4
      size      = 1
      disk_size = 20
      ip_offset = 20 * 256 + 1
      memory    = 2048
      node_labels = [ "tietze.io/instance-type=x-small" ]
    }
  ]
}

output "kubeconfig" {
  value     = module.k3s.k3s_kubeconfig
  sensitive = true
}
