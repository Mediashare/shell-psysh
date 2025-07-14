#!/bin/bash

# =============================================================================
# FONCTION DE PARSAGE DES ARGUMENTS DE TEST
# =============================================================================

# Fonction pour parser les arguments de manière flexible
# Usage: parse_test_args "$@"
#
# Variables exportées après parsing :
# - TEST_ARG_DESCRIPTION
# - TEST_ARG_COMMAND
# - TEST_ARG_EXPECTED
# - TEST_ARG_INPUT_TYPE
# - TEST_ARG_OUTPUT_CHECK
# - TEST_ARG_TIMEOUT
# - TEST_ARG_RETRY
# - TEST_ARG_ERROR_PATTERN
# - TEST_ARG_CONTEXT
# - TEST_ARG_SYNC_TEST
# - TEST_ARG_DEBUG
#
# Exemples d'utilisation :
#
# 1. Arguments nommés :
#    parse_test_args --description="Test simple" --command="echo hello" --expected="hello"
#
# 2. Arguments positionnels :
#    parse_test_args "Test simple" "echo hello" "hello"
#
# 3. Arguments mixtes :
#    parse_test_args "Test simple" "echo hello" "hello" --timeout=10 --retry=3
#
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
}

# Fonction pour nettoyer les variables d'arguments
unset_test_args() {
    unset TEST_ARG_DESCRIPTION TEST_ARG_COMMAND TEST_ARG_EXPECTED
    unset TEST_ARG_INPUT_TYPE TEST_ARG_OUTPUT_CHECK TEST_ARG_TIMEOUT
    unset TEST_ARG_RETRY TEST_ARG_ERROR_PATTERN TEST_ARG_CONTEXT
    unset TEST_ARG_SYNC_TEST TEST_ARG_DEBUG
}

# =============================================================================
# EXEMPLES D'UTILISATION
# =============================================================================

# Exemple 1: Arguments nommés complets
example_named_args() {
    parse_test_args \
        --description="Test avec arguments nommés" \
        --command="echo 'Hello World'" \
        --expected="Hello World" \
        --context="monitor" \
        --timeout=30 \
        --retry=2 \
        --debug
    
    echo "Description: $TEST_ARG_DESCRIPTION"
    echo "Command: $TEST_ARG_COMMAND"
    echo "Expected: $TEST_ARG_EXPECTED"
    echo "Context: $TEST_ARG_CONTEXT"
    echo "Timeout: $TEST_ARG_TIMEOUT"
    echo "Retry: $TEST_ARG_RETRY"
    echo "Debug: $TEST_ARG_DEBUG"
}

# Exemple 2: Arguments positionnels
example_positional_args() {
    parse_test_args "Test positionnel" "echo test" "test"
    
    echo "Description: $TEST_ARG_DESCRIPTION"
    echo "Command: $TEST_ARG_COMMAND"
    echo "Expected: $TEST_ARG_EXPECTED"
}

# Exemple 3: Arguments mixtes
example_mixed_args() {
    parse_test_args "Test mixte" "echo mixed" "mixed" --timeout=15 --sync-test
    
    echo "Description: $TEST_ARG_DESCRIPTION"
    echo "Command: $TEST_ARG_COMMAND"
    echo "Expected: $TEST_ARG_EXPECTED"
    echo "Timeout: $TEST_ARG_TIMEOUT"
    echo "Sync Test: $TEST_ARG_SYNC_TEST"
}

# Fonction de validation des arguments
validate_test_args() {
    local errors=()
    
    # Vérifications obligatoires
    if [[ -z "$TEST_ARG_DESCRIPTION" ]]; then
        errors+=("Description manquante")
    fi
    
    if [[ -z "$TEST_ARG_COMMAND" ]]; then
        errors+=("Commande manquante")
    fi
    
    # Vérifications optionnelles mais recommandées
    if [[ -z "$TEST_ARG_EXPECTED" ]]; then
        errors+=("Résultat attendu manquant (recommandé)")
    fi
    
    # Vérifications de format
    if [[ -n "$TEST_ARG_TIMEOUT" && ! "$TEST_ARG_TIMEOUT" =~ ^[0-9]+$ ]]; then
        errors+=("Timeout doit être un nombre entier")
    fi
    
    if [[ -n "$TEST_ARG_RETRY" && ! "$TEST_ARG_RETRY" =~ ^[0-9]+$ ]]; then
        errors+=("Retry doit être un nombre entier")
    fi
    
    if [[ -n "$TEST_ARG_CONTEXT" && ! "$TEST_ARG_CONTEXT" =~ ^(monitor|phpunit|shell|mixed)$ ]]; then
        errors+=("Context doit être : monitor, phpunit, shell, ou mixed")
    fi
    
    if [[ -n "$TEST_ARG_OUTPUT_CHECK" && ! "$TEST_ARG_OUTPUT_CHECK" =~ ^(contains|exact|regex|json|error|not_contains)$ ]]; then
        errors+=("Output check doit être : contains, exact, regex, json, error, ou not_contains")
    fi
    
    if [[ -n "$TEST_ARG_INPUT_TYPE" && ! "$TEST_ARG_INPUT_TYPE" =~ ^(pipe|file|echo|interactive|multiline)$ ]]; then
        errors+=("Input type doit être : pipe, file, echo, interactive, ou multiline")
    fi
    
    # Retourner les erreurs
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "Erreurs de validation des arguments :" >&2
        for error in "${errors[@]}"; do
            echo "  - $error" >&2
        done
        return 1
    fi
    
    return 0
}

# Fonction pour afficher l'aide sur les arguments
show_test_args_help() {
    cat << 'EOF'
Usage: parse_test_args [OPTIONS] [description] [command] [expected]

Arguments positionnels :
  description    Description du test
  command        Commande à exécuter
  expected       Résultat attendu

Options :
  --description=STR, --desc=STR
                 Description du test
  --command=STR, --cmd=STR
                 Commande à exécuter
  --expected=STR, --expect=STR
                 Résultat attendu
  --input-type=TYPE, --input=TYPE
                 Type d'entrée : pipe, file, echo, interactive, multiline
  --output-check=TYPE, --check=TYPE
                 Type de vérification : contains, exact, regex, json, error, not_contains
  --timeout=SECONDS
                 Timeout en secondes (défaut: 30)
  --retry=COUNT
                 Nombre de tentatives (défaut: 1)
  --error-pattern=STR
                 Pattern d'erreur attendu
  --context=TYPE
                 Contexte d'exécution : monitor, phpunit, shell, mixed
  --sync-test
                 Activer le test de synchronisation
  --debug
                 Activer le mode debug

Exemples :
  parse_test_args "Test simple" "echo hello" "hello"
  parse_test_args --desc="Test avancé" --cmd="echo test" --expect="test" --timeout=10
  parse_test_args "Test mixte" "echo mixed" "mixed" --retry=3 --debug

EOF
}
