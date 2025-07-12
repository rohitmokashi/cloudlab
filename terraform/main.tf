provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./vpc"
}

module "security" {
  source = "./security"
  vpc_id = module.vpc.vpc_id
}

module "compute" {
  source = "./compute"
  public_subnet_id        = module.vpc.public_subnet_id
  private_subnet_id        = module.vpc.private_subnet_id
  security_group_id = module.security.node_sg_id
  control_plane_count     = var.control_plane_count
  node_count     = var.node_count
  ami_id         = var.ami_id
  instance_type  = var.instance_type
}

