#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
# Initialiser le test
init_test "TEST 06: Affichage temps réel"

# Définir le délai en fonction du mode
if [[ "${FAST_MODE:-}" == "1" || "${SIMPLE_MODE:-}" == "1" ]]; then
    DELAY="0"  # Pas de délai en mode rapide
else
    DELAY="200000"  # Délai normal
fi

# Étape 1: Test de progression en temps réel
test_session_sync "Boucle avec affichage progressif" \
"for(\$i = 1; \$i <= 5; \$i++) { echo \"Etape \$i/5\\n\"; if($DELAY > 0) usleep($DELAY); } echo \"Termine!\";" \
'Termine!'

# Étape 2: Test performance avec pause  
test_session_sync "Boucle avec usleep" \
"for(\$i = 1; \$i <= 3; \$i++) { if($DELAY > 0) usleep(100000); } echo \"Done\";" \
'Done'

# Afficher le résumé
test_summary

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
