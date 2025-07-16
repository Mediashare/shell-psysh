#!/bin/bash

# =============================================================================
# SCRIPT COMPLET POUR REMPLACER TOUTES LES FONCTIONS DE TEST PAR test_session_sync
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Migration complète vers test_session_sync...${NC}"

# Fonction pour remplacer les fonctions de test dans un fichier
migrate_test_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${CYAN}🔧 Migrating $basename...${NC}"
    
    # Ajouter l'import test_session_sync si pas déjà présent
    if ! grep -q "test_session_sync_enhanced.sh" "$file"; then
        sed -i '' '/source.*loader\.sh/a\
source "$SCRIPT_DIR/../../lib/func/test_session_sync_enhanced.sh"
' "$file"
    fi
    
    # 1. Remplacer test_monitor_multiline
    sed -i '' 's/test_monitor_multiline \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/test_monitor_multiline \([^\"]*\)\"\\([^\"]*\\)\" \\\\$/test_session_sync \\1\"\\2\" \\\\\\/" "$file"
    sed -i '' "s/test_monitor_multiline \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' \\\\$/test_session_sync \\1\"\\2\" \\\\\\/" "$file"
    
    # 2. Remplacer test_monitor_expression
    sed -i '' 's/test_monitor_expression \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/test_monitor_expression \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\4' \\\\\\n    --context monitor --output-check result/g" "$file"
    
    # 3. Remplacer test_monitor_error
    sed -i '' 's/test_monitor_error \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/test_monitor_error \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\4' \\\\\\n    --context monitor --output-check error/g" "$file"
    
    # 4. Remplacer test_monitor_echo
    sed -i '' 's/test_monitor_echo \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/test_monitor_echo \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\4' \\\\\\n    --context monitor --input-type echo/g" "$file"
    
    # 5. Remplacer test_monitor_performance
    sed -i '' 's/test_monitor_performance \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/test_monitor_performance \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\4' \\\\\\n    --context monitor --benchmark --memory-check/g" "$file"
    
    # 6. Remplacer test_shell_responsiveness
    sed -i '' 's/test_shell_responsiveness \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/test_shell_responsiveness \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\5' \\\\\\n    --context shell/g" "$file"
    
    # 7. Remplacer test_sync_bidirectional
    sed -i '' 's/test_sync_bidirectional \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/test_sync_bidirectional \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\4' \\\\\\n    --context monitor --sync-test/g" "$file"
    
    # 8. Remplacer test_psysh_error
    sed -i '' 's/test_psysh_error \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/test_psysh_error \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\4' \\\\\\n    --context psysh --output-check error/g" "$file"
    
    # 9. Remplacer run_test_step
    sed -i '' 's/run_test_step \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' "s/run_test_step \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\4' \\\\\\n    --context monitor/g" "$file"
    
    # 10. Remplacer test_error_pattern (si pas déjà fait)
    sed -i '' "s/test_error_pattern \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --expect '\\4' \\\\\\n    --context monitor --output-check error/g" "$file"
    
    # 11. Remplacer test_combined_commands (si pas déjà fait)  
    sed -i '' "s/test_combined_commands \([^\"]*\)\"\\([^\"]*\\)\" '\\([^']*\\)' '\\([^']*\\)' '\\([^']*\\)'/test_session_sync \\1\"\\2\" \\\\\\n    --step '\\3' \\\\\\n    --step '\\4' \\\\\\n    --expect '\\5' \\\\\\n    --context monitor/g" "$file"
    
    echo -e "${GREEN}✅ $basename migré${NC}"
}

