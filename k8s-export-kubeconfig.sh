#!/bin/bash

# =============================================================================
# Script d'export du kubeconfig Kubernetes
# Ce script permet d'exporter le fichier admin.conf via plusieurs méthodes
# =============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fichier kubeconfig par défaut
KUBECONFIG_FILE="/etc/kubernetes/admin.conf"
TEMP_FILE="/tmp/kubeconfig_export_$(date +%s).txt"

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           KUBERNETES KUBECONFIG EXPORT TOOL                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_kubeconfig() {
    if [[ ! -f "$KUBECONFIG_FILE" ]]; then
        echo -e "${RED}[ERREUR] Fichier $KUBECONFIG_FILE non trouvé${NC}"
        echo -e "${YELLOW}Essayez avec: sudo $0${NC}"
        exit 1
    fi
    
    if [[ ! -r "$KUBECONFIG_FILE" ]]; then
        echo -e "${RED}[ERREUR] Impossible de lire $KUBECONFIG_FILE${NC}"
        echo -e "${YELLOW}Essayez avec: sudo $0${NC}"
        exit 1
    fi
}

# Méthode 1: Upload vers transfer.sh (service gratuit de partage de fichiers)
upload_transfer_sh() {
    echo -e "${BLUE}[INFO] Upload vers transfer.sh...${NC}"
    
    RESULT=$(curl --upload-file "$KUBECONFIG_FILE" "https://transfer.sh/admin.conf" 2>/dev/null)
    
    if [[ -n "$RESULT" ]]; then
        echo -e "${GREEN}[SUCCÈS] Fichier uploadé!${NC}"
        echo -e "${YELLOW}URL de téléchargement (valide 14 jours):${NC}"
        echo -e "${CYAN}$RESULT${NC}"
        echo ""
        echo -e "${YELLOW}Pour télécharger: curl -o admin.conf $RESULT${NC}"
        return 0
    else
        echo -e "${RED}[ÉCHEC] Upload vers transfer.sh échoué${NC}"
        return 1
    fi
}

