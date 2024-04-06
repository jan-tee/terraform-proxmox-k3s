resource "macaddress" "k3s-workers" {
  for_each = local.mapped_worker_nodes
}

locals {
  listed_worker_nodes = flatten([
    for pool in var.node_pools :
    [
      for i in range(pool.size) :
      merge({
          i = i
        },
          pool,
        {
          subnet = coalesce(pool.subnet, var.default_node_settings.subnet),
          node_labels = coalesce(pool.node_labels, [])
          vm_id = pool.vm_id + i
        })
    ]
  ])

  mapped_worker_nodes = {
    for node in local.listed_worker_nodes : "${node.name}-${node.i}" =>
    merge(node, {
      ip      = cidrhost(node.subnet, node.i + node.ip_offset)
      gw      = coalesce(node.gw, var.default_node_settings.gw)
      vm_id   = node.vm_id
    })
  }

  worker_node_ips = [for node in local.mapped_worker_nodes : node.ip]
}

resource "proxmox_virtual_environment_vm" "k3s-worker" {
  depends_on = [
    proxmox_virtual_environment_vm.k3s-support,
    proxmox_virtual_environment_vm.k3s-master,
  ]

  for_each = local.mapped_worker_nodes

  node_name   = coalesce(each.value.node, var.default_node_settings.node)
  name        = "${var.cluster.name}-${each.key}"
  vm_id       = each.value.vm_id


  on_boot     = coalesce(each.value.onboot, var.default_node_settings.onboot, false)
  cpu {
    cores     = coalesce(each.value.cores, var.default_node_settings.cores)
    sockets   = coalesce(each.value.sockets, var.default_node_settings.sockets)
    type      = "x86-64-v2-AES"
  }

  memory {
    dedicated = coalesce(each.value.memory, var.default_node_settings.memory)
  }

  initialization {
    datastore_id = var.cluster.cloud_config_datastore_id
    ip_config {
      ipv4 {
        address = "${each.value.ip}/${split("/", each.value.subnet)[1]}"
        gateway = "${each.value.gw}"
      }
    }
    dns {
      domain = var.default_node_settings.searchdomain
      servers = [var.default_node_settings.nameserver]
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  disk {
    datastore_id = coalesce(each.value.storage_id, var.default_node_settings.storage_id)
    file_id      = local.cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = coalesce(var.master_node_settings.disk_size, var.default_node_settings.disk_size)
  }

  network_device {
    bridge       = coalesce(each.value.network_bridge, var.default_node_settings.network_bridge)
    mac_address  = macaddress.k3s-workers[each.key].address
    vlan_id      = null # TODO coalesce(var.master_node_settings.network_tag, var.default_node_settings.network_tag, null)
  }

  agent {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      initialization[0].datastore_id,
      initialization[0].interface,
      network_device[0].disconnected,
      disk[1].file_format,
      disk[1].path_in_datastore,
      tags,
      mac_addresses,
      cpu[0].flags
    ]
  }

  connection {
    type = "ssh"
    user = "terraform"
    host = each.value.ip
  }

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/scripts/install-k3s-server.sh.tftpl", {
        mode                = "agent"
        tokens              = [random_password.k3s-server-token.result]
        alt_names           = []
        disable             = []
        server_hosts        = ["https://${local.support_node_ip}:6443"]
        node_taints         = coalesce(each.value.taints, [])
        node_labels         = coalesce(each.value.node_labels, [])
        insecure_registries = var.cluster.insecure_registries
        datastores          = []
        http_proxy          = var.cluster.http_proxy
      })
    ]
  }

}
