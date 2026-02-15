control_plane_nodes = ["cloudlab-cp1"]
worker_nodes        = ["cloudlab-wk1"]

instance_type = "t2.medium"

ami_id = ""

# VPC Configuration
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
availability_zone   = "ap-south-1a"

# Cluster name prefix for all resources
cluster_name = "cloudlab-cluster"

admin_username = "ubuntu"

root_volume_size = 50

tags = {
  owner       = "rmokashi"
  environment = "prod"
  project     = "cloudlab-k8s-cluster"
  managed_by  = "terraform"
}

