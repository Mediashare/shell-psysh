#!/bin/bash

# Test 06: Affichage temps réel
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 06: Affichage temps réel"

# Définir le délai en fonction du mode
if [[ "${FAST_MODE:-}" == "1" || "${SIMPLE_MODE:-}" == "1" ]]; then
    DELAY="0"  # Pas de délai en mode rapide
else
    DELAY="200000"  # Délai normal
fi

# Étape 1: Test de progression en temps réel
"for(\$i = 1; \$i <= 5; \$i++) { echo \"Etape \$i/5\\n\"; if($DELAY > 0) usleep($DELAY); } echo \"Termine!\";" \
test_session_sync "Boucle avec affichage progressif" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Termine!'

# Étape 2: Test performance avec pause  
"for(\$i = 1; \$i <= 3; \$i++) { if($DELAY > 0) usleep(100000); } echo \"Done\";" \
test_session_sync "Boucle avec usleep" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Done'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
