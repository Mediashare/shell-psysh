#!/bin/bash

# Script de correction amélioré pour les appels test_session_sync
# Restaure d'abord les backups puis applique une conversion plus précise

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Correction améliorée des formats test_session_sync ===${NC}"
echo ""

# Fonction pour restaurer les backups
restore_backups() {
    echo -e "${YELLOW}Restauration des fichiers de backup...${NC}"
    
    local backup_count=0
    while IFS= read -r -d '' backup_file; do
        if [[ -f "$backup_file" ]]; then
            local original_file="${backup_file%.backup_*}"
            if [[ -f "$original_file" ]]; then
                mv "$backup_file" "$original_file"
                ((backup_count++))
                echo -e "  ${GREEN}✓ Restauré: $original_file${NC}"
            fi
        fi
    done < <(find "./test/shell/Command" -name "*.backup_*" -print0)
    
    echo -e "${GREEN}✅ $backup_count fichiers restaurés${NC}"
    echo ""
}

# Fonction pour convertir de manière plus précise
convert_test_calls() {
    local file="$1"
    local temp_file=$(mktemp)
    local converted=false
    
    echo -e "${YELLOW}Traitement: $file${NC}"
    
    # Traitement ligne par ligne avec un parser plus robuste
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*test_session_sync[[:space:]]+\"([^\"]+)\"[[:space:]]+(.*)$ ]]; then
            local description="${BASH_REMATCH[1]}"
            local rest="${BASH_REMATCH[2]}"
            
            # Lire les lignes suivantes jusqu'à la fin de l'appel
            local full_call="$line"
            while [[ "$rest" =~ \\[[:space:]]*$ ]]; do
                if IFS= read -r next_line; then
                    full_call="$full_call"$'\n'"$next_line"
                    rest="$next_line"
                else
                    break
                fi
            done
            
            # Extraire les arguments de l'appel complet
            local args_text=$(echo "$full_call" | sed 's/test_session_sync[[:space:]]*"[^"]*"[[:space:]]*//' | tr '\n' ' ' | sed 's/\\[[:space:]]*//g')
            
            # Parser les arguments quoted
            local args=()
            local current_arg=""
            local in_quotes=false
            local quote_char=""
            
            for (( i=0; i<${#args_text}; i++ )); do
                local char="${args_text:$i:1}"
                
                if [[ "$char" == '"' || "$char" == "'" ]]; then
                    if [[ "$in_quotes" == "false" ]]; then
                        in_quotes=true
                        quote_char="$char"
                    elif [[ "$char" == "$quote_char" ]]; then
                        in_quotes=false
                        if [[ -n "$current_arg" ]]; then
                            args+=("$current_arg")
                            current_arg=""
                        fi
                        quote_char=""
                    else
                        current_arg+="$char"
                    fi
                elif [[ "$in_quotes" == "true" ]]; then
                    current_arg+="$char"
                elif [[ "$char" =~ [[:space:]] ]]; then
                    if [[ -n "$current_arg" ]]; then
                        args+=("$current_arg")
                        current_arg=""
                    fi
                else
                    current_arg+="$char"
                fi
            done
            
            # Ajouter le dernier argument si nécessaire
            if [[ -n "$current_arg" ]]; then
                args+=("$current_arg")
            fi
            
            # Détecter le pattern et convertir
            if [[ ${#args[@]} -ge 2 ]]; then
                local step="${args[0]}"
                local expect="${args[1]}"
                local context="psysh"
                local output_check="contains"
                local tag="default_session"
                local use_shell=false
                local use_psysh=false
                
                # Déterminer le contexte basé sur la description et le contenu
                if [[ "$description" =~ phpunit|PHPUnit ]]; then
                    context="phpunit"
                    tag="phpunit_session"
                elif [[ "$description" =~ shell|Shell ]]; then
                    context="shell"
                    use_shell=true
                    tag="shell_session"
                elif [[ "$description" =~ monitor|Monitor ]]; then
                    context="monitor"
                    tag="monitor_session"
                elif [[ "$description" =~ sync|Sync ]]; then
                    context="psysh"
                    use_psysh=true
                    tag="sync_session"
                elif [[ "$step" =~ ^phpunit: ]]; then
                    context="phpunit"
                    tag="phpunit_session"
                elif [[ "$step" =~ ^psysh: ]]; then
                    context="monitor"
                    tag="monitor_session"
                else
                    context="psysh"
                    use_psysh=true
                    tag="default_session"
                fi
                
                # Déterminer l'output-check
                if [[ ${#args[@]} -ge 3 ]]; then
                    local check_arg="${args[2]}"
                    if [[ "$check_arg" =~ check_contains|contains ]]; then
                        output_check="contains"
                    elif [[ "$check_arg" =~ check_exact|exact ]]; then
                        output_check="exact"
                    elif [[ "$check_arg" =~ check_regex|regex ]]; then
                        output_check="regex"
                    elif [[ "$check_arg" =~ variable|object|array|function|class|global ]]; then
                        output_check="result"
                    fi
                fi
                
                # Nettoyer les steps qui contiennent des appels test_session_sync imbriqués
                if [[ "$step" =~ test_session_sync.*--step[[:space:]]+\"([^\"]+)\" ]]; then
                    step="${BASH_REMATCH[1]}"
                fi
                
                # Construire le nouvel appel
                local new_call="test_session_sync \"$description\" \\\\"$'\n'"    --step \"$step\" \\\\"
                
                if [[ -n "$expect" && ! "$expect" =~ ^(check_|variable|object|array|function|workflow|assertion|modification|mock|class|global|largedata|creative)$ ]]; then
                    new_call="$new_call"$'\n'"    --expect \"$expect\" \\\\"
                fi
                
                new_call="$new_call"$'\n'"    --context $context \\\\"
                new_call="$new_call"$'\n'"    --output-check $output_check \\\\"
                
                if [[ "$use_shell" == "true" ]]; then
                    new_call="$new_call"$'\n'"    --shell \\\\"
                elif [[ "$use_psysh" == "true" ]]; then
                    new_call="$new_call"$'\n'"    --psysh \\\\"
                fi
                
                new_call="$new_call"$'\n'"    --tag \"$tag\""
                
                echo "$new_call" >> "$temp_file"
                converted=true
                echo -e "  ${GREEN}✓ Converti: $description${NC}"
            else
                # Pas assez d'arguments, garder tel quel
                echo "$full_call" >> "$temp_file"
            fi
        else
            # Ligne normale
            echo "$line" >> "$temp_file"
        fi
    done < "$file"
    
    # Remplacer le fichier si converti
    if [[ "$converted" == "true" ]]; then
        mv "$temp_file" "$file"
        echo -e "  ${GREEN}✓ Fichier modifié${NC}"
    else
        rm "$temp_file"
        echo -e "  ${YELLOW}- Aucune conversion nécessaire${NC}"
    fi
    
    echo ""
}

# Fonction pour traiter les tests de synchronisation spéciaux
fix_sync_tests() {
    local file="$1"
    
    if [[ "$file" =~ sync|Sync ]]; then
        echo -e "${YELLOW}Correction spéciale synchronisation: $file${NC}"
        
        # Traiter les appels de synchronisation multi-étapes
        python3 -c "
import re
import sys

def fix_sync_call(content):
    # Pattern pour détecter les appels de synchronisation multi-lignes
    pattern = r'test_session_sync \"([^\"]+)\" \\\\\\\\\n([^\\n]+)\n([^\\n]+)\n([^\\n]+)\n([^\\n]+)\n([^\\n]+)'
    
    def replace_sync(match):
        description = match.group(1)
        # Extraire les arguments des lignes suivantes
        lines = [match.group(i) for i in range(2, 7)]
        
        # Construire le nouvel appel
        new_call = f'test_session_sync \"{description}\" \\\\\\\\\n'
        
        # Analyser chaque ligne pour déterminer le type d'étape
        for line in lines:
            line = line.strip().strip(\"'\\\"\")
            if line.startswith('\$'):
                new_call += f'    --step \"{line}\" --context psysh --psysh --tag \"sync_session\" \\\\\\\\\n'
            elif line.startswith('phpunit:'):
                new_call += f'    --step \"{line}\" --context phpunit --tag \"phpunit_session\" \\\\\\\\\n'
            elif line.startswith('echo'):
                new_call += f'    --step \"{line}\" --context shell --shell --tag \"shell_session\" \\\\\\\\\n'
            elif not line.startswith('test_session_sync') and line not in ['variable', 'object', 'array', 'function', 'class', 'global']:
                new_call += f'    --expect \"{line}\" --output-check contains'
                break
        
        return new_call
    
    return re.sub(pattern, replace_sync, content, flags=re.MULTILINE)

# Lire le fichier
with open('$file', 'r') as f:
    content = f.read()

# Appliquer les corrections
fixed_content = fix_sync_call(content)

# Écrire le fichier corrigé
with open('$file', 'w') as f:
    f.write(fixed_content)
"
        
        echo -e "  ${GREEN}✓ Synchronisation corrigée${NC}"
        echo ""
    fi
}

# Fonction principale
main() {
    echo -e "${BLUE}Phase 1: Restauration des backups${NC}"
    restore_backups
    
    echo -e "${BLUE}Phase 2: Conversion améliorée${NC}"
    
    # Trouver tous les fichiers de test
    local test_files=()
    while IFS= read -r -d '' file; do
        test_files+=("$file")
    done < <(find "./test/shell/Command" -name "*.sh" -print0)
    
    local total_files=${#test_files[@]}
    local modified_files=0
    
    echo -e "${BLUE}Traitement de $total_files fichiers...${NC}"
    echo ""
    
    # Traiter chaque fichier
    for file in "${test_files[@]}"; do
        # Créer une nouvelle sauvegarde
        cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
        
        # Convertir
        convert_test_calls "$file"
        
        # Traiter les tests de synchronisation spéciaux
        fix_sync_tests "$file"
        
        ((modified_files++))
    done
    
    echo -e "${GREEN}=== RÉSUMÉ FINAL ===${NC}"
    echo -e "${BLUE}Fichiers traités: $total_files${NC}"
    echo -e "${GREEN}Fichiers modifiés: $modified_files${NC}"
    echo ""
    echo -e "${GREEN}✅ Conversion améliorée terminée!${NC}"
    echo ""
    echo -e "${BLUE}Tests recommandés:${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Runner/test_runner_commands.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Monitor/24_test_sync_simple.sh${NC}"
}

# Exécuter le script
main "$@"
