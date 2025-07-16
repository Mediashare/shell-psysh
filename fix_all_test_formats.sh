#!/bin/bash

# Script complet pour corriger tous les formats test_session_sync incorrects
# Analyse et corrige tous les patterns d'appel selon les règles spécifiées

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Correction complète des formats test_session_sync ===${NC}"
echo ""

# Compteurs globaux
TOTAL_FILES=0
MODIFIED_FILES=0
TOTAL_CONVERSIONS=0

# Fonction pour analyser et corriger un fichier
fix_test_file() {
    local file="$1"
    local temp_file=$(mktemp)
    local converted=false
    
    echo -e "${YELLOW}Analyse: $file${NC}"
    
    # Créer backup
    cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
    
    # Lire le fichier et traiter ligne par ligne
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*test_session_sync[[:space:]]+\"([^\"]+)\"[[:space:]]+(.*)$ ]]; then
            local description="${BASH_REMATCH[1]}"
            local rest="${BASH_REMATCH[2]}"
            
            # Lire les lignes suivantes si nécessaire
            local full_call="$line"
            while [[ "$rest" =~ \\[[:space:]]*$ ]]; do
                if IFS= read -r next_line; then
                    full_call="$full_call"$'\n'"$next_line"
                    rest="$next_line"
                else
                    break
                fi
            done
            
            # Analyser et corriger selon le pattern détecté
            if [[ "$full_call" =~ test_session_sync.*\"Test\ command\".*--step ]]; then
                # Pattern: test_session_sync "desc" "test_session_sync "Test command" --step "cmd"" "expect" "check"
                fix_nested_test_session_sync "$full_call" "$description" >> "$temp_file"
                converted=true
                ((TOTAL_CONVERSIONS++))
                echo -e "  ${GREEN}✓ Corrigé format imbriqué: $description${NC}"
                
            elif [[ "$full_call" =~ test_session_sync.*\'.*\'.*\'.*\'.*\'.*\' ]]; then
                # Pattern: test_session_sync "desc" 'arg1' 'arg2' 'arg3' 'arg4' 'arg5' (synchronisation)
                fix_sync_test_format "$full_call" "$description" >> "$temp_file"
                converted=true
                ((TOTAL_CONVERSIONS++))
                echo -e "  ${GREEN}✓ Corrigé format synchronisation: $description${NC}"
                
            elif [[ "$full_call" =~ test_session_sync.*\".*\".*\".*\".*\".*\" ]]; then
                # Pattern: test_session_sync "desc" "cmd" "expect" "check"
                fix_simple_test_format "$full_call" "$description" >> "$temp_file"
                converted=true
                ((TOTAL_CONVERSIONS++))
                echo -e "  ${GREEN}✓ Corrigé format simple: $description${NC}"
                
            elif [[ "$full_call" =~ --step.*--step.*--step ]]; then
                # Pattern: test_session_sync avec multiples --step sur une ligne
                fix_multi_step_format "$full_call" "$description" >> "$temp_file"
                converted=true
                ((TOTAL_CONVERSIONS++))
                echo -e "  ${GREEN}✓ Corrigé format multi-étapes: $description${NC}"
                
            else
                # Garder tel quel si déjà bien formaté
                echo "$full_call" >> "$temp_file"
            fi
        else
            # Ligne normale
            echo "$line" >> "$temp_file"
        fi
    done < "$file"
    
    # Remplacer le fichier si des conversions ont été faites
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

# Fonction pour corriger les appels test_session_sync imbriqués
fix_nested_test_session_sync() {
    local full_call="$1"
    local description="$2"
    
    # Extraire la commande du --step imbriqué
    local step_cmd=""
    if [[ "$full_call" =~ --step[[:space:]]+\"([^\"]+)\" ]]; then
        step_cmd="${BASH_REMATCH[1]}"
    fi
    
    # Extraire l'expectation (ligne suivante généralement)
    local expect=""
    if [[ "$full_call" =~ \"([^\"]+)\"[[:space:]]*\\[[:space:]]*$.*\"([^\"]+)\" ]]; then
        expect="${BASH_REMATCH[2]}"
    fi
    
    # Déterminer le contexte et l'output-check
    local context="psysh"
    local output_check="contains"
    local tag="default_session"
    local shell_flag=""
    local psysh_flag=""
    
    if [[ "$step_cmd" =~ ^phpunit: ]]; then
        context="phpunit"
        tag="phpunit_session"
    elif [[ "$step_cmd" =~ ^psysh: ]]; then
        context="monitor"
        tag="monitor_session"
    elif [[ "$description" =~ shell|Shell ]]; then
        context="shell"
        tag="shell_session"
        shell_flag="--shell"
    else
        context="psysh"
        psysh_flag="--psysh"
    fi
    
    # Construire la version corrigée
    echo "test_session_sync \"$description\" \\"
    echo "    --step \"$step_cmd\" \\"
    echo "    --expect \"$expect\" \\"
    echo "    --context $context \\"
    echo "    --output-check $output_check \\"
    if [[ -n "$shell_flag" ]]; then
        echo "    $shell_flag \\"
    elif [[ -n "$psysh_flag" ]]; then
        echo "    $psysh_flag \\"
    fi
    echo "    --tag \"$tag\""
}

# Fonction pour corriger les tests de synchronisation
fix_sync_test_format() {
    local full_call="$1"
    local description="$2"
    
    # Extraire les 5 arguments entre guillemets simples
    local args=()
    while [[ "$full_call" =~ \'([^\']+)\' ]]; do
        args+=("${BASH_REMATCH[1]}")
        full_call="${full_call/\'${BASH_REMATCH[1]}\'/_REPLACED_}"
    done
    
    if [[ ${#args[@]} -ge 4 ]]; then
        local step1="${args[0]}"
        local step2="${args[1]}"
        local step3="${args[2]}"
        local expect="${args[3]}"
        
        # Construire la version corrigée avec multiples étapes
        echo "test_session_sync \"$description\" \\"
        
        # Première étape (généralement psysh)
        if [[ "$step1" =~ ^\$ ]]; then
            echo "    --step '$step1' \\"
            echo "    --context psysh \\"
            echo "    --psysh \\"
            echo "    --tag \"sync_session\" \\"
        fi
        
        # Deuxième étape (généralement phpunit)
        if [[ "$step2" =~ ^phpunit: ]]; then
            echo "    --step '$step2' \\"
            echo "    --context phpunit \\"
            echo "    --tag \"phpunit_session\" \\"
            echo "    --expect \"✅ Test créé :\" \\"
            echo "    --output-check contains \\"
        fi
        
        # Troisième étape (généralement shell)
        if [[ "$step3" =~ ^echo ]]; then
            echo "    --step '$step3' \\"
            echo "    --context shell \\"
            echo "    --shell \\"
            echo "    --tag \"shell_session\" \\"
        fi
        
        # Expectation finale
        echo "    --expect \"$expect\" \\"
        echo "    --output-check exact"
    else
        echo "$full_call"
    fi
}

# Fonction pour corriger les tests simples
fix_simple_test_format() {
    local full_call="$1"
    local description="$2"
    
    # Extraire les arguments entre guillemets doubles
    local args=()
    local temp_call="$full_call"
    while [[ "$temp_call" =~ \"([^\"]+)\" ]]; do
        args+=("${BASH_REMATCH[1]}")
        temp_call="${temp_call/\"${BASH_REMATCH[1]}\"/_REPLACED_}"
    done
    
    if [[ ${#args[@]} -ge 3 ]]; then
        local step="${args[1]}"
        local expect="${args[2]}"
        local check="${args[3]:-contains}"
        
        # Déterminer le contexte
        local context="psysh"
        local tag="default_session"
        local shell_flag=""
        local psysh_flag=""
        
        if [[ "$step" =~ ^phpunit: ]]; then
            context="phpunit"
            tag="phpunit_session"
        elif [[ "$step" =~ ^psysh: ]]; then
            context="monitor"
            tag="monitor_session"
        elif [[ "$description" =~ shell|Shell ]]; then
            context="shell"
            tag="shell_session"
            shell_flag="--shell"
        else
            context="psysh"
            psysh_flag="--psysh"
        fi
        
        # Convertir check_contains en contains
        local output_check="contains"
        if [[ "$check" =~ exact ]]; then
            output_check="exact"
        elif [[ "$check" =~ regex ]]; then
            output_check="regex"
        fi
        
        # Construire la version corrigée
        echo "test_session_sync \"$description\" \\"
        echo "    --step \"$step\" \\"
        echo "    --expect \"$expect\" \\"
        echo "    --context $context \\"
        echo "    --output-check $output_check \\"
        if [[ -n "$shell_flag" ]]; then
            echo "    $shell_flag \\"
        elif [[ -n "$psysh_flag" ]]; then
            echo "    $psysh_flag \\"
        fi
        echo "    --tag \"$tag\""
    else
        echo "$full_call"
    fi
}

# Fonction pour corriger les formats multi-étapes sur une ligne
fix_multi_step_format() {
    local full_call="$1"
    local description="$2"
    
    # Séparer les étapes multiples
    local steps=()
    local contexts=()
    local tags=()
    local expects=()
    
    # Analyser chaque --step
    while [[ "$full_call" =~ --step[[:space:]]+\'([^\']+)\'[[:space:]]+--context[[:space:]]+([^[:space:]]+)[[:space:]]+.*--tag[[:space:]]+\"([^\"]+)\" ]]; do
        steps+=("${BASH_REMATCH[1]}")
        contexts+=("${BASH_REMATCH[2]}")
        tags+=("${BASH_REMATCH[3]}")
        full_call="${full_call/--step[[:space:]]+\'${BASH_REMATCH[1]}\'/_REPLACED_}"
    done
    
    # Extraire l'expectation
    if [[ "$full_call" =~ --expect[[:space:]]+\"([^\"]+)\" ]]; then
        expects+=("${BASH_REMATCH[1]}")
    fi
    
    # Reconstruire avec format correct
    echo "test_session_sync \"$description\" \\"
    
    for i in "${!steps[@]}"; do
        echo "    --step '${steps[i]}' \\"
        echo "    --context ${contexts[i]} \\"
        
        # Ajouter --shell ou --psysh selon le contexte
        if [[ "${contexts[i]}" == "shell" ]]; then
            echo "    --shell \\"
        elif [[ "${contexts[i]}" == "psysh" ]]; then
            echo "    --psysh \\"
        fi
        
        echo "    --tag \"${tags[i]}\" \\"
        
        # Ajouter expectation seulement à la dernière étape
        if [[ $i -eq $((${#steps[@]} - 1)) && ${#expects[@]} -gt 0 ]]; then
            echo "    --expect \"${expects[0]}\" \\"
            echo "    --output-check contains"
        fi
    done
}

# Fonction principale
main() {
    echo -e "${BLUE}Recherche des fichiers de test...${NC}"
    
    # Trouver tous les fichiers .sh dans ./test/shell/Command
    local test_files=()
    while IFS= read -r -d '' file; do
        # Ignorer les fichiers de backup
        if [[ ! "$file" =~ \.backup ]]; then
            test_files+=("$file")
        fi
    done < <(find "./test/shell/Command" -name "*.sh" -print0)
    
    TOTAL_FILES=${#test_files[@]}
    echo -e "${BLUE}Trouvé $TOTAL_FILES fichiers de test${NC}"
    echo ""
    
    # Traiter chaque fichier
    for file in "${test_files[@]}"; do
        fix_test_file "$file"
    done
    
    echo -e "${GREEN}=== RÉSUMÉ FINAL ===${NC}"
    echo -e "${BLUE}Fichiers analysés: $TOTAL_FILES${NC}"
    echo -e "${GREEN}Fichiers modifiés: $MODIFIED_FILES${NC}"
    echo -e "${YELLOW}Conversions effectuées: $TOTAL_CONVERSIONS${NC}"
    echo ""
    echo -e "${GREEN}✅ Correction complète terminée!${NC}"
    echo ""
    echo -e "${BLUE}Formats corrigés vers le nouveau système test_session_sync avec:${NC}"
    echo -e "${GREEN}  ✓ Options --step, --expect, --context, --output-check${NC}"
    echo -e "${GREEN}  ✓ Options --shell et --psysh pour forcer le contexte${NC}"
    echo -e "${GREEN}  ✓ Options --tag pour gérer les sessions${NC}"
    echo -e "${GREEN}  ✓ Support des tests multi-étapes avec différents contextes${NC}"
    echo ""
    echo -e "${BLUE}Tests recommandés pour validation:${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Runner/test_runner_commands.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Monitor/24_test_sync_simple.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/PHPUnit/test_phpunit_create.sh${NC}"
}

# Exécuter le script
main "$@"
