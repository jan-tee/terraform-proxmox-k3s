locals {
  nodes = toset(flatten([
    local.master_node_ips,
    local.support_node_ip,
    local.worker_node_ips
  ]))
}

resource "null_resource" "k3s-reboot-task" {
  depends_on = [
    proxmox_virtual_environment_vm.k3s-support,
    proxmox_virtual_environment_vm.k3s-master,
    proxmox_virtual_environment_vm.k3s-worker,
    data.external.kubeconfig
  ]

  for_each = local.nodes

  connection {
    type = "ssh"
    user = "terraform"
    host = each.value
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -E shutdown -r 1"
    ]
  }
}
