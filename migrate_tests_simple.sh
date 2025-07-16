#!/bin/bash

# =============================================================================
# SCRIPT SIMPLE DE MIGRATION VERS test_session_sync
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Migration vers test_session_sync...${NC}"

# Trouver tous les fichiers de test
find ./test/shell/Command -name "*.sh" -type f | while read -r file; do
    echo -e "${CYAN}🔧 Processing $(basename "$file")...${NC}"
    
    # Vérifier si déjà migré
    if grep -q "test_session_sync" "$file"; then
        echo -e "${YELLOW}⏭️  Skipping $(basename "$file") (already using test_session_sync)${NC}"
        continue
    fi
    
    # Créer un backup
    if [[ ! -f "${file}.old" ]]; then
        cp "$file" "${file}.old"
    fi
    
    # Ajouter l'import de test_session_sync après les imports existants
    sed -i '' '/source.*loader\.sh/a\
# Charger test_session_sync\
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"
' "$file"
    
    # Remplacer les appels de test simples par test_session_sync
    # Pattern: test_execute "description" 'command' "expected"
    sed -i '' 's/test_execute \([^"]*\)"[^"]*" \([^'"'"']*\)'"'"'[^'"'"']*'"'"' \([^"]*\)"[^"]*"/test_session_sync \1"..." --step \2"..." --expect \3"..." --context monitor/g' "$file"
    
    # Remplacer les appels directs de commandes psysh
    sed -i '' 's/\$PROJECT_ROOT\/bin\/psysh -c/test_session_sync "Test command" --step/g' "$file"
    
    echo -e "${GREEN}✅ $(basename "$file") migré${NC}"
done

echo -e "${GREEN}🎉 Migration terminée!${NC}"
