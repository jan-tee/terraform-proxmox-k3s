resource "macaddress" "k3s-workers" {
  for_each = local.mapped_worker_nodes
}

resource "random_id" "cloud-config-k3s-worker" {
  for_each = local.mapped_worker_nodes
  byte_length = 16
}

# cloud_config file
resource "proxmox_virtual_environment_file" "cloud-config-k3s-worker" {
  for_each = local.mapped_worker_nodes

  content_type = "snippets"
  datastore_id = var.cluster.cloud_config_datastore_id
  node_name    = var.cluster.target_node

  source_raw {
    data = <<EOF
#cloud-config
users:
  - default
  - name: terraform
    groups:
      - sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ${trimspace(data.local_file.ssh_public_key.content)}
    sudo: ALL=(ALL) NOPASSWD:ALL
timezone: Europe/Berlin
hostname: "${each.key}"
fqdn: "${var.cluster.name}-${each.key}.${coalesce(each.value.domain, var.default_node_settings.domain)}"
write_files:
  - encoding: b64
    content: ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIA0KIEBAQEBAQCAgIEBAQCAgQEBAICBAQEAgIEBAQEBAQEBAICAgQEBAQEBAICAgIEBAQEBAQCAgIEBAQEBAQEBAQEAgICBAQEBAQEBAQCAgQEBAICBAQEAgIEBAQEBAQEBAICAgQEBAQEBAICAgIEBAQEBAQCAgIA0KQEBAQEBAQEAgIEBAQCAgQEBAICBAQEAgIEBAQEBAQEBAICBAQEBAQEBAICAgQEBAQEBAQEAgIEBAQEBAQEBAQEBAICBAQEBAQEBAQCAgQEBAQCBAQEAgIEBAQEBAQEBAICBAQEBAQEBAICAgQEBAQEBAQCAgIA0KQEAhICBAQEAgIEBAISAgQEAhICBAQCEgIEBAISAgICAgICAhQEAgICAgICAgQEAhICBAQEAgIEBAISBAQCEgQEAhICBAQCEgICAgICAgQEAhQCFAQEAgIEBAISAgICAgICAhQEAgICAgICAgIUBAICAgICAgIA0KIUAhICBAIUAgICFAISAgIUAhICAhQCEgICFAISAgICAgICAhQCEgICAgICAgIUAhICBAIUAgICFAISAhQCEgIUAhICAhQCEgICAgICAgIUAhIUAhQCEgICFAISAgICAgICAhQCEgICAgICAgIUAhICAgICAgIA0KQCFAIUAhQCEgIEAhISAgISFAICBAIUAgIEAhISE6ISAgICAhIUBAISEgICAgQCFAICAhQCEgIEAhISAhIUAgQCFAICBAISEhOiEgICAgQCFAICEhQCEgIEAhISE6ISAgICAhIUBAISEgICAgISFAQCEhICAgIA0KISEhQCEhISEgICFAISAgISEhICAhQCEgICEhISEhOiAgICAgISFAISEhICAgIUAhICAhISEgICFAISAgICEgIUAhICAhISEhITogICAgIUAhICAhISEgICEhISEhOiAgICAgISFAISEhICAgICEhQCEhISAgIA0KISE6ICAhISEgICEhOiAgISE6ICAhITogICEhOiAgICAgICAgICAgICE6ISAgISE6ICAhISEgICEhOiAgICAgISE6ICAhITogICAgICAgISE6ICAhISEgICEhOiAgICAgICAgICAgICE6ISAgICAgICAhOiEgIA0KOiE6ICAhOiEgIDohOiAgOiE6ICA6ITogIDohOiAgICAgICAgICAgITohICAgOiE6ICAhOiEgIDohOiAgICAgOiE6ICA6ITogICAgICAgOiE6ICAhOiEgIDohOiAgICAgICAgICAgITohICAgICAgICE6ISAgIA0KOjogICA6OjogICA6Ojo6IDo6IDo6OiAgICA6OiA6Ojo6ICA6Ojo6IDo6ICAgOjo6OjogOjogIDo6OiAgICAgOjogICAgOjogOjo6OiAgIDo6ICAgOjogICA6OiA6Ojo6ICA6Ojo6IDo6ICAgOjo6OiA6OiAgIA0KIDogICA6IDogICAgOjogOiAgOiA6ICAgIDogOjogOjogICA6OiA6IDogICAgIDogOiAgOiAgICA6ICAgICAgOiAgICA6IDo6IDo6ICAgOjogICAgOiAgIDogOjogOjogICA6OiA6IDogICAgOjogOiA6
    owner: root:root
    path: /etc/motd
    permissions: "0644"

packages:
  - qemu-guest-agent
  - net-tools
package_upgrade: true
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  - apt update
  - apt upgrade -y
  - echo "done" > /tmp/cloud-config.done
EOF
    file_name = "cloud-config-${each.key}-${random_id.cloud-config-k3s-worker[each.key].hex}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "k3s-worker" {
  depends_on = [
    proxmox_virtual_environment_vm.k3s-support,
    proxmox_virtual_environment_vm.k3s-master,
  ]

  for_each = local.mapped_worker_nodes

  node_name   = coalesce(each.value.node, var.default_node_settings.node)
  name        = each.key
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
    user_data_file_id = proxmox_virtual_environment_file.cloud-config-k3s-worker[each.key].id
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
