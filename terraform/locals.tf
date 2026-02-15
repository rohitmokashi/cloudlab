locals {
  # Combine all nodes for common resources
  all_nodes = concat(var.control_plane_nodes, var.worker_nodes)

  # Primary control plane node for initial cluster setup
  primary_control_plane = var.control_plane_nodes[0]
}
