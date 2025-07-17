provider "aws" {
  region = "ap-south-1"
}

# 1. Create a custom VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
}

# 2. Create an internet gateway for public access
resource "aws_internet_gateway" "k8s_gw" {
  vpc_id = aws_vpc.k8s_vpc.id
}

# 3. Create a public subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# 4. Route table for the public subnet
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_gw.id
  }
}

# 5. Associate route table with subnet
resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_rt.id
}

# 6. Key pair from your local system
resource "aws_key_pair" "test_key" {
  key_name   = "test-key"
  public_key = file("C:/Users/rohit/.ssh/id_rsa.pub")
}

# 7. Security group for Kubernetes testing
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-test-sg"
  description = "Security group for Kubernetes test cluster"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "etcd server client API"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "kube-scheduler"
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "kube-controller-manager"
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 8. Control Plane
resource "aws_instance" "control_plane" {
  ami                         = "ami-08abeca95324c9c91"  # Amazon Linux 2 (ap-south-1)
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.test_key.key_name
  subnet_id                   = aws_subnet.k8s_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]

  provisioner "file" {
    source      = "common.sh"
    destination = "/home/ec2-user/common.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("C:/Users/rohit/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "master.sh"
    destination = "/home/ec2-user/master.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("C:/Users/rohit/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "k8s-control-plane"
  }
}

# 9. Worker Nodes
resource "aws_instance" "worker_nodes" {
  count                       = 2
  ami                         = "ami-08abeca95324c9c91"
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.test_key.key_name
  subnet_id                   = aws_subnet.k8s_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]

  provisioner "file" {
    source      = "common.sh"
    destination = "/home/ec2-user/common.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("C:/Users/rohit/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  
  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}
