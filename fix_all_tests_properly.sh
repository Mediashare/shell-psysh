#!/bin/bash

# =============================================================================
# SCRIPT POUR CORRIGER TOUS LES TESTS AVEC test_session_sync
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Correction complète des tests avec test_session_sync...${NC}"

# Fonction pour nettoyer et corriger un fichier
fix_test_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${CYAN}🔧 Fixing $basename...${NC}"
    
    # Créer un backup si nécessaire
    if [[ ! -f "${file}.backup" ]]; then
        cp "$file" "${file}.backup"
    fi
    
    # Créer un fichier temporaire pour la correction
    local temp_file=$(mktemp)
    
    # Traiter le fichier ligne par ligne
    while IFS= read -r line; do
        # Ignorer les lignes orphelines d'options
        if [[ "$line" =~ ^[[:space:]]*--expect.*--context ]]; then
            continue
        fi
        
        # Corriger les appels test_session_sync malformés
        if [[ "$line" =~ test_session_sync.*--step.*phpunit:expect-exception ]]; then
            # Extraire les parties
            local description=$(echo "$line" | sed -n 's/.*test_session_sync "\([^"]*\)".*/\1/p')
            local command=$(echo "$line" | sed -n 's/.*--step "\([^"]*\)".*/\1/p')
            
            echo "test_session_sync \"$description\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"✅\" \\" >> "$temp_file"
            echo "    --context phpunit" >> "$temp_file"
            continue
        fi
        
        if [[ "$line" =~ test_session_sync.*--step.*phpunit:expect-no-exception ]]; then
            local description=$(echo "$line" | sed -n 's/.*test_session_sync "\([^"]*\)".*/\1/p')
            local command=$(echo "$line" | sed -n 's/.*--step "\([^"]*\)".*/\1/p')
            
            echo "test_session_sync \"$description\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"✅\" \\" >> "$temp_file"
            echo "    --context phpunit" >> "$temp_file"
            continue
        fi
        
        if [[ "$line" =~ test_session_sync.*--step.*phpunit:assert-exception ]]; then
            local description=$(echo "$line" | sed -n 's/.*test_session_sync "\([^"]*\)".*/\1/p')
            local command=$(echo "$line" | sed -n 's/.*--step "\([^"]*\)".*/\1/p')
            
            echo "test_session_sync \"$description\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"✅\" \\" >> "$temp_file"
            echo "    --context phpunit" >> "$temp_file"
            continue
        fi
        
        if [[ "$line" =~ test_session_sync.*--step.*phpunit:assert-no-exception ]]; then
            local description=$(echo "$line" | sed -n 's/.*test_session_sync "\([^"]*\)".*/\1/p')
            local command=$(echo "$line" | sed -n 's/.*--step "\([^"]*\)".*/\1/p')
            
            echo "test_session_sync \"$description\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"✅\" \\" >> "$temp_file"
            echo "    --context phpunit" >> "$temp_file"
            continue
        fi
        
        # Corriger les appels monitor
        if [[ "$line" =~ test_session_sync.*--step.*monitor ]]; then
            local description=$(echo "$line" | sed -n 's/.*test_session_sync "\([^"]*\)".*/\1/p')
            local command=$(echo "$line" | sed -n 's/.*--step "\([^"]*\)".*/\1/p')
            
            echo "test_session_sync \"$description\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"success\" \\" >> "$temp_file"
            echo "    --context monitor" >> "$temp_file"
            continue
        fi
        
        # Ajouter la ligne normale si elle ne correspond à aucun pattern
        echo "$line" >> "$temp_file"
        
    done < "$file"
    
    # Remplacer le fichier original
    mv "$temp_file" "$file"
    
    echo -e "${GREEN}✅ $basename corrigé${NC}"
}

# Fonction pour nettoyer entièrement et reconstruire un fichier
rebuild_test_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${YELLOW}🔄 Rebuilding $basename...${NC}"
    
    # Créer un backup
    if [[ ! -f "${file}.backup" ]]; then
        cp "$file" "${file}.backup"
    fi
    
    # Fichier temporaire pour la reconstruction
    local temp_file=$(mktemp)
    
    # En-tête standard
    cat > "$temp_file" << 'EOF'
#!/bin/bash

# Test script - rebuilt for test_session_sync

# Charger les fonctions nécessaires
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
source "$SCRIPT_DIR/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "$(basename "$0" .sh)"

