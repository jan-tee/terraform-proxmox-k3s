variable "proxmox" {
 type = object({
   endpoint                = string,
   api_token               = string
 })
}

variable "image" {
  type = object({
    download_type          = optional(string, "local"),
    path                   = optional(string, "http://boot.at.home/cloudimages/jammy-server-cloudimg-amd64.img")
    datastore_id           = optional(string, "iso")
  })
}

variable "cluster" {
  type = object({
    name                      = string,
    target_node               = string,
    master_nodes_count        = number,
    api_hostnames             = optional(list(string), []),
    k3s_disable_components    = optional(list(string), []),
    http_proxy                = optional(string, ""),
    insecure_registries       = optional(list(string), []),
    ssh_key_path              = optional(string),
    cloud_config_datastore_id = optional(string, "local")
  })
}

variable "default_node_settings" {
  type = object({
    vm_id           = optional(number),
    cores           = optional(number, 2),
    sockets         = optional(number, 1),
    storage_id      = string,
    memory          = number,
    disk_size       = number,
    nameserver      = string,
    searchdomain    = string
    network_bridge  = optional(string, "vmbr0"),
    network_tag     = optional(number),
    subnet          = string,
    gw              = string,
    node     = optional(string),
    pool     = optional(string, "local-lvm")
    onboot          = optional(bool),
    boot            = optional(string, "order=virtio0")
  })
}

variable "support_node_settings" {
  type = object({
    vm_id           = optional(number),
    cores           = optional(number),
    db_name         = optional(string, "k3s"),
    db_user         = optional(string, "k3s"),
    gw              = optional(string),
    subnet          = optional(string),
    ip_offset       = optional(number),
    memory          = optional(number),
    disk_size       = optional(number),
    network_bridge  = optional(string),
    network_tag     = optional(number),
    sockets         = optional(number),
    storage_id      = optional(string),
    node     = optional(string),
    pool     = optional(string),
    onboot          = optional(bool),
    boot            = optional(string)
  })
}

variable "master_node_settings" {
  type = object({
    vm_id           = optional(number),
    cores           = optional(number),
    gw              = optional(string),
    subnet          = optional(string),
    ip_offset       = optional(number),
    memory          = optional(number),
    disk_size       = optional(number),
    network_bridge  = optional(string),
    network_tag     = optional(number),
    sockets         = optional(number),
    storage_id      = optional(string),
    node     = optional(string),
    pool     = optional(string),
    onboot          = optional(bool),
    boot            = optional(string),
    node_labels     = optional(list(string))
  })
}

variable "node_pools" {
  description = "Node pool definitions for the cluster."
  type = list(object({
    name            = string,
    size            = number,
    vm_id           = optional(number),
    taints          = optional(list(string)),
    cores           = optional(number),
    gw              = optional(string),
    subnet          = optional(string),
    ip_offset       = optional(number),
    memory          = optional(number),
    disk_size       = optional(number),
    network_bridge  = optional(string),
    network_tag     = optional(number),
    sockets         = optional(number),
    storage_id      = optional(string),
    node     = optional(string),
    pool     = optional(string),
    onboot          = optional(bool),
    boot            = optional(string),
    node_labels     = optional(list(string))
  }))
}

