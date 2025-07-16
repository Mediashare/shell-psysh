#!/bin/bash

# Test 23: Réactivité du shell après monitor (régression)
# Test automatisé pour vérifier que le shell reste réactif après l'exécution de monitor
# Ce test vérifie la correction du bug où le shell devenait non-réactif après monitor

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 23: Réactivité du shell"

# Étape 1: Test de réactivité
'$result = 42;' \
test_session_sync "Shell responsive" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
'echo "Test OK"' \
'Test OK'

# Étape 2: Test multiple
'$result = 1+1;' \
test_session_sync "Multiple commands" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'$x = 10; echo $x' \
'10'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
