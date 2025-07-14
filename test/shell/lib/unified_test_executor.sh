#!/bin/bash

# =============================================================================
# UNIFIED TEST EXECUTOR - Architecture modulaire pour tests PsySH Enhanced
# =============================================================================
# Cette bibliothèque fournit des méthodes unifiées pour exécuter tous types 
# de tests shell psysh avec paramètres flexibles et techniques avancées

# Variables globales pour le test
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_TEST_NAME=""
TEST_OUTPUT_DIR=""
DEBUG_MODE=${DEBUG_MODE:-0}
declare -a TEST_RESULTS
declare -a TEST_DETAILS

# Variables pour la stack trace debug
DEBUG_STACK_DEPTH=0
declare -a DEBUG_FUNCTION_STACK
declare -a DEBUG_FILE_STACK

# Déterminer le répertoire du script
if [[ -z "$SHELL_TEST_DIR" ]]; then
    SHELL_TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
fi

# Source du module de timeout portable
source "$SHELL_TEST_DIR/lib/timeout_handler.sh" 2>/dev/null || {
    echo "Erreur: Impossible de charger le module timeout_handler.sh" >&2
    exit 1
}

# =============================================================================
# SYSTÈME DE TRACE DEBUG POUR STACK TRACE
# =============================================================================

# Fonction de trace debug pour suivre l'exécution des fonctions
debug_trace() {
    local action="$1"
    local func_name="$2"
    shift 2
    local params="$*"
    
    if [[ "$DEBUG_MODE" -eq "1" ]]; then
        local caller_file="${BASH_SOURCE[2]:-unknown}"
        local caller_line="${BASH_LINENO[1]:-?}"
        local current_file="${BASH_SOURCE[1]:-unknown}"
        local current_line="${BASH_LINENO[0]:-?}"
        
        local indent=$(printf "%*s" $((DEBUG_STACK_DEPTH * 2)) "")
        
        if [[ "$action" == "enter" ]]; then
            ((DEBUG_STACK_DEPTH++))
            DEBUG_FUNCTION_STACK+=("$func_name")
            DEBUG_FILE_STACK+=("$current_file")
            echo -e "${CYAN}[TRACE]${indent}📥 ENTER: ${YELLOW}$func_name()${NC} | Fichier: $(basename "$current_file"):$current_line | Appelé depuis: $(basename "$caller_file"):$caller_line${NC}"
            if [[ -n "$params" ]]; then
                echo -e "${CYAN}[TRACE]${indent}   📋 Paramètres: $params${NC}"
            fi
        elif [[ "$action" == "exit" ]]; then
            echo -e "${CYAN}[TRACE]${indent}📤 EXIT:  ${YELLOW}$func_name()${NC} | Fichier: $(basename "$current_file"):$current_line${NC}"
            if [[ ${#DEBUG_FUNCTION_STACK[@]} -gt 0 ]]; then
                unset 'DEBUG_FUNCTION_STACK[${#DEBUG_FUNCTION_STACK[@]}-1]'
            fi
            if [[ ${#DEBUG_FILE_STACK[@]} -gt 0 ]]; then
                unset 'DEBUG_FILE_STACK[${#DEBUG_FILE_STACK[@]}-1]'
            fi
            ((DEBUG_STACK_DEPTH--))
        elif [[ "$action" == "call" ]]; then
            echo -e "${CYAN}[TRACE]${indent}⚡ CALL:  ${YELLOW}$func_name()${NC} | Ligne: $current_line | Params: $params${NC}"
        fi
    fi
}

# =============================================================================
# FONCTIONS UTILITAIRES AVANCÉES
# =============================================================================

# Fonction pour parser les arguments de manière flexible
# Usage: parse_test_args "$@"
parse_test_args() {
    # Variables pour les arguments (remplace les déclarations declare -g)
    TEST_ARG_DESCRIPTION=""
    TEST_ARG_COMMAND=""
    TEST_ARG_EXPECTED=""
    TEST_ARG_INPUT_TYPE=""
    TEST_ARG_OUTPUT_CHECK=""
    TEST_ARG_TIMEOUT=""
    TEST_ARG_RETRY=""
    TEST_ARG_ERROR_PATTERN=""
    TEST_ARG_CONTEXT=""
    TEST_ARG_SYNC_TEST=""
    TEST_ARG_DEBUG=""

    while [ $# -gt 0 ]; do
        case $1 in
            --description=*|--desc=*)
                TEST_ARG_DESCRIPTION="${1#*=}"
                ;;
            --command=*|--cmd=*)
                TEST_ARG_COMMAND="${1#*=}"
                ;;
            --expected=*|--expect=*)
                TEST_ARG_EXPECTED="${1#*=}"
                ;;
            --input-type=*|--input=*)
                TEST_ARG_INPUT_TYPE="${1#*=}"
                ;;
            --output-check=*|--check=*)
                TEST_ARG_OUTPUT_CHECK="${1#*=}"
                ;;
            --timeout=*)
                TEST_ARG_TIMEOUT="${1#*=}"
                ;;
            --retry=*)
                TEST_ARG_RETRY="${1#*=}"
                ;;
            --error-pattern=*)
                TEST_ARG_ERROR_PATTERN="${1#*=}"
                ;;
            --context=*)
                TEST_ARG_CONTEXT="${1#*=}"
                ;;
            --sync-test)
                TEST_ARG_SYNC_TEST="true"
                ;;
            --debug)
                TEST_ARG_DEBUG="true"
                ;;
            *)
                # Paramètres positionnels
                if [ -z "$TEST_ARG_DESCRIPTION" ]; then
                    TEST_ARG_DESCRIPTION="$1"
                elif [ -z "$TEST_ARG_COMMAND" ]; then
                    TEST_ARG_COMMAND="$1"
                elif [ -z "$TEST_ARG_EXPECTED" ]; then
                    TEST_ARG_EXPECTED="$1"
                fi
                ;;
        esac
        shift
    done
    
    # Exporter les arguments parsés dans des variables globales
    # (plus de tableau associatif, donc cette boucle n'est plus utile)
    # for key in "${!args[@]}"; do
    #     declare -g "TEST_ARG_${key^^}"="${args[$key]}"
    # done
    #
    # Les variables sont déjà affectées directement ci-dessus
    : # no-op (compatibilité)
}

