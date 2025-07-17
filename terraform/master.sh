NODENAME=$(hostname -s)
MASTER_PRIVATE_IP=$(ip addr show ens5 | awk '/inet / {print $2}' | cut -d/ -f1)
kubeadm init --apiserver-advertise-address="$MASTER_PRIVATE_IP" --node-name "$NODENAME" --pod-network-cidr=192.168.0.0/16

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config