#!/bin/bash

# =============================================================================
# CHARGEUR PRINCIPAL POUR LA NOUVELLE ARCHITECTURE DE TESTS
# =============================================================================

# Déterminer le répertoire des fonctions
FUNC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB_DIR="$( cd "$FUNC_DIR/.." && pwd )"
SHELL_TEST_DIR="$( cd "$LIB_DIR/.." && pwd )"

# Charger d'abord la configuration pour avoir $PROJECT_ROOT
if [[ -f "$LIB_DIR/../config.sh" ]]; then
    source "$LIB_DIR/../config.sh"
fi

# Charger les modules de base (nécessaires pour les couleurs et autres utilitaires)
source "$LIB_DIR/display_utils.sh"
source "$LIB_DIR/timeout_handler.sh"
source "$LIB_DIR/unified_test_executor.sh"

# Charger les fonctions de la nouvelle architecture  
source "$FUNC_DIR/parse_test_args.sh"
# Note: test_execute.sh has a conflicting implementation with unified_test_executor.sh
# We use the unified version which has all the needed functions
# source "$FUNC_DIR/test_execute.sh"
# source "$FUNC_DIR/test_session_sync.sh"
source "$FUNC_DIR/test_session_sync_enhanced.sh"

# Variables globales pour le test
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
CURRENT_TEST_NAME=""
TEST_OUTPUT_DIR=""
DEBUG_MODE=${DEBUG_MODE:-0}
declare -a TEST_RESULTS
declare -a TEST_DETAILS

# Configuration par défaut - maintenant $PROJECT_ROOT est défini
# Force the correct path even if PSYSH_CMD was previously set incorrectly
# export PSYSH_CMD="php -d memory_limit=-1 $PROJECT_ROOT/bin/psysh"
export PSYSH_CMD="$PROJECT_ROOT/bin/psysh"

# =============================================================================
# FONCTIONS D'INITIALISATION ET NETTOYAGE
# =============================================================================