EOF
    
    # Analyser le fichier original pour extraire les tests
    while IFS= read -r line; do
        # Ignorer les lignes de commentaires et les lignes vides
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        # Ignorer les lignes d'initialisation
        if [[ "$line" =~ ^(source|SCRIPT_DIR|init_test|echo) ]]; then
            continue
        fi
        
        # Détecter les anciens appels de test
        if [[ "$line" =~ \$PROJECT_ROOT/bin/psysh.*phpunit:expect-exception ]]; then
            local command=$(echo "$line" | sed -n 's/.*-c "\([^"]*\)".*/\1/p')
            echo "" >> "$temp_file"
            echo "test_session_sync \"Test exception expected\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"✅\" \\" >> "$temp_file"
            echo "    --context phpunit" >> "$temp_file"
            continue
        fi
        
        if [[ "$line" =~ \$PROJECT_ROOT/bin/psysh.*phpunit:expect-no-exception ]]; then
            local command=$(echo "$line" | sed -n 's/.*-c "\([^"]*\)".*/\1/p')
            echo "" >> "$temp_file"
            echo "test_session_sync \"Test no exception expected\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"✅\" \\" >> "$temp_file"
            echo "    --context phpunit" >> "$temp_file"
            continue
        fi
        
        if [[ "$line" =~ \$PROJECT_ROOT/bin/psysh.*phpunit:assert-exception ]]; then
            local command=$(echo "$line" | sed -n 's/.*-c "\([^"]*\)".*/\1/p')
            echo "" >> "$temp_file"
            echo "test_session_sync \"Test assertion exception\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"✅\" \\" >> "$temp_file"
            echo "    --context phpunit" >> "$temp_file"
            continue
        fi
        
        if [[ "$line" =~ \$PROJECT_ROOT/bin/psysh.*phpunit:assert-no-exception ]]; then
            local command=$(echo "$line" | sed -n 's/.*-c "\([^"]*\)".*/\1/p')
            echo "" >> "$temp_file"
            echo "test_session_sync \"Test assertion no exception\" \\" >> "$temp_file"
            echo "    --step \"$command\" \\" >> "$temp_file"
            echo "    --expect \"✅\" \\" >> "$temp_file"
            echo "    --context phpunit" >> "$temp_file"
            continue
        fi
        
        # Détecter les appels monitor
        if [[ "$line" =~ monitor ]]; then
            local command=$(echo "$line" | sed -n 's/.*monitor "\([^"]*\)".*/\1/p')
            if [[ -n "$command" ]]; then
                echo "" >> "$temp_file"
                echo "test_session_sync \"Test monitor command\" \\" >> "$temp_file"
                echo "    --step \"$command\" \\" >> "$temp_file"
                echo "    --expect \"success\" \\" >> "$temp_file"
                echo "    --context monitor" >> "$temp_file"
            fi
            continue
        fi
        
    done < "$file"
    
    # Pied de page standard
    cat >> "$temp_file" << 'EOF'

# Afficher le résumé
test_summary

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
EOF
    
    # Remplacer le fichier original
    mv "$temp_file" "$file"
    
    echo -e "${GREEN}✅ $basename reconstruit${NC}"
}

# Fonction principale
main() {
    local total_files=0
    local fixed_files=0
    
    # Trouver tous les fichiers de test
test_files=()
    while IFS= read -r file; do
        test_files+=("$file")
    done < <(find ./test/shell/Command -name "*.sh" -type f | sort)
    
    total_files=${#test_files[@]}
    echo -e "${BLUE}📁 Fichiers trouvés: $total_files${NC}"
    
    # Traiter chaque fichier
    for file in "${test_files[@]}"; do
        local basename=$(basename "$file")
        
        # Vérifier si le fichier a besoin d'être corrigé
        if grep -q "test_session_sync" "$file" && grep -q "^\s*--expect.*--context" "$file"; then
            fix_test_file "$file"
            ((fixed_files++))
        elif grep -q "\$PROJECT_ROOT/bin/psysh\|monitor\|phpunit:" "$file"; then
            rebuild_test_file "$file"
            ((fixed_files++))
        else
            echo -e "${YELLOW}⏭️  Skipping $basename (no changes needed)${NC}"
        fi
    done
    
    # Statistiques finales
    echo ""
    echo -e "${GREEN}📊 Correction terminée:${NC}"
    echo -e "${CYAN}   Total: $total_files fichiers${NC}"
    echo -e "${GREEN}   Corrigés: $fixed_files fichiers${NC}"
    echo -e "${YELLOW}   Ignorés: $((total_files - fixed_files)) fichiers${NC}"
    
    if [[ $fixed_files -gt 0 ]]; then
        echo ""
        echo -e "${GREEN}✅ Correction réussie!${NC}"
        echo -e "${CYAN}💡 Les fichiers .backup ont été conservés comme sauvegarde${NC}"
    fi
}

# Exécuter le script principal
main "$@"
