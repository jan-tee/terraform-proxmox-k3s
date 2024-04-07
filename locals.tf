locals {
  listed_worker_nodes = flatten([
    for pool in var.node_pools :            # for each pool...
    [
      for i in range(pool.size) :           # ...for each node in the pool to be generated...
      merge({
          i = i                             # create a map that has i = index,
        },
          pool,                             # all the data from "pool",
        {
          subnet = coalesce(pool.subnet, var.default_node_settings.subnet), # a "subnet" property,
          node_labels = coalesce(pool.node_labels, [])                      # the node label
          vm_id = pool.vm_id + i                                            # a calculated VM id
        })
    ]
  ])

  # and turn that into a flat collection of the properties, and calculate the IP
  mapped_worker_nodes = {
    for node in local.listed_worker_nodes : "${var.cluster.name}-${node.name}-${node.i}" =>
    merge(node, {
      ip      = cidrhost(node.subnet, node.i + node.ip_offset)
      gw      = coalesce(node.gw, var.default_node_settings.gw)
      vm_id   = node.vm_id
    })
  }

  worker_node_ips = [for node in local.mapped_worker_nodes : node.ip]
}

locals {
  master_node_subnet = coalesce(var.master_node_settings.subnet, var.default_node_settings.subnet)
  master_node_ips    = [for i in range(var.cluster.master_nodes_count) : cidrhost(local.master_node_subnet, i + var.master_node_settings.ip_offset)]

  master_nodes = {
    for i in range(var.cluster.master_nodes_count) : "${var.cluster.name}-master-${i}" =>
      merge({
        ip = cidrhost(local.master_node_subnet, i + var.master_node_settings.ip_offset)
      })
    }
}

locals {
  support_node_subnet    = coalesce(var.support_node_settings.subnet, var.default_node_settings.subnet)
  support_node_ip        = cidrhost(local.support_node_subnet, var.support_node_settings.ip_offset)
  gw                     = coalesce(var.support_node_settings.gw, var.default_node_settings.gw)
}
