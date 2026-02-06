#!/bin/bash

echo "=========================================="
echo "Préparation Kubernetes Worker Node"
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

info "Étape 1/9 : Nettoyage de K3s..."
/usr/local/bin/k3s-agent-uninstall.sh 2>/dev/null || true
/usr/local/bin/k3s-uninstall.sh 2>/dev/null || true
rm -rf /var/lib/rancher
rm -rf /etc/rancher
rm -rf /var/lib/kubelet
rm -rf /etc/cni
rm -rf /opt/cni

info "Étape 2/9 : Désactivation du swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

info "Étape 3/9 : Configuration des modules kernel..."
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

info "Étape 4/9 : Configuration sysctl..."
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

info "Étape 5/9 : Installation de containerd..."
apt update
apt install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

info "Étape 6/9 : Ajout du dépôt Kubernetes..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

# Version Kubernetes (doit correspondre au master)
K8S_VERSION="v1.32"

mkdir -p /etc/apt/keyrings
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

info "Étape 7/9 : Installation de kubeadm, kubelet et kubectl..."
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo ""
echo "=========================================="
info "Préparation terminée avec succès !"
echo "=========================================="
echo ""
warn "IMPORTANT : Exécutez maintenant la commande 'kubeadm join' que vous avez copiée depuis le master"
echo ""
echo "Exemple :"
echo "  sudo kubeadm join 10.0.0.100:6443 --token xxxxx --discovery-token-ca-cert-hash sha256:xxxxx"
echo ""
echo "Si vous avez une erreur CPU, utilisez :"
echo "  sudo kubeadm join 10.0.0.100:6443 --token xxxxx --discovery-token-ca-cert-hash sha256:xxxxx --ignore-preflight-errors=NumCPU"
echo ""
