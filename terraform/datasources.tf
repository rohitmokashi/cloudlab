# Get latest Ubuntu 22.04 LTS AMI if ami_id is not specified
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use provided AMI or default to Ubuntu 22.04
  selected_ami = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
}

