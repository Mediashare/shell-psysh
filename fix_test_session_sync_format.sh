#!/bin/bash

# Script de conversion des anciens appels test_session_sync vers le nouveau format avec options
# Gère les options --step, --expect, --context, --output-check, --shell, --psysh, --tag

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs
TOTAL_FILES=0
MODIFIED_FILES=0
TOTAL_CONVERSIONS=0

echo -e "${BLUE}=== Correction des formats test_session_sync ===${NC}"
echo ""

# Fonction pour analyser et convertir un appel test_session_sync
convert_test_session_sync() {
    local file="$1"
    local temp_file=$(mktemp)
    local converted=false
    
    echo -e "${YELLOW}Traitement de: $file${NC}"
    
    # Lire le fichier ligne par ligne
    while IFS= read -r line; do
        # Détecter les appels test_session_sync mal formatés
        if [[ "$line" =~ ^[[:space:]]*test_session_sync[[:space:]]+ ]]; then
            # Extraire les arguments de l'appel test_session_sync
            local call_content="$line"
            local next_line
            
            # Lire les lignes suivantes si l'appel continue
            while IFS= read -r next_line; do
                if [[ "$next_line" =~ ^[[:space:]]*['\"].*['\"][[:space:]]*\\[[:space:]]*$ ]] || [[ "$next_line" =~ ^[[:space:]]*['\"].*['\"][[:space:]]*$ ]]; then
                    call_content="$call_content"$'\n'"$next_line"
                    if [[ ! "$next_line" =~ \\[[:space:]]*$ ]]; then
                        break
                    fi
                else
                    # Remettre la ligne dans le flux
                    echo "$next_line" >> "$temp_file"
                    break
                fi
            done
            
            # Analyser l'appel existant
            if [[ "$call_content" =~ test_session_sync[[:space:]]+\"([^\"]+)\"[[:space:]]+(.*)$ ]]; then
                local description="${BASH_REMATCH[1]}"
                local args_part="${BASH_REMATCH[2]}"
                
                # Nettoyer les arguments
                args_part=$(echo "$args_part" | sed 's/\\$//' | tr '\n' ' ')
                
                # Analyser les arguments basés sur des patterns courants
                local args=()
                local current_arg=""
                local in_quotes=false
                local quote_char=""
                
                # Parser les arguments manuellement
                for (( i=0; i<${#args_part}; i++ )); do
                    local char="${args_part:$i:1}"
                    
                    if [[ "$char" == '"' || "$char" == "'" ]]; then
                        if [[ "$in_quotes" == "false" ]]; then
                            in_quotes=true
                            quote_char="$char"
                            current_arg+="$char"
                        elif [[ "$char" == "$quote_char" ]]; then
                            in_quotes=false
                            current_arg+="$char"
                            quote_char=""
                        else
                            current_arg+="$char"
                        fi
                    elif [[ "$char" == " " && "$in_quotes" == "false" ]]; then
                        if [[ -n "$current_arg" ]]; then
                            args+=("$current_arg")
                            current_arg=""
                        fi
                    else
                        current_arg+="$char"
                    fi
                done
                
                # Ajouter le dernier argument
                if [[ -n "$current_arg" ]]; then
                    args+=("$current_arg")
                fi
                
                # Convertir selon les patterns détectés
                local converted_call=""
                local context="psysh"
                local output_check="contains"
                local use_shell=false
                local use_psysh=false
                local tag=""
                
                # Détecter le type de test basé sur le contenu
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
                else
                    context="psysh"
                    use_psysh=true
                    tag="default_session"
                fi
                
                # Déterminer l'output-check basé sur les arguments
                if [[ "${args[*]}" =~ check_contains|contains ]]; then
                    output_check="contains"
                elif [[ "${args[*]}" =~ check_exact|exact ]]; then
                    output_check="exact"
                elif [[ "${args[*]}" =~ check_regex|regex ]]; then
                    output_check="regex"
                elif [[ "${args[*]}" =~ result ]]; then
                    output_check="result"
                else
                    output_check="contains"
                fi
                
                # Construire le nouvel appel
                converted_call="test_session_sync \"$description\" \\"
                
                # Analyser les arguments pour extraire les steps et expects
                local step_found=false
                local current_step=""
                local current_expect=""
                
                for arg in "${args[@]}"; do
                    # Nettoyer les guillemets
                    arg=$(echo "$arg" | sed 's/^["\x27]//' | sed 's/["\x27]$//')
                    
                    if [[ "$arg" =~ ^test_session_sync ]]; then
                        # Extraire la commande du test_session_sync imbriqué
                        if [[ "$arg" =~ --step[[:space:]]+\"([^\"]+)\" ]]; then
                            current_step="${BASH_REMATCH[1]}"
                            step_found=true
                        fi
                    elif [[ ! "$step_found" && -n "$arg" && ! "$arg" =~ ^(check_|Usage:|Error|test_value|variable|object|array|function|workflow|assertion|modification|mock|class|global|largedata|creative)$ ]]; then
                        # Premier argument non-spécial = step
                        current_step="$arg"
                        step_found=true
                    elif [[ "$step_found" && -n "$arg" && ! "$arg" =~ ^(check_|variable|object|array|function|workflow|assertion|modification|mock|class|global|largedata|creative)$ ]]; then
                        # Deuxième argument = expect
                        current_expect="$arg"
                        break
                    fi
                done
                
                # Si pas de step trouvé, utiliser le premier argument
                if [[ ! "$step_found" && ${#args[@]} -gt 0 ]]; then
                    current_step=$(echo "${args[0]}" | sed 's/^["\x27]//' | sed 's/["\x27]$//')
                fi
                
                # Si pas d'expect trouvé, utiliser le deuxième argument
                if [[ -z "$current_expect" && ${#args[@]} -gt 1 ]]; then
                    current_expect=$(echo "${args[1]}" | sed 's/^["\x27]//' | sed 's/["\x27]$//')
                fi
                
                # Construire le nouvel appel avec les options
                converted_call="$converted_call"$'\n'"    --step \"$current_step\" \\"
                if [[ -n "$current_expect" ]]; then
                    converted_call="$converted_call"$'\n'"    --expect \"$current_expect\" \\"
                fi
                converted_call="$converted_call"$'\n'"    --context $context \\"
                converted_call="$converted_call"$'\n'"    --output-check $output_check \\"
                if [[ "$use_shell" == "true" ]]; then
                    converted_call="$converted_call"$'\n'"    --shell \\"
                elif [[ "$use_psysh" == "true" ]]; then
                    converted_call="$converted_call"$'\n'"    --psysh \\"
                fi
                converted_call="$converted_call"$'\n'"    --tag \"$tag\""
                
                # Écrire l'appel converti
                echo "$converted_call" >> "$temp_file"
                converted=true
                ((TOTAL_CONVERSIONS++))
                
                echo -e "  ${GREEN}✓ Converti: $description${NC}"
                
            else
                # Appel non reconnu, le garder tel quel
                echo "$call_content" >> "$temp_file"
            fi
        else
            # Ligne normale, la garder
            echo "$line" >> "$temp_file"
        fi
    done < "$file"
    
    # Remplacer le fichier original si des conversions ont été faites
    if [[ "$converted" == "true" ]]; then
        mv "$temp_file" "$file"
        ((MODIFIED_FILES++))
        echo -e "  ${GREEN}✓ Fichier modifié${NC}"
    else
        rm "$temp_file"
        echo -e "  ${YELLOW}- Aucune conversion nécessaire${NC}"
    fi
    
    echo ""
}

# Fonction pour traiter les tests de synchronisation complexes
convert_sync_tests() {
    local file="$1"
    local temp_file=$(mktemp)
    local converted=false
    
    echo -e "${YELLOW}Traitement synchronisation: $file${NC}"
    
    # Cas spéciaux pour les tests de synchronisation
    if [[ "$file" =~ phpunit_sync|sync ]]; then
        # Conversion spéciale pour les tests de synchronisation
        sed -i '' -E "
            # Convertir test_session_sync avec multiple étapes
            s/test_session_sync \"([^\"]+)\" \\\\/test_session_sync \"\1\" \\\\/g
            
            # Ajouter les options pour les tests de synchronisation
            /test_session_sync.*Synchronisation/ {
                N
                N
                N
                s/test_session_sync \"([^\"]+)\" \\\\/test_session_sync \"\1\" \\\\/
                s/'\\\$([^']+)'/    --step \"\$\1\" --context psysh --psysh --tag \"sync_session\" \\\\/
                s/'phpunit:([^']+)'/    --step \"phpunit:\1\" --context phpunit --tag \"phpunit_session\" \\\\/
                s/'echo ([^']+)'/    --step \"echo \1\" --context shell --shell --tag \"shell_session\" \\\\/
                s/'([^']+)'/    --expect \"\1\" --output-check contains/
            }
        " "$file"
        converted=true
    fi
    
    if [[ "$converted" == "true" ]]; then
        ((MODIFIED_FILES++))
        ((TOTAL_CONVERSIONS++))
        echo -e "  ${GREEN}✓ Fichier de synchronisation modifié${NC}"
    else
        echo -e "  ${YELLOW}- Aucune conversion sync nécessaire${NC}"
    fi
    
    echo ""
}

# Fonction pour traiter les patterns spéciaux
fix_special_patterns() {
    local file="$1"
    
    echo -e "${YELLOW}Correction des patterns spéciaux: $file${NC}"
    
    # Corriger les appels test_session_sync mal formatés avec arguments imbriqués
    sed -i '' -E '
        # Corriger les appels avec test_session_sync imbriqué
        s/test_session_sync "([^"]+)" \\\\/test_session_sync "\1" \\\\/g
        s/"test_session_sync \"([^\"]+)\" --step \\\"([^\\\"]+)\\\"\"/--step "\2"/g
        
        # Ajouter les options manquantes après les steps
        /--step "[^"]*"/ {
            /--context/! s/$/& --context psysh/
            /--output-check/! s/$/& --output-check contains/
            /--tag/! s/$/& --tag "default_session"/
        }
        
        # Corriger les expects
        s/"Usage:"/--expect "Usage:"/g
        s/"test_value"/--expect "test_value"/g
        s/"120"/--expect "120"/g
        s/"40"/--expect "40"/g
        s/"1\.0"/--expect "1.0"/g
        
        # Corriger les output-checks
        s/"check_contains"/--output-check contains/g
        s/"check_exact"/--output-check exact/g
        s/"check_regex"/--output-check regex/g
        s/"variable"/--output-check result/g
        s/"object"/--output-check result/g
        s/"array"/--output-check result/g
        s/"function"/--output-check result/g
        s/"class"/--output-check result/g
        s/"global"/--output-check result/g
        
        # Ajouter les tags appropriés
        /phpunit/ s/--tag "default_session"/--tag "phpunit_session"/g
        /shell/ s/--tag "default_session"/--tag "shell_session"/g
        /monitor/ s/--tag "default_session"/--tag "monitor_session"/g
        /sync/ s/--tag "default_session"/--tag "sync_session"/g
    ' "$file"
    
    echo -e "  ${GREEN}✓ Patterns spéciaux corrigés${NC}"
    echo ""
}

# Fonction principale
main() {
    echo -e "${BLUE}Recherche des fichiers de test...${NC}"
    
    # Trouver tous les fichiers de test
    local test_files=()
    while IFS= read -r -d '' file; do
        test_files+=("$file")
    done < <(find "./test/shell/Command" -name "*.sh" -print0)
    
    TOTAL_FILES=${#test_files[@]}
    echo -e "${BLUE}Trouvé $TOTAL_FILES fichiers de test${NC}"
    echo ""
    
    # Traiter chaque fichier
    for file in "${test_files[@]}"; do
        # Créer une sauvegarde
        cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
        
        # Convertir les appels test_session_sync
        convert_test_session_sync "$file"
        
        # Traiter les tests de synchronisation spéciaux
        if [[ "$file" =~ sync|Sync ]]; then
            convert_sync_tests "$file"
        fi
        
        # Corriger les patterns spéciaux
        fix_special_patterns "$file"
        
        ((TOTAL_FILES++))
    done
    
    echo -e "${GREEN}=== RÉSUMÉ ===${NC}"
    echo -e "${BLUE}Fichiers traités: $TOTAL_FILES${NC}"
    echo -e "${GREEN}Fichiers modifiés: $MODIFIED_FILES${NC}"
    echo -e "${YELLOW}Conversions effectuées: $TOTAL_CONVERSIONS${NC}"
    echo ""
    echo -e "${GREEN}✅ Conversion terminée!${NC}"
    echo -e "${YELLOW}💡 Les fichiers originaux ont été sauvegardés avec l'extension .backup_$(date +%Y%m%d_%H%M%S)${NC}"
    echo ""
    echo -e "${BLUE}Vous pouvez maintenant tester les fichiers convertis avec:${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Runner/test_runner_commands.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh${NC}"
}

# Exécuter le script
main "$@"