# =============================================================================
# MÉTHODE UNIFIÉE PRINCIPALE : test_execute
# =============================================================================

# Fonction principale unifiée pour exécuter tous types de tests
# Usage: test_execute [OPTIONS] "description" "command" "expected"
# 
# OPTIONS:
#   --context=TYPE         : monitor, phpunit, shell, mixed
#   --input-type=TYPE      : pipe, file, echo, interactive, multiline
#   --output-check=TYPE    : contains, exact, regex, json, error
#   --sync-test           : active le test de synchronisation bidirectionnelle
#   --timeout=SECONDS     : timeout pour l'exécution
#   --retry=COUNT         : nombre de tentatives en cas d'échec
#   --debug               : mode debug avec détails complets
#
test_execute() {
    debug_trace enter "test_execute" "desc='$1'" "cmd='$2'" "expected='$3'"
    
    local description="$1"
    local command="$2"
    local expected="$3"
    
    command=$(printf '%s' "$command")  # Assurer que les retours à la ligne sont correctement gérés

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
    
    echo -e "${BLUE}>>> Étape $TEST_COUNT: $description${NC}"
    
    if [[ "$debug" == "true" || "$DEBUG_MODE" == "1" ]]; then
        echo -e "${CYAN}[DEBUG] Context: $context | Input: $input_type | Check: $output_check${NC}"
        echo -e "${CYAN}[DEBUG] Command: $command${NC}"
        echo -e "${CYAN}[DEBUG] Expected: $expected${NC}"
    fi
    
    local result=""
    local success=false
    local attempt=1
    
    while [[ $attempt -le $retry_count ]]; do
        if [[ $retry_count -gt 1 ]]; then
            echo -e "${YELLOW}[Tentative $attempt/$retry_count]${NC}"
        fi
        
        # Exécuter selon le contexte et le type d'input
        case "$context" in
            "monitor")
                result=$(execute_monitor_test "$command" "$input_type" "$timeout")
                ;;
            "phpunit")
                result=$(execute_phpunit_test "$command" "$input_type" "$timeout")
                ;;
            "shell")
                result=$(execute_shell_test "$command" "$input_type" "$timeout")
                ;;
            "psysh")
                result=$(execute_psysh_test "$command" "$input_type" "$timeout")
                ;;
            "mixed")
                result=$(execute_mixed_test "$command" "$input_type" "$timeout")
                ;;
            *)
                echo -e "${RED}❌ ERREUR: Contexte inconnu '$context'${NC}"
                return 1
                ;;
        esac
        
        # Vérifier le résultat selon le type de check
        if check_result "$result" "$expected" "$output_check"; then
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
        
        # Test de synchronisation si demandé
        if [[ "$sync_test" == "true" ]]; then
            test_synchronization "$command" "$expected"
        fi
    else
        ((FAIL_COUNT++))
        echo -e "${RED}❌ FAIL: $description${NC}"
        echo -e "${RED}Résultat attendu: $expected${NC}"
        echo -e "${RED}Résultat obtenu: $result${NC}"
        TEST_RESULTS["$TEST_COUNT"]="FAIL"
        TEST_DETAILS["$TEST_COUNT"]="Expected: $expected | Got: $result"
    fi
    
    # Cleanup des variables temporaires
    unset_test_args
    
    debug_trace exit "test_execute"
    return $([[ "$success" == "true" ]] && echo 0 || echo 1)
}

