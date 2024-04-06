resource "proxmox_virtual_environment_file" "cloud_image_local" {
  count = var.image.download_type == "local" ? 1 : 0
  content_type = "iso"
  datastore_id = var.image.datastore_id
  node_name    = var.cluster.target_node
  overwrite    = true

  source_file {
    # will download and store locally
    path = var.image.path
  }
}

resource "proxmox_virtual_environment_download_file" "cloud_image_url" {
  count = var.image.download_type == "url" ? 1 : 0
  content_type = "iso"
  datastore_id = var.image.datastore_id
  node_name    = var.cluster.target_node
  overwrite    = true
  overwrite_unmanaged = true

  url = var.image.path
}

locals {
  cloud_image = coalesce(one(proxmox_virtual_environment_file.cloud_image_local), one(proxmox_virtual_environment_download_file.cloud_image_url))
}