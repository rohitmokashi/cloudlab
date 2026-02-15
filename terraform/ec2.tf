# ============================================================================
# EC2 Instances for Kubernetes Nodes
# ============================================================================
resource "aws_instance" "k8s_nodes" {
  for_each = toset(local.all_nodes)

  ami                         = local.selected_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true

  # User data to enable password authentication (Ubuntu)
  user_data = <<-EOF
              #!/bin/bash
              # Create admin user with password
              useradd -m -s /bin/bash ${var.admin_username} 2>/dev/null || true
              echo "${var.admin_username}:${var.admin_password}" | chpasswd
              usermod -aG sudo ${var.admin_username}
              
              # Allow sudo without password
              echo "${var.admin_username} ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/${var.admin_username}
              
              # Enable password authentication for SSH
              sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
              sed -i 's/^KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
              echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
              
              # Restart SSH service
              systemctl restart ssh
              EOF

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = each.value
  })
}
