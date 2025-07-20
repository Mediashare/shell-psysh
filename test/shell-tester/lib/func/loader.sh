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
