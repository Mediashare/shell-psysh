#!/bin/bash

# =============================================================================
# SCRIPT DE CORRECTION DES FICHIERS MIGRÉS
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Correction des fichiers migrés...${NC}"

# Fonction pour corriger un fichier spécifique
fix_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${CYAN}🔧 Fixing $basename...${NC}"
    
    # Corriger les appels test_session_sync incomplets
    # Ajouter --expect pour les tests PHPUnit
    sed -i '' 's/test_session_sync "Test command" --step "phpunit:expect-exception/test_session_sync "Test exception expected" --step "phpunit:expect-exception/g' "$file"
    sed -i '' 's/test_session_sync "Test command" --step "phpunit:expect-no-exception/test_session_sync "Test no exception expected" --step "phpunit:expect-no-exception/g' "$file"
    sed -i '' 's/test_session_sync "Test command" --step "phpunit:assert-exception/test_session_sync "Test assertion exception" --step "phpunit:assert-exception/g' "$file"
    sed -i '' 's/test_session_sync "Test command" --step "phpunit:assert-no-exception/test_session_sync "Test assertion no exception" --step "phpunit:assert-no-exception/g' "$file"
    
    # Ajouter --expect "✅" pour les tests PHPUnit réussis
    sed -i '' '/test_session_sync.*phpunit:expect-no-exception/s/$/\n    --expect "✅" --context phpunit/' "$file"
    sed -i '' '/test_session_sync.*phpunit:assert-no-exception/s/$/\n    --expect "✅" --context phpunit/' "$file"
    
    # Ajouter --expect "✅" pour les tests PHPUnit d'exception
    sed -i '' '/test_session_sync.*phpunit:expect-exception/s/$/\n    --expect "✅" --context phpunit/' "$file"
    sed -i '' '/test_session_sync.*phpunit:assert-exception/s/$/\n    --expect "✅" --context phpunit/' "$file"
    
    # Corriger les doubles échappements
    sed -i '' 's/\\\\\\"/\"/g' "$file"
    sed -i '' 's/\\\\\\\\/\\/g' "$file"
    
    # Supprimer les lignes echo qui affichent les commandes
    sed -i '' '/^echo.*test_session_sync.*--step/d' "$file"
    
    echo -e "${GREEN}✅ $basename corrigé${NC}"
}

# Corriger tous les fichiers migrés
find ./test/shell/Command -name "*.sh" -type f | while read -r file; do
    # Vérifier si le fichier utilise test_session_sync
    if grep -q "test_session_sync" "$file"; then
        fix_file "$file"
    fi
done

echo -e "${GREEN}🎉 Correction terminée!${NC}"
