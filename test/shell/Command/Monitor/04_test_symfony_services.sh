#!/bin/bash

# Test 04: Services Symfony
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 04: Services Symfony"

# Initialiser le Symfony Kernel
# container=$(/usr/bin/env symfony new kernel)
# kernel=$container->get('kernel');
# router=$container->get('router');

# dispatcher=$container->get('event_dispatcher');

# Étape 1: Test Container Symfony - Vérifier qu'il y a au moins 20 services
'$services = $container->getServiceIds(); $count = count($services); echo $count = 20 ? "OK: $count services" : "FAIL: only $count services"' \
test_session_sync "Container Symfony - Nombre de services (≥20)" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'OK:.*services'

# Étape 2: Test Kernel et environnement
'$kernel->getEnvironment()' \
test_session_sync "Kernel environnement" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'dev'

# Étape 3: Test Router
'$class = get_class($router->getRouteCollection()); echo $class' \
test_session_sync "Router - Collection de routes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Symfony\\Component\\Routing\\RouteCollection'

# Étape 4: Test EventDispatcher - Vérifier qu'il y a au moins quelques listeners
'$count = count($dispatcher->getListeners()); echo $count >= 3 ? "OK: $count listeners" : "FAIL: only $count listeners"' \
test_session_sync "EventDispatcher - Nombre de listeners (≥ 3)" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'OK:.*listeners'

# Étape 5: Test d'erreur - service inexistant
'$container->get("nonexistent.service")' \
test_session_sync "Service inexistant" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'non-existent service'

# Étape 6: Test d'erreur - paramètre inexistant
'$container->getParameter("nonexistent.parameter")' \
test_session_sync "Paramètre inexistant" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'non-existent parameter'

# Étape 7: Test sync - services persistants
'$my_service = $container->get("kernel");' \
test_session_sync "Services persistants" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo get_class($my_service)' \
'App\\Kernel'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
