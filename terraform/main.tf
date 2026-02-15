# ============================================================================
# Kubernetes Cluster on AWS - Main Entry Point
# ============================================================================
# This file is intentionally minimal. Resources are organized in:
#
# - provider.tf         : Terraform & AWS provider configuration
# - locals.tf           : Local variables and computed values
# - input_variables.tf  : Variable definitions
# - datasources.tf      : Data sources (AMI lookup)
# - vpc.tf              : VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
# - security_groups.tf  : Security Group rules for K8s cluster
# - ec2.tf              : EC2 instances for K8s nodes
# - k8s_provisioning.tf : Kubernetes installation and cluster setup
# - outputs.tf          : Output values
# ============================================================================