# =============================================================================
# FONCTIONS D'EXÉCUTION SPÉCIALISÉES
# =============================================================================

# Exécution dans le contexte psysh
execute_psysh_test() {
    local command="$1"
    local input_type="$2"
    local timeout="$3"
    
    case "$input_type" in
        "multiline")
            echo "$command" | run_with_timeout "$timeout" $PSYSH_CMD 2>&1
            ;;
        "pipe")
            echo "$command" | run_with_timeout "$timeout" $PSYSH_CMD 2>&1
            ;;
        "file")
            local temp_file=$(mktemp)
            echo "$command" > "$temp_file"
            run_with_timeout "$timeout" $PSYSH_CMD < "$temp_file" 2>&1
            rm -f "$temp_file"
            ;;
        "interactive")
            # Simulation d'input interactif
            echo -e "$command\nexit" | run_with_timeout "$timeout" $PSYSH_CMD 2>&1
            ;;
        *)
            echo "$command" | run_with_timeout "$timeout" $PSYSH_CMD 2>&1
            ;;
    esac
}

# Exécution dans le contexte monitor
execute_monitor_test() {
    debug_trace enter "execute_monitor_test" "cmd='$1'" "input='$2'" "timeout=$3"
    
    local command="$1"
    local input_type="$2"
    local timeout="$3"
    
    case "$input_type" in
        "multiline")
            echo "monitor $command" | run_with_timeout "$timeout" $PSYSH_CMD 2>&1
            ;;
        "pipe")
            echo "monitor $command" | run_with_timeout "$timeout" $PSYSH_CMD 2>&1
            ;;
        "file")
            local temp_file=$(mktemp)
            echo "monitor $command" > "$temp_file"
            run_with_timeout "$timeout" $PSYSH_CMD < "$temp_file" 2>&1
            rm -f "$temp_file"
            ;;
        "interactive")
            # Simulation d'input interactif
            echo -e "monitor\n$command\nexit" | run_with_timeout "$timeout" $PSYSH_CMD 2>&1
            ;;
        *)
            debug_trace call "run_with_timeout" "timeout=$timeout" "cmd=monitor $command"
            echo -e "monitor $command" | run_with_timeout "$timeout" $PSYSH_CMD 2>&1
            ;;
    esac
    
    debug_trace exit "execute_monitor_test"
}

# Exécution dans le contexte phpunit
execute_phpunit_test() {
    local command="$1"
    local input_type="$2"
    local timeout="$3"
    
    # Préfixer avec le contexte phpunit si nécessaire
    if [[ "$command" != phpunit:* ]]; then
        command="phpunit:$command"
    fi
    
    execute_psysh_test "$command" "$input_type" "$timeout"
}

# Exécution dans le contexte shell
execute_shell_test() {
    local command="$1"
    local input_type="$2"
    local timeout="$3"
    
    case "$input_type" in
        "file")
            local temp_file=$(mktemp)
            echo "$command" > "$temp_file"
            run_with_timeout "$timeout" bash "$temp_file" 2>&1
            rm -f "$temp_file"
            ;;
        *)
            run_with_timeout "$timeout" bash -c "$command" 2>&1
            ;;
    esac
}

