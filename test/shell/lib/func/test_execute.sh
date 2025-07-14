#!/bin/bash

# Fonction principale pour exécuter tous types de tests
# Usage: test_execute [OPTIONS] "description" "command" "expected"
# 
# OPTIONS:
#   --context=TYPE         : monitor, phpunit, shell, mixed, psysh
#   --input-type=TYPE      : pipe, file, echo, interactive, multiline
#   --output-check=TYPE    : contains, exact, regex, json, error
#   --sync-test           : active le test de synchronisation bidirectionnelle
#   --timeout=SECONDS     : timeout pour l'exécution
#   --retry=COUNT         : nombre de tentatives en cas d'échec
#   --debug               : mode debug avec détails complets
#
# Options globales
# - Description des arguments
# - Commande à exécuter
# - Résultat attendu
#
# Fonctionnalités avancées :
# - Réessai en cas d'échec
# - Timeout configurable
# - Debug et analyse du contexte
# - Synchronisation intermédiaire...
#
test_execute() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    # Vérifier si le command est un heredoc (commence par un saut de ligne)
    if [[ "$command" == $'\n'* ]]; then
        # C'est un heredoc, le traiter comme tel
        command="$(echo "$command" | sed '/^$/d')"
    fi
    
    # Parser les arguments additionnels
    shift 3
    parse_test_args "$@"
    
    # Configuration par défaut
    local context="${TEST_ARG_CONTEXT:-monitor}"
    local input_type="${TEST_ARG_INPUT_TYPE:-echo}"
    local output_check="${TEST_ARG_OUTPUT_CHECK:-contains}"
    local timeout="${TEST_ARG_TIMEOUT:-30}"
    local retry_count="${TEST_ARG_RETRY:-1}"
    local sync_test="${TEST_ARG_SYNC_TEST:-false}"
    local debug="${TEST_ARG_DEBUG:-false}"
    
    ((TEST_COUNT++))
    
    echo -e "${BLUE}\u001b[1m\u001b[32mEtape $TEST_COUNT: $description${NC}"
    
    if [[ "$debug" == "true" || "$DEBUG_MODE" == "1" ]]; then
        echo -e "${CYAN}[DEBUG] Etape $TEST_COUNT - Context: $context | Input: $input_type | Check: $output_check${NC}"
        echo -e "${CYAN}[DEBUG] Etape $TEST_COUNT - Command: $command${NC}"
        echo -e "${CYAN}[DEBUG] Etape $TEST_COUNT - Expected: $expected${NC}"
    fi
    
    local result=""
    local actual_output=""
    local success=false
    local attempt=1
    
    while [[ $attempt -le $retry_count ]]; do
        if [[ $retry_count -gt 1 ]]; then
            echo -e "${YELLOW}[Tentative $attempt/$retry_count]${NC}"
        fi
        
        # Capturer l'output avec un fichier temporaire pour éviter les problèmes de capture
        local temp_output_file=$(mktemp)
        
        # Exécuter selon le contexte et le type d'input
        case "$context" in
            "monitor")
                execute_monitor_test "$command" "$input_type" "$timeout" > "$temp_output_file" 2>&1
                local exit_status=$?
                ;;
            "phpunit")
                execute_phpunit_test "$command" "$input_type" "$timeout" > "$temp_output_file" 2>&1
                local exit_status=$?
                ;;
            "shell")
                execute_shell_test "$command" "$input_type" "$timeout" > "$temp_output_file" 2>&1
                local exit_status=$?
                ;;
            "psysh")
                execute_psysh_test "$command" "$input_type" "$timeout" > "$temp_output_file" 2>&1
                local exit_status=$?
                ;;
            "mixed")
                execute_mixed_test "$command" "$input_type" "$timeout" > "$temp_output_file" 2>&1
                local exit_status=$?
                ;;
            *)
                echo -e "${RED}❌ ERREUR: Contexte inconnu '$context'${NC}"
                rm -f "$temp_output_file"
                return 1
                ;;
        esac
        
        # Lire l'output capturé
        result=$(cat "$temp_output_file")
        
        # Nettoyer l'output pour extraire seulement la partie utile
        # Supprimer les lignes de debug et les messages de système
        actual_output=$(echo "$result" | grep -v "\[DEBUG\]" | grep -v "🔍 Monitoring" | grep -v "✅ Execution completed" | grep -v "PHP Warning" | grep -v "Warning:" | grep -v "Call Stack:" | grep -v "PHP Stack trace:" | head -10 | tail -5 | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Si actual_output est vide, utiliser result comme fallback
        if [[ -z "$actual_output" ]]; then
            actual_output="$result"
        fi
        
        # Nettoyer le fichier temporaire
        rm -f "$temp_output_file"
        
        # Afficher l'output en mode debug
        if [[ "$debug" == "true" || "$DEBUG_MODE" == "1" ]]; then
            echo -e "${CYAN}[DEBUG] Etape $TEST_COUNT - Raw Output: $result${NC}"
            echo -e "${CYAN}[DEBUG] Etape $TEST_COUNT - ACTUAL: $actual_output${NC}"
            echo -e "${CYAN}[DEBUG] Etape $TEST_COUNT - Exit Status: $exit_status${NC}"
        fi
        
        # Vérifier le résultat selon le type de check - utiliser actual_output pour la vérification
        if check_result "$actual_output" "$expected" "$output_check"; then
            success=true
            break
        fi
        
        ((attempt++))
        if [[ $attempt -le $retry_count ]]; then
            echo -e "${YELLOW}⏳ Nouvelle tentative dans 1 seconde...${NC}"
            sleep 1
        fi
    done
    
    # Traitement du résultat
    if [[ "$success" == "true" ]]; then
        ((PASS_COUNT++))
        echo -e "${GREEN}✅ PASS: $description${NC}"
        TEST_RESULTS["$TEST_COUNT"]="PASS"
        
        # Afficher ACTUAL en mode debug même pour les succès
        if [[ "$debug" == "true" || "$DEBUG_MODE" == "1" ]]; then
            echo -e "${GREEN}[DEBUG] Etape $TEST_COUNT - SUCCESS with ACTUAL: '$actual_output'${NC}"
        fi
        
        # Test de synchronisation si demandé
        if [[ "$sync_test" == "true" ]]; then
            test_synchronization "$command" "$expected"
        fi
    else
        ((FAIL_COUNT++))
        echo -e "${RED}❌ FAIL: $description${NC}"
        echo -e "${RED}Résultat attendu: $expected${NC}"
        echo -e "${RED}Résultat obtenu (ACTUAL): $actual_output${NC}"
        echo -e "${YELLOW}Résultat brut (RAW): $result${NC}"
        TEST_RESULTS["$TEST_COUNT"]="FAIL"
        TEST_DETAILS["$TEST_COUNT"]="Expected: $expected | ACTUAL: $actual_output | RAW: $result"
    fi
    
    # Cleanup des variables temporaires
    unset_test_args
    
    return $([[ "$success" == "true" ]] && echo 0 || echo 1)
}

