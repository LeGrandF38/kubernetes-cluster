#!/bin/bash

echo "=========================================="
echo "Nettoyage complet Kubernetes"
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

warn "Ce script va supprimer TOUT le cluster Kubernetes existant !"
read -p "Êtes-vous sûr de vouloir continuer ? (oui/non): " confirm

if [[ $confirm != "oui" ]]; then
    echo "Nettoyage annulé."
    exit 0
fi

info "Étape 1/8 : Arrêt et reset de kubeadm..."
kubeadm reset -f 2>/dev/null || true

info "Étape 2/8 : Arrêt des services Kubernetes..."
systemctl stop kubelet 2>/dev/null || true
systemctl stop containerd 2>/dev/null || true

info "Étape 3/8 : Suppression des interfaces réseau..."
ip link delete cni0 2>/dev/null || true
ip link delete flannel.1 2>/dev/null || true
ip link delete docker0 2>/dev/null || true

info "Étape 4/8 : Nettoyage des dossiers Kubernetes..."
rm -rf /etc/kubernetes
rm -rf /var/lib/etcd
rm -rf /var/lib/kubelet
rm -rf /etc/cni/net.d
rm -rf /var/lib/cni
rm -rf /opt/cni/bin

info "Étape 5/8 : Nettoyage K3s (si présent)..."
/usr/local/bin/k3s-uninstall.sh 2>/dev/null || true
/usr/local/bin/k3s-agent-uninstall.sh 2>/dev/null || true
rm -rf /var/lib/rancher
rm -rf /etc/rancher

info "Étape 6/8 : Nettoyage des configurations utilisateur..."
rm -rf /root/.kube
rm -rf $HOME/.kube 2>/dev/null || true

info "Étape 7/8 : Nettoyage des règles iptables..."
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
iptables -t nat -X 2>/dev/null || true

info "Étape 8/8 : Redémarrage de containerd..."
systemctl start containerd 2>/dev/null || true

echo ""
echo "=========================================="
info "Nettoyage terminé avec succès !"
echo "=========================================="
echo ""
echo "Vous pouvez maintenant relancer :"
echo "  - k8s-master-install.sh (sur le master)"
echo "  - k8s-node-install.sh (sur les workers)"
echo ""
warn "Note : Les packages kubeadm/kubelet/kubectl restent installés"
echo "Pour les supprimer complètement : apt remove --purge kubeadm kubelet kubectl"