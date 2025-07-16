#!/bin/bash

# Test 08: Gestion des erreurs
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 08: Gestion des erreurs"

# Étape 1: Test division par zéro
'$x = 10 / 0;' \
test_session_sync "Division par zéro" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Division by zero|DivisionByZeroError|Error:.*[Dd]ivision)'

# Étape 2: Variable non définie
'echo $undefined_variable;' \
test_session_sync "Variable non définie" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Undefined variable|Error:.*Undefined variable|Notice|Warning|TypeError)'

# Étape 3: Fonction inexistante
'nonexistent_function();' \
test_session_sync "Fonction inexistante" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Call to undefined function|Error:.*undefined function|Fatal error|TypeError)'

# Étape 4: Erreur de syntaxe PHP
'if ($x) { echo "test";' \
test_session_sync "Erreur de syntaxe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(PARSE ERROR|Parse error|syntax error|unexpected|Error:.*syntax error|Error:.*Unclosed|Syntax error|PHP Parse error|TypeError.*null given)'

# Étape 5: Accès à un index inexistant
'$arr = [1, 2, 3]; echo $arr[10];' \
test_session_sync "Index array inexistant" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Undefined array key|Undefined offset|Notice|Warning|Error:.*Undefined)'

# Étape 6: Test de propriété inexistante sur objet
'$obj = new stdClass(); echo $obj->nonexistent;' \
test_session_sync "Propriété objet inexistante" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Undefined property|Notice|Warning|Error:.*Undefined property)'

# Étape 7: Erreur de type (appel sur null)
'$null = null; $null->method();' \
test_session_sync "Appel méthode sur null" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Call to a member function|Fatal error|Error:.*on null)'

# Étape 8: Vérifier que les erreurs ne cassent pas le shell
'$undefined_var = null;' \
test_session_sync "Shell après erreur" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
'echo 2 + 2' \
'4'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