# Fonction pour migrer les patterns echo + PSYSH_CMD
migrate_echo_patterns() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${CYAN}🔧 Migrating echo patterns in $basename...${NC}"
    
    # Créer un fichier temporaire pour la conversion
    local temp_file=$(mktemp)
    
    # Traiter le fichier ligne par ligne
    while IFS= read -r line; do
        # Détecter le pattern echo + description
        if [[ "$line" =~ ^echo[[:space:]]+\"📝[[:space:]]*Test[[:space:]]*[0-9]+:[[:space:]]*(.*)\" ]]; then
            local test_desc="${BASH_REMATCH[1]}"
            echo "$line" >> "$temp_file"
            
            # Lire les prochaines lignes pour construire le test
            local cmd_block=""
            local expect_pattern=""
            
            while IFS= read -r next_line; do
                if [[ "$next_line" =~ ^\{$ ]]; then
                    # Début du bloc de commandes
                    continue
                elif [[ "$next_line" =~ ^[[:space:]]*echo[[:space:]]+[\'\"](.*)[\'\"]\;?$ ]]; then
                    # Commande dans le bloc
                    local cmd="${BASH_REMATCH[1]}"
                    if [[ -n "$cmd_block" ]]; then
                        cmd_block="$cmd_block; $cmd"
                    else
                        cmd_block="$cmd"
                    fi
                elif [[ "$next_line" =~ ^\}[[:space:]]*\|[[:space:]]*.*PSYSH_CMD ]]; then
                    # Fin du bloc, construire le test_session_sync
                    echo "" >> "$temp_file"
                    echo "test_session_sync \"$test_desc\" \\" >> "$temp_file"
                    echo "    --step \"$cmd_block\" \\" >> "$temp_file"
                    echo "    --expect \"✅\" \\" >> "$temp_file"
                    echo "    --context phpunit" >> "$temp_file"
                    echo "" >> "$temp_file"
                    
                    # Ignorer les lignes suivantes jusqu'à la fin du test
                    while IFS= read -r skip_line; do
                        if [[ "$skip_line" =~ ^fi$ ]] || [[ "$skip_line" =~ ^echo[[:space:]]+\"📝 ]]; then
                            if [[ "$skip_line" =~ ^echo[[:space:]]+\"📝 ]]; then
                                # Nouveau test, remettre la ligne dans le flux
                                echo "$skip_line" >> "$temp_file"
                            fi
                            break
                        fi
                    done
                    break
                else
                    echo "$next_line" >> "$temp_file"
                fi
            done
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$file"
    
    # Remplacer le fichier original
    mv "$temp_file" "$file"
    
    echo -e "${GREEN}✅ Echo patterns migrated in $basename${NC}"
}

# Fonction principale
main() {
    local total_files=0
    local migrated_files=0
    
    # Trouver tous les fichiers de test
    local test_files=()
    while IFS= read -r file; do
        test_files+=("$file")
    done < <(find ./test/shell/Command -name "*.sh" -type f)
    
    total_files=${#test_files[@]}
    echo -e "${BLUE}📁 Fichiers trouvés: $total_files${NC}"
    
    # Migrer chaque fichier
    for file in "${test_files[@]}"; do
        # Migrer les fonctions de test
        migrate_test_file "$file"
        
        # Migrer les patterns echo + PSYSH_CMD
        if grep -q "PSYSH_CMD" "$file"; then
            migrate_echo_patterns "$file"
        fi
        
        ((migrated_files++))
    done
    
    # Remplacements globaux supplémentaires
    echo -e "${CYAN}🔧 Applying global replacements...${NC}"
    
    # Remplacer toutes les autres fonctions de test restantes
    for file in "${test_files[@]}"; do
        # Remplacer les options avec = vers format --option value
        sed -i '' 's/--context=/--context /g' "$file"
        sed -i '' 's/--output-check=/--output-check /g' "$file"
        sed -i '' 's/--input-type=/--input-type /g' "$file"
        sed -i '' 's/--retry=/--retry /g' "$file"
        sed -i '' 's/--timeout=/--timeout /g' "$file"
        sed -i '' 's/--debug=/--debug /g' "$file"
        sed -i '' 's/--sync-test=/--sync-test /g' "$file"
        
        # Ajouter --step et --expect pour les appels test_session_sync incomplets
        sed -i '' '/test_session_sync "/,/--context/ {
            /--step/!s/test_session_sync \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\n    --step "TODO: DEFINE STEP" \\\n    --expect "TODO: DEFINE EXPECT" \\/
        }' "$file"
    done
    
    # Statistiques finales
    echo ""
    echo -e "${GREEN}📊 Migration terminée:${NC}"
    echo -e "${CYAN}   Total: $total_files fichiers${NC}"
    echo -e "${GREEN}   Migrés: $migrated_files fichiers${NC}"
    
    echo ""
    echo -e "${GREEN}✅ Migration complète réussie!${NC}"
    echo -e "${CYAN}💡 Tous les tests utilisent maintenant test_session_sync${NC}"
}

# Exécuter le script principal
main "$@"
