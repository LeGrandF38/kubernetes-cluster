#!/bin/bash

echo "=========================================="
echo "Installation de ttyd (Web Terminal)"
echo "=========================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Port par défaut (modifiable)
TTYD_PORT=7681

info "Étape 1/4 : Installation des dépendances..."
apt-get update
apt-get install -y wget

info "Étape 2/4 : Téléchargement de ttyd..."
TTYD_VERSION=$(wget -qO- https://api.github.com/repos/tsl0922/ttyd/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [[ -z "$TTYD_VERSION" ]]; then
    warn "Impossible de détecter la dernière version, utilisation de 1.7.7"
    TTYD_VERSION="1.7.7"
fi

info "Version détectée : $TTYD_VERSION"
wget -qO /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.$(uname -m)"
chmod +x /usr/local/bin/ttyd

# Vérifier l'installation
if ! /usr/local/bin/ttyd --version &>/dev/null; then
    error "L'installation de ttyd a échoué"
    exit 1
fi

info "Étape 3/4 : Création du service systemd..."
cat <<EOF > /etc/systemd/system/ttyd.service
[Unit]
Description=ttyd - Web Terminal
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ttyd --port ${TTYD_PORT} --writable bash
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

info "Étape 4/4 : Démarrage du service ttyd..."
systemctl daemon-reload
systemctl enable ttyd
systemctl start ttyd

# Récupérer l'IP
NODE_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
info "ttyd installé et démarré avec succès !"
echo "=========================================="
echo ""
echo "  Accédez au terminal web depuis votre navigateur :"
echo ""
echo "    http://${NODE_IP}:${TTYD_PORT}"
echo ""
warn "SECURITE : ttyd est ouvert sans authentification !"
echo "  Pour ajouter un login/mot de passe, modifiez le service :"
echo "    sudo systemctl edit ttyd"
echo "  Et remplacez ExecStart par :"
echo "    ExecStart=/usr/local/bin/ttyd --port ${TTYD_PORT} --writable -c user:motdepasse bash"
echo "  Puis : sudo systemctl restart ttyd"
echo ""
echo "  Commandes utiles :"
echo "    sudo systemctl status ttyd    # vérifier le statut"
echo "    sudo systemctl stop ttyd      # arrêter"
echo "    sudo systemctl restart ttyd   # redémarrer"
echo ""
