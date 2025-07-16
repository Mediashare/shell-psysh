#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "symfony services"

# Étape 1: Test Container Symfony - Vérifier qu'il y a au moins 20 services
test_monitor_echo "Container Symfony - Nombre de services (≥20)" \
'$services = $container->getServiceIds(); $count = count($services); echo $count = 20 ? "OK: $count services" : "FAIL: only $count services"' \
'OK:.*services'

# Étape 2: Test Kernel et environnement
test_monitor_expression "Kernel environnement" \
'$kernel->getEnvironment()' \
'dev'

# Étape 3: Test Router
test_monitor_echo "Router - Collection de routes" \
'$class = get_class($router->getRouteCollection()); echo $class' \
'Symfony\\Component\\Routing\\RouteCollection'

# Étape 4: Test EventDispatcher - Vérifier qu'il y a au moins quelques listeners
test_monitor_echo "EventDispatcher - Nombre de listeners (≥ 3)" \
'$count = count($dispatcher->getListeners()); echo $count >= 3 ? "OK: $count listeners" : "FAIL: only $count listeners"' \
'OK:.*listeners'

# Étape 5: Test d'erreur - service inexistant
test_monitor_error "Service inexistant" \
'$container->get("nonexistent.service")' \
'non-existent service'

# Étape 6: Test d'erreur - paramètre inexistant
test_monitor_error "Paramètre inexistant" \
'$container->getParameter("nonexistent.parameter")' \
'non-existent parameter'

# Étape 7: Test sync - services persistants
test_shell_responsiveness "Services persistants" \
'$my_service = $container->get("kernel");' \
'echo get_class($my_service)' \
'App\\Kernel'

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
