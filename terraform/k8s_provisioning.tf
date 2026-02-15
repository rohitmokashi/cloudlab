# ============================================================================
# STAGE 1: Wait for all VMs to be ready before any K8s provisioning
# ============================================================================
resource "null_resource" "wait_for_vms" {
  for_each   = toset(local.all_nodes)
  depends_on = [aws_instance.k8s_nodes]

  provisioner "remote-exec" {
    inline = [
      "echo 'VM ${each.value} is ready and accessible via SSH'"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = aws_instance.k8s_nodes[each.key].public_ip
      timeout  = "10m"
    }
  }
}

# ============================================================================
# STAGE 2: Install K8s prerequisites on all nodes (after all VMs are ready)
# ============================================================================
resource "null_resource" "k8s_prerequisites" {
  for_each   = toset(local.all_nodes)
  depends_on = [null_resource.wait_for_vms]

  provisioner "remote-exec" {
    inline = [
      "echo '=== Starting K8s prerequisites installation on ${each.value} ==='",
      "sudo hostnamectl set-hostname ${each.value}",
      "echo \"$(hostname -I | awk '{print $1}') $(hostname)\" | sudo tee -a /etc/hosts",
      "sudo apt-get update -y",
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^\\(.*\\)$/#\\1/g' /etc/fstab",
      "echo -e 'overlay\\nbr_netfilter' | sudo tee /etc/modules-load.d/k8s.conf",
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter",
      "echo -e 'net.bridge.bridge-nf-call-iptables = 1\\nnet.ipv4.ip_forward = 1\\nnet.bridge.bridge-nf-call-ip6tables = 1' | sudo tee -a /etc/sysctl.d/k8s.conf",
      "sudo sysctl --system",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo mkdir -p /etc/docker",
      "echo '{\"exec-opts\": [\"native.cgroupdriver=systemd\"], \"log-driver\": \"json-file\", \"log-opts\": {\"max-size\": \"100m\"}, \"storage-driver\": \"overlay2\"}' | sudo tee /etc/docker/daemon.json",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ${var.admin_username}",
      "sudo mkdir -p /etc/containerd",
      "containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1",
      "sudo sed -i 's/SystemdCgroup \\= false/SystemdCgroup \\= true/g' /etc/containerd/config.toml",
      "sudo systemctl restart containerd",
      "sudo systemctl enable containerd",
      "sudo apt-get install -y apt-transport-https ca-certificates curl",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo apt-mark hold kubelet kubeadm kubectl",
      "sudo systemctl enable --now kubelet",
      "echo '=== K8s prerequisites installation completed on ${each.value} ==='"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = aws_instance.k8s_nodes[each.key].public_ip
      timeout  = "30m"
    }
  }
}

# ============================================================================
# STAGE 3: Initialize primary control plane (after all prerequisites done)
# ============================================================================
resource "null_resource" "master_init" {
  depends_on = [null_resource.k8s_prerequisites]

  provisioner "remote-exec" {
    inline = [
      "echo '=== Initializing primary control plane ==='",
      "PRIVATE_IP=$(hostname -I | awk '{print $1}')",
      "PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)",
      "PUBLIC_HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)",
      "echo \"Private IP: $PRIVATE_IP\"",
      "echo \"Public IP: $PUBLIC_IP\"",
      "echo \"Public Hostname: $PUBLIC_HOSTNAME\"",
      "sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$PRIVATE_IP --apiserver-cert-extra-sans=$PUBLIC_IP,$PUBLIC_HOSTNAME,$PRIVATE_IP --ignore-preflight-errors=NumCPU,Mem",
      "mkdir -p $HOME/.kube",
      "sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml",
      "echo '=== Waiting for Flannel to be ready ==='",
      "sleep 30",
      "kubectl get nodes",
      "kubeadm token create --print-join-command > /tmp/join_command.sh",
      "chmod +x /tmp/join_command.sh",
      "echo '=== Primary control plane initialization completed ==='"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = aws_instance.k8s_nodes[local.primary_control_plane].public_ip
      timeout  = "30m"
    }
  }
}

# ============================================================================
# STAGE 4: Join additional control plane nodes (after primary is initialized)
# ============================================================================
resource "null_resource" "control_plane_join" {
  for_each   = toset(slice(var.control_plane_nodes, 1, length(var.control_plane_nodes)))
  depends_on = [null_resource.master_init]

  provisioner "remote-exec" {
    inline = [
      "echo '=== Joining ${each.value} as additional control plane node ==='",
      "sudo apt-get install -y sshpass",
      "JOIN_CMD=$(sshpass -p '${var.admin_password}' ssh -o StrictHostKeyChecking=no ${var.admin_username}@${aws_instance.k8s_nodes[local.primary_control_plane].private_ip} 'cat /tmp/join_command.sh')",
      "sudo $JOIN_CMD --control-plane",
      "echo '=== ${each.value} successfully joined as control plane ==='"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = aws_instance.k8s_nodes[each.key].public_ip
      timeout  = "15m"
    }
  }
}

# ============================================================================
# STAGE 5: Join worker nodes (after primary control plane is initialized)
# ============================================================================
resource "null_resource" "worker_join" {
  for_each   = toset(var.worker_nodes)
  depends_on = [null_resource.master_init]

  provisioner "remote-exec" {
    inline = [
      "echo '=== Joining ${each.value} as worker node ==='",
      "sudo apt-get install -y sshpass",
      "JOIN_CMD=$(sshpass -p '${var.admin_password}' ssh -o StrictHostKeyChecking=no ${var.admin_username}@${aws_instance.k8s_nodes[local.primary_control_plane].private_ip} 'cat /tmp/join_command.sh')",
      "sudo $JOIN_CMD",
      "echo '=== ${each.value} successfully joined as worker ==='"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = aws_instance.k8s_nodes[each.key].public_ip
      timeout  = "15m"
    }
  }
}

# ============================================================================
# STAGE 6: Verify cluster status (after all nodes have joined)
# ============================================================================
resource "null_resource" "cluster_verification" {
  depends_on = [null_resource.control_plane_join, null_resource.worker_join]

  provisioner "remote-exec" {
    inline = [
      "echo '=== Verifying Kubernetes Cluster Status ==='",
      "echo ''",
      "echo '--- Node Status ---'",
      "kubectl get nodes -o wide",
      "echo ''",
      "echo '--- System Pods Status ---'",
      "kubectl get pods -n kube-system",
      "echo ''",
      "echo '--- Cluster Info ---'",
      "kubectl cluster-info",
      "echo ''",
      "echo '=== Kubernetes Cluster Setup Complete! ==='"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = aws_instance.k8s_nodes[local.primary_control_plane].public_ip
      timeout  = "5m"
    }
  }
}
