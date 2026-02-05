#!/bin/bash

echo "=========================================="
echo "Installation Kubernetes Master"
echo "=========================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si on est root
if [[ $EUID -ne 0 ]]; then
   error "Ce script doit être exécuté en tant que root (sudo)" 
   exit 1
fi

info "Étape 1/10 : Nettoyage de K3s..."
/usr/local/bin/k3s-uninstall.sh 2>/dev/null || true
rm -rf /var/lib/rancher
rm -rf /etc/rancher
rm -rf /var/lib/kubelet
rm -rf /etc/cni
rm -rf /opt/cni

info "Étape 2/10 : Désactivation du swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

info "Étape 3/10 : Configuration des modules kernel..."
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

info "Étape 4/10 : Configuration sysctl..."
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

info "Étape 5/10 : Installation de containerd..."
apt update
apt install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

info "Étape 6/10 : Ajout du dépôt Kubernetes..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

info "Étape 7/10 : Installation de kubeadm, kubelet et kubectl..."
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

info "Étape 8/10 : Initialisation du cluster Kubernetes..."
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.0.0.100

info "Étape 9/10 : Configuration de kubectl pour l'utilisateur..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Configuration aussi pour root
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

info "Étape 10/10 : Installation du plugin réseau Flannel..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo ""
echo "=========================================="
info "Installation terminée avec succès !"
echo "=========================================="
echo ""
warn "IMPORTANT : Copiez la commande 'kubeadm join' ci-dessous pour l'utiliser sur node1 :"
echo ""
kubeadm token create --print-join-command
echo ""
echo "Vérifiez l'état du cluster avec :"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