# Méthode 2: Upload vers file.io (fichier supprimé après 1er téléchargement)
upload_file_io() {
    echo -e "${BLUE}[INFO] Upload vers file.io...${NC}"
    
    RESULT=$(curl -F "file=@$KUBECONFIG_FILE" "https://file.io" 2>/dev/null)
    
    if [[ -n "$RESULT" ]]; then
        URL=$(echo "$RESULT" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$URL" ]]; then
            echo -e "${GREEN}[SUCCÈS] Fichier uploadé!${NC}"
            echo -e "${YELLOW}URL de téléchargement (1 seul téléchargement possible):${NC}"
            echo -e "${CYAN}$URL${NC}"
            echo ""
            echo -e "${RED}⚠️  ATTENTION: Le fichier sera supprimé après le 1er téléchargement!${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[ÉCHEC] Upload vers file.io échoué${NC}"
    return 1
}

# Méthode 3: Upload vers 0x0.st
upload_0x0() {
    echo -e "${BLUE}[INFO] Upload vers 0x0.st...${NC}"
    
    RESULT=$(curl -F "file=@$KUBECONFIG_FILE" "https://0x0.st" 2>/dev/null)
    
    if [[ -n "$RESULT" && "$RESULT" == http* ]]; then
        echo -e "${GREEN}[SUCCÈS] Fichier uploadé!${NC}"
        echo -e "${YELLOW}URL de téléchargement:${NC}"
        echo -e "${CYAN}$RESULT${NC}"
        echo ""
        echo -e "${YELLOW}Pour télécharger: curl -o admin.conf $RESULT${NC}"
        return 0
    else
        echo -e "${RED}[ÉCHEC] Upload vers 0x0.st échoué${NC}"
        return 1
    fi
}

# Méthode 4: Upload vers tmpfiles.org
upload_tmpfiles() {
    echo -e "${BLUE}[INFO] Upload vers tmpfiles.org...${NC}"
    
    RESULT=$(curl -F "file=@$KUBECONFIG_FILE" "https://tmpfiles.org/api/v1/upload" 2>/dev/null)
    
    if [[ -n "$RESULT" ]]; then
        URL=$(echo "$RESULT" | grep -o '"url":"[^"]*"' | cut -d'"' -f4 | sed 's|tmpfiles.org/|tmpfiles.org/dl/|')
        if [[ -n "$URL" ]]; then
            echo -e "${GREEN}[SUCCÈS] Fichier uploadé!${NC}"
            echo -e "${YELLOW}URL de téléchargement:${NC}"
            echo -e "${CYAN}$URL${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[ÉCHEC] Upload vers tmpfiles.org échoué${NC}"
    return 1
}

# Méthode 5: Afficher en Base64 (copier-coller)
show_base64() {
    echo -e "${BLUE}[INFO] Encodage en Base64...${NC}"
    echo ""
    echo -e "${YELLOW}═══════════════════ DÉBUT BASE64 ═══════════════════${NC}"
    base64 "$KUBECONFIG_FILE"
    echo -e "${YELLOW}════════════════════ FIN BASE64 ════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Pour décoder sur votre machine:${NC}"
    echo -e "${CYAN}echo '<COLLER_LE_BASE64_ICI>' | base64 -d > admin.conf${NC}"
    echo ""
    echo -e "${YELLOW}Ou sous Windows PowerShell:${NC}"
    echo -e "${CYAN}[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('<BASE64>')) | Out-File admin.conf${NC}"
}

# Méthode 6: Afficher en clair (pour copier-coller direct)
show_raw() {
    echo -e "${BLUE}[INFO] Affichage du contenu brut...${NC}"
    echo ""
    echo -e "${YELLOW}═══════════════════ DÉBUT KUBECONFIG ═══════════════════${NC}"
    cat "$KUBECONFIG_FILE"
    echo -e "${YELLOW}════════════════════ FIN KUBECONFIG ════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Copiez le contenu ci-dessus et collez-le dans un fichier admin.conf${NC}"
}

# Méthode 7: Upload vers pastebin (dpaste.org)
upload_dpaste() {
    echo -e "${BLUE}[INFO] Upload vers dpaste.org...${NC}"
    
    CONTENT=$(cat "$KUBECONFIG_FILE")
    RESULT=$(curl -s -X POST "https://dpaste.org/api/" \
        -d "content=$CONTENT" \
        -d "syntax=yaml" \
        -d "expiry_days=7" 2>/dev/null)
    
    if [[ -n "$RESULT" && "$RESULT" == http* ]]; then
        RAW_URL="${RESULT}/raw"
        echo -e "${GREEN}[SUCCÈS] Fichier uploadé!${NC}"
        echo -e "${YELLOW}URL (expire dans 7 jours):${NC}"
        echo -e "${CYAN}$RESULT${NC}"
        echo ""
        echo -e "${YELLOW}URL raw pour téléchargement:${NC}"
        echo -e "${CYAN}$RAW_URL${NC}"
        echo ""
        echo -e "${YELLOW}Pour télécharger: curl -o admin.conf $RAW_URL${NC}"
        return 0
    else
        echo -e "${RED}[ÉCHEC] Upload vers dpaste.org échoué${NC}"
        return 1
    fi
}

# Menu principal
show_menu() {
    echo -e "${GREEN}Choisissez une méthode d'export:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} transfer.sh    - Upload fichier (14 jours)"
    echo -e "  ${CYAN}2)${NC} file.io        - Upload fichier (1 téléchargement)"
    echo -e "  ${CYAN}3)${NC} 0x0.st         - Upload fichier"
    echo -e "  ${CYAN}4)${NC} tmpfiles.org   - Upload fichier temporaire"
    echo -e "  ${CYAN}5)${NC} dpaste.org     - Pastebin (7 jours)"
    echo -e "  ${CYAN}6)${NC} Base64         - Afficher encodé (copier-coller)"
    echo -e "  ${CYAN}7)${NC} Brut           - Afficher en clair (copier-coller)"
    echo -e "  ${CYAN}8)${NC} Tout essayer   - Essaie toutes les méthodes d'upload"
    echo -e "  ${CYAN}0)${NC} Quitter"
    echo ""
}

try_all_uploads() {
    echo -e "${BLUE}[INFO] Tentative de toutes les méthodes d'upload...${NC}"
    echo ""
    
    upload_transfer_sh && return 0
    echo ""
    upload_file_io && return 0
    echo ""
    upload_0x0 && return 0
    echo ""
    upload_tmpfiles && return 0
    echo ""
    upload_dpaste && return 0
    echo ""
    
    echo -e "${RED}[ÉCHEC] Toutes les méthodes d'upload ont échoué${NC}"
    echo -e "${YELLOW}Utilisez les méthodes Base64 ou Brut pour copier-coller manuellement${NC}"
    return 1
}

# Mode automatique (essaie tout)
auto_mode() {
    echo -e "${BLUE}[MODE AUTO] Recherche de la meilleure méthode...${NC}"
    echo ""
    
    if command -v curl &> /dev/null; then
        try_all_uploads && exit 0
    fi
    
    echo -e "${YELLOW}[FALLBACK] Affichage en Base64...${NC}"
    echo ""
    show_base64
}

# Main
print_banner
check_kubeconfig

# Si argument passé, mode automatique
if [[ "$1" == "--auto" || "$1" == "-a" ]]; then
    auto_mode
    exit 0
fi

# Mode interactif
while true; do
    show_menu
    read -p "Votre choix [1-8, 0]: " choice
    echo ""
    
    case $choice in
        1) upload_transfer_sh ;;
        2) upload_file_io ;;
        3) upload_0x0 ;;
        4) upload_tmpfiles ;;
        5) upload_dpaste ;;
        6) show_base64 ;;
        7) show_raw ;;
        8) try_all_uploads ;;
        0) echo -e "${GREEN}Au revoir!${NC}"; exit 0 ;;
        *) echo -e "${RED}Choix invalide${NC}" ;;
    esac
    
    echo ""
    echo -e "${YELLOW}─────────────────────────────────────────────────────${NC}"
    echo ""
done
