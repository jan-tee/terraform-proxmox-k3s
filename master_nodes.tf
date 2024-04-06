resource "macaddress" "k3s-masters" {
  count = var.cluster.master_nodes_count
}

locals {
  master_node_subnet = coalesce(var.master_node_settings.subnet, var.default_node_settings.subnet)
  master_node_ips    = [for i in range(var.cluster.master_nodes_count) : cidrhost(local.master_node_subnet, i + var.master_node_settings.ip_offset)]
}

resource "random_password" "k3s-server-token" {
  length           = 32
  special          = false
  override_special = "_%@"
}

data "external" "kubeconfig" {
  depends_on = [
    proxmox_virtual_environment_vm.k3s-support,
#   proxmox_virtual_environment_vm.k3s-master
  ]

  program = [
    "/usr/bin/ssh",
    "-o UserKnownHostsFile=/dev/null",
    "-o StrictHostKeyChecking=no",
    "terraform@${local.master_node_ips[0]}",
    "echo '{\"kubeconfig\":\"'$(sudo cat /etc/rancher/k3s/k3s.yaml | base64)'\"}'"
  ]
}

resource "proxmox_virtual_environment_vm" "k3s-master" {
  count       = var.cluster.master_nodes_count

  node_name   = coalesce(var.master_node_settings.node, var.default_node_settings.node)
  name        = "${var.cluster.name}-master-${count.index}"
  vm_id       = var.master_node_settings.vm_id + count.index

  on_boot     = coalesce(var.master_node_settings.onboot, var.default_node_settings.onboot, false)
  cpu {
    cores     = coalesce(var.master_node_settings.cores, var.default_node_settings.cores)
    sockets   = coalesce(var.master_node_settings.sockets, var.default_node_settings.sockets)
    type      = "x86-64-v2-AES"
  }

  memory {
    dedicated = coalesce(var.master_node_settings.memory, var.default_node_settings.memory)
  }

  initialization {
    datastore_id = var.cluster.cloud_config_datastore_id
    ip_config {
      ipv4 {
        address = "${local.master_node_ips[count.index]}/${split("/", local.master_node_subnet)[1]}"
        gateway = "${local.gw}"
      }
    }
    dns {
      domain = var.default_node_settings.searchdomain
      servers = [var.default_node_settings.nameserver]
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  disk {
    datastore_id = coalesce(var.master_node_settings.storage_id, var.default_node_settings.storage_id)
    file_id      = local.cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = coalesce(var.master_node_settings.disk_size, var.default_node_settings.disk_size)
  }

  network_device {
    bridge       = coalesce(var.master_node_settings.network_bridge, var.default_node_settings.network_bridge)
    mac_address  = upper(macaddress.k3s-masters[count.index].address)
    vlan_id      = null # TODO coalesce(var.master_node_settings.network_tag, var.default_node_settings.network_tag, null)
  }

  agent {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      initialization[0].datastore_id,
      initialization[0].interface,
    ]
  }

  connection {
    type = "ssh"
    user = "terraform"
    host = local.master_node_ips[count.index]
  }

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/scripts/install-k3s-server.sh.tftpl", {
        mode                = "server"
        tokens              = [random_password.k3s-server-token.result]
        alt_names           = concat([local.support_node_ip], var.cluster.api_hostnames)
        server_hosts        = []
        node_taints         = ["CriticalAddonsOnly=true:NoExecute"]
        node_labels         = coalesce(var.master_node_settings.node_labels, [])
        insecure_registries = var.cluster.insecure_registries
        disable             = var.cluster.k3s_disable_components
        datastores = [{
          host     = "${local.support_node_ip}:3306"
          name     = var.support_node_settings.db_name
          user     = var.support_node_settings.db_user
          password = random_password.k3s-master-db-password.result
        }]
        http_proxy = var.cluster.http_proxy
      })
    ]
  }
}
