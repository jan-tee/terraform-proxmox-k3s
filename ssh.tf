data "local_file" "ssh_public_key" {
  filename = var.cluster.ssh_key_path != null ? var.cluster.ssh_key_path : pathexpand("~/.ssh/id_rsa.pub")
}