# Exécution mixte (combinaison de commandes)
execute_mixed_test() {
    local command="$1"
    local input_type="$2"
    local timeout="$3"
    
    # Séparer les commandes par des délimiteurs
    local IFS=$'\n'
    local commands=($(echo "$command" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g'))
    
    local combined_output=""
    for cmd in "${commands[@]}"; do
        cmd=$(echo "$cmd" | xargs)  # trim whitespace
        if [[ "$cmd" =~ ^(monitor|phpunit:) ]]; then
            combined_output+=$(execute_psysh_test "$cmd" "$input_type" "$timeout")
        else
            combined_output+=$(execute_shell_test "$cmd" "$input_type" "$timeout")
        fi
        combined_output+=$'\n'
    done
    
    echo "$combined_output"
}

# =============================================================================
# FONCTIONS DE VÉRIFICATION
# =============================================================================

# Vérification du résultat selon le type
check_result() {
    local result="$1"
    local expected="$2"
    local check_type="$3"
    
    case "$check_type" in
        "contains")
            [[ "$result" == *"$expected"* ]]
            ;;
        "exact")
            [[ "$result" == "$expected" ]]
            ;;
        "regex")
            [[ "$result" =~ $expected ]]
            ;;
        "json")
            # Vérification JSON basique
            echo "$result" | jq -e ".$expected" >/dev/null 2>&1
            ;;
        "error")
            [[ "$result" == *"$expected"* ]] || [[ $? -ne 0 ]]
            ;;
        "not_contains")
            [[ "$result" != *"$expected"* ]]
            ;;
        *)
            [[ "$result" == *"$expected"* ]]
            ;;
    esac
}

# Test de synchronisation bidirectionnelle
test_synchronization() {
    local setup_command="$1"
    local verification_command="$2"
    
    echo -e "${CYAN}🔄 Test de synchronisation...${NC}"
    
    # Étape 1: Setup
    local setup_result=$(execute_psysh_test "$setup_command" "echo" "10")
    
    # Étape 2: Vérification
    local verify_result=$(execute_psysh_test "$verification_command" "echo" "10")
    
    if [[ "$verify_result" == *"$verification_command"* ]]; then
        echo -e "${GREEN}✅ Synchronisation OK${NC}"
    else
        echo -e "${RED}❌ Synchronisation FAIL${NC}"
    fi
}

# =============================================================================
# FONCTIONS SPÉCIALISÉES POUR LA SYNCHRONISATION DE VARIABLES
# =============================================================================

# Test d'enregistrement et de synchronisation d'une variable simple
test_variable_sync() {
    local description="$1"
    local var_name="$2"
    local var_value="$3"
    local expected_result="$4"
    
    test_execute "$description" \
        '$var_name = $var_value; echo $var_name' \
        "$expected_result" \
        --context=monitor --sync-test
}

# =============================================================================
# FONCTION FLEXIBLE POUR TESTER LA SYNCHRONISATION EN SESSION UNIQUE
# =============================================================================

