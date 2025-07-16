#!/bin/bash

# =============================================================================
# SCRIPT POUR RESTAURER LES FICHIERS DEPUIS LES BACKUPS
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Restauration des fichiers depuis les backups...${NC}"

# Compteurs
RESTORED_COUNT=0
TOTAL_BACKUPS=0

# Trouver tous les fichiers de backup
find ./test/shell/Command -name "*.backup" -type f | while read -r backup_file; do
    # Obtenir le nom du fichier original
    original_file="${backup_file%.backup}"
    
    if [[ -f "$original_file" ]]; then
        echo -e "${CYAN}🔄 Restauration de $(basename "$original_file")...${NC}"
        
        # Restaurer le fichier
        cp "$backup_file" "$original_file"
        
        echo -e "${GREEN}✅ $(basename "$original_file") restauré${NC}"
        ((RESTORED_COUNT++))
    else
        echo -e "${YELLOW}⚠️  Fichier original non trouvé: $original_file${NC}"
    fi
    
    ((TOTAL_BACKUPS++))
done

echo ""
echo -e "${GREEN}📊 Restauration terminée:${NC}"
echo -e "${CYAN}   Backups trouvés: $TOTAL_BACKUPS${NC}"
echo -e "${GREEN}   Fichiers restaurés: $RESTORED_COUNT${NC}"

if [[ $RESTORED_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${GREEN}✅ Restauration réussie!${NC}"
    echo -e "${CYAN}💡 Les fichiers .backup sont toujours conservés${NC}"
fi
