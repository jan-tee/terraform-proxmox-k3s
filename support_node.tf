resource "macaddress" "k3s-support" {
}

resource "random_id" "cloud-config-k3s-support" {
  byte_length = 16
}

# cloud_config file
resource "proxmox_virtual_environment_file" "cloud-config-k3s-support" {
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

hostname: "${join("-", [var.cluster.name, "support"])}"
fqdn: "${join("-", [var.cluster.name, "support"])}.${coalesce(var.support_node_settings.domain, var.default_node_settings.domain)}"
prefer_fqdn_over_hostname: true

write_files:
  - encoding: b64
    content: ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIA0KIEBAQEBAQCAgIEBAQCAgQEBAICBAQEAgIEBAQEBAQEBAICAgQEBAQEBAICAgIEBAQEBAQCAgIEBAQEBAQEBAQEAgICBAQEBAQ
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
    file_name = "cloud-config-${join("-", [var.cluster.name, "support"])}-${random_id.cloud-config-k3s-support.hex}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "k3s-support" {
  node_name   = coalesce(var.support_node_settings.node, var.default_node_settings.node)
  name        = join("-", [var.cluster.name, "support"])
  vm_id       = var.support_node_settings.vm_id

  on_boot     = coalesce(var.support_node_settings.onboot, var.default_node_settings.onboot, false)
  cpu {
    cores     = coalesce(var.support_node_settings.cores, var.default_node_settings.cores)
    sockets   = coalesce(var.support_node_settings.sockets, var.default_node_settings.sockets)
    type      = "x86-64-v2-AES"
  }

  memory {
    dedicated = coalesce(var.support_node_settings.memory, var.default_node_settings.memory)
  }

  initialization {
    datastore_id = var.cluster.cloud_config_datastore_id
    ip_config {
      ipv4 {
        address = "${local.support_node_ip}/${split("/", local.support_node_subnet)[1]}"
        gateway = "${local.gw}"
      }
    }
    dns {
      domain = var.default_node_settings.searchdomain
      servers = [var.default_node_settings.nameserver]
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud-config-k3s-support.id
  }

  disk {
    datastore_id = coalesce(var.support_node_settings.storage_id, var.default_node_settings.storage_id)
    file_id      = local.cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = coalesce(var.support_node_settings.disk_size, var.default_node_settings.disk_size)
  }

  network_device {
    bridge       = coalesce(var.support_node_settings.network_bridge, var.default_node_settings.network_bridge)
    mac_address  = upper(macaddress.k3s-support.address)
    vlan_id      = null # TODO coalesce(var.support_node_settings.network_tag, var.default_node_settings.network_tag, null)
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
    host = local.support_node_ip
  }

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/scripts/install-support.sh.tftpl", {
        root_password = random_password.support-db-password.result

        k3s_database = var.support_node_settings.db_name
        k3s_user     = var.support_node_settings.db_user
        k3s_password = random_password.k3s-master-db-password.result

        http_proxy = var.cluster.http_proxy
      })
    ]
  }
}

# output "vm_ipv4_address" {
#   value = proxmox_virtual_environment_vm.k3s-support.ipv4_addresses[1][0]
# }

resource "random_password" "support-db-password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

resource "random_password" "k3s-master-db-password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

resource "null_resource" "k3s_nginx_config" {
  depends_on = [
    proxmox_virtual_environment_vm.k3s-support
  ]

  triggers = {
    config_change = filemd5("${path.module}/config/nginx.conf.tftpl")
  }

  connection {
    type = "ssh"
    user = "terraform"
    host = local.support_node_ip
  }

  provisioner "file" {
    destination = "/tmp/nginx.conf"
    content = templatefile("${path.module}/config/nginx.conf.tftpl", {
      k3s_server_hosts = [for ip in local.master_node_ips :
        "${ip}:6443"
      ]
      k3s_nodes = concat(local.master_node_ips, [
        for node in local.mapped_worker_nodes :
        node.ip
      ])
    })
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo systemctl restart nginx.service",
    ]
  }
}