# Fonction principale pour tester la synchronisation dans une même session PsySH
# Usage: test_session_sync "description" --step "command1" --expect "result1" --step "command2" --expect "result2" ...
test_session_sync() {
    local description="$1"
    shift
    
    ((TEST_COUNT++))
    echo -e "${BLUE}>>> Étape $TEST_COUNT: $description${NC}"
    
    # Parser les étapes et attentes
    local steps=()
    local expectations=()
    local contexts=()
    local current_step=""
    local current_expect=""
    local current_context="monitor"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --step)
                if [[ -n "$current_step" ]]; then
                    steps+=("$current_step")
                    expectations+=("$current_expect")
                    contexts+=("$current_context")
                fi
                current_step="$2"
                current_expect=""  # Reset expectation
                current_context="monitor"  # Reset context
                shift 2
                ;;
            --expect)
                current_expect="$2"
                shift 2
                ;;
            --context)
                current_context="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}❌ Option inconnue: $1${NC}"
                return 1
                ;;
        esac
    done
    
    # Ajouter la dernière étape
    if [[ -n "$current_step" ]]; then
        steps+=("$current_step")
        expectations+=("$current_expect")
        contexts+=("$current_context")
    fi
    
    # Construire la commande complète pour une session unique
    local full_command=""
    local verification_points=()
    
    for i in "${!steps[@]}"; do
        local step="${steps[$i]}"
        local expect="${expectations[$i]}"
        local context="${contexts[$i]}"
        
        # Adapter la commande selon le contexte
        case "$context" in
            "phpunit")
                if [[ "$step" != phpunit:* ]]; then
                    step="phpunit:$step"
                fi
                ;;
            "monitor")
                if [[ "$step" != monitor* ]]; then
                    step="monitor '$step'"
                fi
                ;;
            "shell")
                # Commande shell directe dans PsySH
                ;;
        esac
        
        full_command+="$step; "
        
        # Ajouter une vérification si attendue
        if [[ -n "$expect" ]]; then
            verification_points+=("$expect")
        fi
    done
    
    # Ajouter une commande finale pour capturer l'état
    full_command+="echo '=== SESSION_SYNC_COMPLETE ==='"
    
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo -e "${CYAN}[DEBUG] Full command: $full_command${NC}"
        echo -e "${CYAN}[DEBUG] Verification points: ${verification_points[*]}${NC}"
    fi
    
    # Exécuter toute la séquence dans une session unique
    local result=$(execute_psysh_test "$full_command" "echo" "30")
    
    # Vérifier chaque point d'attente
    local all_passed=true
    for expect in "${verification_points[@]}"; do
        if [[ -n "$expect" && "$result" != *"$expect"* ]]; then
            all_passed=false
            break
        fi
    done
    
    if [[ "$all_passed" == "true" && "$result" == *"SESSION_SYNC_COMPLETE"* ]]; then
        ((PASS_COUNT++))
        echo -e "${GREEN}✅ PASS: $description${NC}"
        echo -e "${CYAN}🔄 Synchronisation réussie dans session unique${NC}"
        if [[ "$DEBUG_MODE" == "1" ]]; then
            echo -e "${CYAN}[DEBUG] Result: $result${NC}"
        fi
    else
        ((FAIL_COUNT++))
        echo -e "${RED}❌ FAIL: $description${NC}"
        echo -e "${RED}Steps: ${steps[*]}${NC}"
        echo -e "${RED}Expected: ${verification_points[*]}${NC}"
        echo -e "${RED}Got: $result${NC}"
    fi
}

# Fonction simplifiée pour tester des variables
test_variable_sync_session() {
    local description="$1"
    local var_name="$2"
    local var_value="$3"
    local verification_expr="$4"
    
    test_session_sync "$description" \
        --step "\$var_name = $var_value" \
        --expect "$var_name" \
        --step "echo \$var_name" \
        --expect "$var_value" \
        --step "$verification_expr" \
        --expect "$var_value"
}

# Fonction pour tester des fonctions
test_function_sync_session() {
    local description="$1"
    local function_def="$2"
    local function_call="$3"
    local expected_result="$4"
    
    test_session_sync "$description" \
        --step "$function_def" \
        --step "$function_call" \
        --expect "$expected_result"
}

# Fonction pour tester des classes
test_class_sync_session() {
    local description="$1"
    local class_def="$2"
    local instance_creation="$3"
    local method_call="$4"
    local expected_result="$5"
    
    test_session_sync "$description" \
        --step "$class_def" \
        --step "$instance_creation" \
        --step "$method_call" \
        --expect "$expected_result"
}