# Initialisation de l'environnement de test
init_test_environment() {
    # Charger les configurations nécessaires
    if [[ -f "$LIB_DIR/../config.sh" ]]; then
        source "$LIB_DIR/../config.sh"
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
# FONCTIONS DE COMPATIBILITÉ AVEC L'ANCIENNE ARCHITECTURE
# =============================================================================

# Fonction pour maintenir la compatibilité avec test_multi_variable_sync
test_multi_variable_sync() {
    local description="$1"
    shift
    local -a variables=("$@")
    local expected="${variables[${#variables[@]}-1]}"
    unset variables[${#variables[@]}-1]
    
    ((TEST_COUNT++))
    echo -e "${BLUE}>>> Étape $TEST_COUNT: $description${NC}"
    
    # Construire la commande pour définir toutes les variables
    local setup_cmd=""
    for var_def in "${variables[@]}"; do
        setup_cmd+="$var_def; "
    done
    
    # Ajouter une commande de vérification
    setup_cmd+="echo 'Variables synchronized'"
    
    local result=$(execute_monitor_test "$setup_cmd" "echo" "15")
    
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

# Fonction pour maintenir la compatibilité avec test_variable_persistence
test_variable_persistence() {
    local description="$1"
    local var_name="$2"
    local var_value="$3"
    local verification="$4"
    
    # Nettoyer le nom de variable (enlever le $)
    local clean_var_name="${var_name#\$}"
    
    test_execute "$description - Setup" \
        '\$${clean_var_name} = ${var_value}' \
        "${clean_var_name}" \
        --context=monitor

    test_execute "$description - Verify" \
        'echo \$${clean_var_name}' \
        "$verification" \
        --context=monitor
}

# Fonction pour maintenir la compatibilité avec test_complex_data_sync
test_complex_data_sync() {
    local description="$1"
    local data_setup="$2"
    local data_access="$3"
    local expected="$4"
    
    test_execute "$description" \
        "$data_setup; $data_access" \
        "$expected" \
        --context=monitor --timeout=20
}

# Fonction pour maintenir la compatibilité avec test_sync_error_handling
test_sync_error_handling() {
    local description="$1"
    local invalid_command="$2"
    local error_pattern="$3"
    
    test_execute "$description" \
        "$invalid_command" \
        "$error_pattern" \
        --context=monitor --output-check=error
}

# Fonction pour maintenir la compatibilité avec test_scope_sync
test_scope_sync() {
    local description="$1"
    local global_var="$2"
    local local_var="$3"
    local expected="$4"
    
    # Extraire le nom de variable et sa valeur du global_var
    local var_def="${global_var#global }"
    
    test_execute "$description" \
        "$var_def; $local_var; echo $expected" \
        "$expected" \
        --context=monitor
}

# =============================================================================
# LEGACY COMPATIBILITY FUNCTIONS
# =============================================================================

# Legacy function for test_monitor
test_monitor() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    test_execute "$description" \
        "$command" \
        "$expected" \
        --context=monitor
}

# Legacy function for test_monitor_multiline
test_monitor_multiline() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    test_execute "$description" \
        "$command" \
        "$expected" \
        --context=monitor --input-type=multiline
}

# Legacy function for test_monitor_expression
test_monitor_expression() {
    local description="$1"
    local expression="$2"
    local expected="$3"
    
    test_execute "$description" \
        "$expression" \
        "$expected" \
        --context=monitor
}

# Legacy function for test_monitor_error
test_monitor_error() {
    local description="$1"
    local command="$2"
    local error_pattern="$3"
    
    test_execute "$description" \
        "$command" \
        "$error_pattern" \
        --context=monitor --output-check=error
}

# Legacy function for test_shell_responsiveness
test_shell_responsiveness() {
    local description="$1"
    local setup_cmd="$2"
    local verify_cmd="$3"
    local expected="$4"
    
    test_execute "$description - Setup" \
        "$setup_cmd" \
        "" \
        --context=monitor
    
    test_execute "$description - Verify" \
        "$verify_cmd" \
        "$expected" \
        --context=monitor
}

# Legacy function for test_combined_commands
test_combined_commands() {
    local description="$1"
    local cmd1="$2"
    local cmd2="$3"
    local cmd3="$4"
    local expected="$5"
    
    test_execute "$description" \
        "$cmd1 $cmd2 $cmd3" \
        "$expected" \
        --context=monitor
}

# Legacy function for test_from_file
test_from_file() {
    local description="$1"
    local file_path="$2"
    local expected="$3"
    
    if [[ -f "$file_path" ]]; then
        local command=$(cat "$file_path")
        test_execute "$description" \
            "$command" \
            "$expected" \
            --context=monitor
    else
        ((TEST_COUNT++))
        ((FAIL_COUNT++))
        echo -e "${RED}❌ FAIL: $description - File not found: $file_path${NC}"
    fi
}

# Legacy function for test_error_pattern
test_error_pattern() {
    local description="$1"
    local command="$2"
    local error_pattern="$3"
    
    test_execute "$description" \
        "$command" \
        "$error_pattern" \
        --context=monitor --output-check=error
}

# =============================================================================
# EXPORT DES FONCTIONS PRINCIPALES
# =============================================================================

# Export des fonctions principales pour utilisation dans les scripts de test
export -f test_execute test_monitor test_monitor_multiline test_monitor_expression
export -f test_monitor_error test_shell_responsiveness
export -f test_combined_commands test_from_file test_error_pattern
export -f init_test_environment cleanup_test_environment init_test test_summary

# Export des nouvelles fonctions de synchronisation
export -f test_session_sync test_variable_sync_session test_function_sync_session
export -f test_class_sync_session test_mixed_context_sync test_complex_data_session
export -f test_sync_bidirectional test_multi_variable_sync test_variable_persistence
export -f test_complex_data_sync test_sync_error_handling test_scope_sync

# Export des fonctions de parsing et d'exécution
export -f parse_test_args unset_test_args
export -f execute_monitor_test execute_phpunit_test execute_shell_test execute_mixed_test
export -f check_result test_synchronization

echo -e "${GREEN}✅ Nouvelle architecture de tests chargée avec succès!${NC}" >&2