# Fonction pour tester des contextes mixtes (monitor + phpunit)
test_mixed_context_sync() {
    local description="$1"
    shift
    
    # Cette fonction accepte des triplets: context command expected
    local args=()
    while [[ $# -gt 0 ]]; do
        if [[ $# -ge 3 ]]; then
            args+=("--context" "$1" "--step" "$2" "--expect" "$3")
            shift 3
        else
            echo -e "${RED}❌ Arguments insuffisants pour test_mixed_context_sync${NC}"
            return 1
        fi
    done
    
    test_session_sync "$description" "${args[@]}"
}

# Fonction pour tester la persistance de données complexes
test_complex_data_session() {
    local description="$1"
    local setup_data="$2"
    local access_patterns="$3"
    local expected_values="$4"
    
    test_session_sync "$description" \
        --step "$setup_data" \
        --step "$access_patterns" \
        --expect "$expected_values"
}

# Test de synchronisation bidirectionnelle (version simplifiée pour compatibilité)
test_sync_bidirectional() {
    local description="$1"
    local setup_command="$2"
    local verify_command="$3"
    local expected="$4"
    
    test_session_sync "$description" \
        --step "$setup_command" \
        --step "$verify_command" \
        --expect "$expected"
}

# Test de synchronisation de plusieurs variables
test_multi_variable_sync() {
    local description="$1"
    shift
    local variables=("$@")
    local expected="${variables[-1]}"
    unset variables[-1]
    
    ((TEST_COUNT++))
    echo -e "${BLUE}>>> Étape $TEST_COUNT: $description${NC}"
    
    # Construire la commande pour définir toutes les variables
    local setup_cmd=""
    for var_def in "${variables[@]}"; do
        setup_cmd+="$var_def; "
    done
    
    # Ajouter une commande de vérification
    setup_cmd+="echo 'Variables synchronized'"
    
    local result=$(execute_psysh_test "$setup_cmd" "echo" "15")
    
    if [[ "$result" == *"$expected"* ]]; then
        ((PASS_COUNT++))
        echo -e "${GREEN}✅ PASS: $description${NC}"
        echo -e "${CYAN}🔄 Variables: ${variables[*]}${NC}"
    else
        ((FAIL_COUNT++))
        echo -e "${RED}❌ FAIL: $description${NC}"
        echo -e "${RED}Variables: ${variables[*]}${NC}"
        echo -e "${RED}Expected: $expected${NC}"
        echo -e "${RED}Got: $result${NC}"
    fi
}

# Test de persistance de variable entre sessions
test_variable_persistence() {
    local description="$1"
    local var_name="$2"
    local var_value="$3"
    local verification="$4"
    
    test_execute "$description - Setup" \
       $var_name = $var_value'" \
        "$var_name" \
        --context=monitor
    
    test_execute "$description - Verify" \
        'echo $var_name'" \
        "$verification" \
        --context=monitor
}

# Test de synchronisation avec arrays/objets complexes
test_complex_data_sync() {
    local description="$1"
    local data_setup="$2"
    local data_access="$3"
    local expected="$4"
    
    test_execute "$description" \
        '$data_setup; $data_access'" \
        "$expected" \
        --context=monitor --timeout=20
}

# Test de synchronisation avec gestion d'erreurs
test_sync_error_handling() {
    local description="$1"
    local invalid_command="$2"
    local error_pattern="$3"
    
    test_execute "$description" \
        '$invalid_command'" \
        "$error_pattern" \
        --context=monitor --output-check=error
}

# Test de synchronisation de variables globales vs locales
test_scope_sync() {
    local description="$1"
    local global_var="$2"
    local local_var="$3"
    local expected="$4"
    
    test_execute "$description" \
        'global $global_var; $local_var; echo $global_var'" \
        "$expected" \
        --context=monitor
}

# =============================================================================
# MÉTHODES DE CONVENANCE (BACKWARD COMPATIBILITY)
# =============================================================================

# Fonction de convenance pour les tests monitor simples
test_monitor() {
    test_execute "$1" "$2" "$3" --context=monitor --input-type=echo
}

# Fonction de convenance pour les tests monitor multilignes
test_monitor_multiline() {
    test_execute "$1" "$2" "$3" --context=monitor --input-type=multiline
}

# Fonction de convenance pour les tests monitor avec expressions
test_monitor_expression() {
    test_execute "$1" "$2" "$3" --context=monitor --input-type=echo
}

# Fonction de convenance pour les tests d'erreur
test_monitor_error() {
    test_execute "$1" "$2" "$3" --context=monitor --output-check=error
}

# Fonction de convenance pour les tests de responsiveness shell
test_shell_responsiveness() {
    test_execute "$1" "$2" "$4" --context=monitor --sync-test --input-type=echo
}

# Fonction de convenance pour les tests phpunit
test_phpunit() {
    test_execute "$1" "$2" "$3" --context=phpunit --input-type=echo
}

# =============================================================================
# FONCTIONS D'INITIALISATION ET NETTOYAGE
# =============================================================================

# Initialisation de l'environnement de test
init_test_environment() {
    # Charger les configurations nécessaires
    if [[ -f "$SCRIPT_DIR/../../config.sh" ]]; then
        source "$SCRIPT_DIR/../../config.sh"
    fi
    
    # Créer un répertoire temporaire pour les outputs si nécessaire
    TEST_OUTPUT_DIR=$(mktemp -d)
    export TEST_OUTPUT_DIR
    
    # Initialiser les compteurs
    TEST_COUNT=0
    PASS_COUNT=0
    FAIL_COUNT=0
    
    # Vider les arrays
    TEST_RESULTS=()
    TEST_DETAILS=()
}

# Nettoyage des variables temporaires de test
unset_test_args() {
    unset TEST_ARG_DESCRIPTION TEST_ARG_COMMAND TEST_ARG_EXPECTED
    unset TEST_ARG_INPUT_TYPE TEST_ARG_OUTPUT_CHECK TEST_ARG_TIMEOUT
    unset TEST_ARG_RETRY TEST_ARG_ERROR_PATTERN TEST_ARG_CONTEXT
    unset TEST_ARG_SYNC_TEST TEST_ARG_DEBUG
}

# Nettoyage de l'environnement de test
cleanup_test_environment() {
    if [[ -n "$TEST_OUTPUT_DIR" && -d "$TEST_OUTPUT_DIR" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
    unset_test_args
}

# Fonction pour initialiser un test spécifique
init_test() {
    local test_name="$1"
    CURRENT_TEST_NAME="$test_name"
    echo -e "${PURPLE}=== $test_name ===${NC}"
    echo ""
}

# Affichage du résumé des tests
test_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     RÉSUMÉ DU TEST                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Test: $CURRENT_TEST_NAME${NC}"
    echo -e "${BLUE}Total des étapes: $TEST_COUNT${NC}"
    echo -e "${GREEN}Étapes réussies: $PASS_COUNT${NC}"
    echo -e "${RED}Étapes échouées: $FAIL_COUNT${NC}"
    
    if [[ $FAIL_COUNT -gt 0 ]]; then
        echo ""
        echo -e "${RED}Détails des échecs:${NC}"
        for i in "${!TEST_RESULTS[@]}"; do
            if [[ "${TEST_RESULTS[$i]}" == "FAIL" ]]; then
                echo -e "${RED}  Étape $i: ${TEST_DETAILS[$i]}${NC}"
            fi
        done
        echo -e "${RED}❌ $FAIL_COUNT tests échoués sur $TEST_COUNT${NC}"
    else
        echo -e "${GREEN}🎉 Tous les tests sont PASSÉS ($PASS_COUNT/$TEST_COUNT)${NC}"
    fi
    echo ""
}

# =============================================================================
# FONCTIONS AVANCÉES POUR TESTS COMPLEXES
# =============================================================================

# Test avec combinaison de commandes
test_combined_commands() {
    local description="$1"
    shift
    local commands=("$@")
    local last_expected="${commands[-1]}"
    unset commands[-1]
    
    local combined_cmd=""
    for cmd in "${commands[@]}"; do
        combined_cmd+="$cmd; "
    done
    combined_cmd="${combined_cmd%; }"  # Remove trailing semicolon
    
    test_execute "$description" "$combined_cmd" "$last_expected" --context=mixed
}

# Test avec input depuis fichier
test_from_file() {
    local description="$1"
    local file_path="$2"
    local expected="$3"
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}❌ Fichier non trouvé: $file_path${NC}"
        return 1
    fi
    
    local content=$(cat "$file_path")
    test_execute "$description" "$content" "$expected" --input-type=file
}

# Test avec pattern d'erreur spécifique
test_error_pattern() {
    local description="$1"
    local command="$2"
    local error_pattern="$3"
    
    test_execute "$description" "$command" "$error_pattern" --output-check=error --error-pattern="$error_pattern"
}

# Export des fonctions principales pour utilisation dans les scripts de test
export -f test_execute test_monitor test_monitor_multiline test_monitor_expression
export -f test_monitor_error test_shell_responsiveness test_phpunit
export -f test_combined_commands test_from_file test_error_pattern
export -f init_test_environment cleanup_test_environment init_test test_summary
# Export des nouvelles fonctions de synchronisation
export -f test_session_sync test_variable_sync_session test_function_sync_session
export -f test_class_sync_session test_mixed_context_sync test_complex_data_session
export -f test_sync_bidirectional test_multi_variable_sync test_variable_persistence
export -f test_complex_data_sync test_sync_error_handling test_scope_sync
}
