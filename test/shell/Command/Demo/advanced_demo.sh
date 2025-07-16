#!/bin/bash

# =============================================================================
# DÉMONSTRATION AVANCÉE DE L'UNIFIED_TEST_EXECUTOR
# =============================================================================
# Ce script démontre toutes les capacités avancées de l'architecture modulaire
# pour tester les commandes shell psysh avec flexibilité maximale

# Obtenir le répertoire du script et charger l'exécuteur unifié
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "DÉMO AVANCÉE - Unified Test Executor"

echo -e "${YELLOW}Cette démonstration illustre toutes les capacités de la nouvelle architecture:${NC}"
echo -e "${CYAN}• Tests avec différents contextes (monitor, phpunit, shell, mixed)${NC}"
echo -e "${CYAN}• Types d'input variés (pipe, file, echo, interactive, multiline)${NC}"
echo -e "${CYAN}• Types de vérification (contains, exact, regex, json, error)${NC}"
echo -e "${CYAN}• Options avancées (retry, timeout, sync, debug)${NC}"
echo ""

# =============================================================================
# SECTION 1: TESTS MONITOR BASIQUES ET AVANCÉS
# =============================================================================

echo -e "${PURPLE}=== SECTION 1: Tests Monitor ===${NC}"

# Test monitor simple avec echo
    --step '$x = 42; echo $x;' \
test_session_sync "Monitor simple avec echo" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "42" \
    --context monitor --input-type echo

# Test monitor avec input multilignes
    --step '$a = 10;
test_session_sync "Monitor multilignes" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
$b = 20;
$result = $a + $b;
echo $result;' \
    --expect "30" \
    --context monitor --input-type multiline

# Test monitor avec vérification regex
    --step 'echo date("Y-m-d");' \
test_session_sync "Monitor avec regex" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "[0-9]{4}-[0-9]{2}-[0-9]{2}" \
    --context monitor --output-check regex

# Test monitor avec retry automatique
    --step 'echo "test";' \
test_session_sync "Monitor avec retry" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "test" \
    --context monitor --retry 3 --timeout 5

# =============================================================================
# SECTION 2: TESTS PHPUNIT AVEC OPTIONS AVANCÉES
# =============================================================================

echo -e "${PURPLE}=== SECTION 2: Tests PHPUnit avancés ===${NC}"

# Test phpunit avec assertion complexe
"assert 'array_sum([1,2,3]) == 6' --message='Array sum test'" \
test_session_sync "PHPUnit assert complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
"✅" \
--context phpunit

# Test phpunit avec vérification exacte
"assert 'true'" \
test_session_sync "PHPUnit vérification exacte" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
"✅ Assertion réussie" \
--context phpunit --output-check exact

# =============================================================================
# SECTION 3: TESTS SHELL ET MIXED
# =============================================================================

echo -e "${PURPLE}=== SECTION 3: Tests Shell et Mixed ===${NC}"

# Test shell simple
"echo 'Hello from shell'" \
test_session_sync "Shell simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
"Hello from shell" \
--context shell

# Test mixed (combinaison shell + monitor)
"echo 'Setup' && monitor 'echo \"PsySH ready\";'" \
test_session_sync "Test mixte shell + monitor" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context shell \
    --output-check contains \
    --shell \
    --tag "shell_session"
"PsySH ready" \
--context mixed

# =============================================================================
# SECTION 4: TESTS AVEC FICHIERS
# =============================================================================

echo -e "${PURPLE}=== SECTION 4: Tests avec fichiers ===${NC}"

# Créer un fichier temporaire de test
echo 'monitor "$x = \"Hello World\"; echo $x;"' > /tmp/demo_test.txt

# Test depuis fichier
    --step "cat /tmp/demo_test.txt" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "Test depuis fichier" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    --expect "Hello World" \
    --context shell

# Nettoyage
rm -f /tmp/demo_test.txt

# =============================================================================
# SECTION 5: TESTS D'ERREURS ET PATTERNS
# =============================================================================

echo -e "${PURPLE}=== SECTION 5: Tests d'erreurs ===${NC}"

# Test d'erreur avec pattern spécifique
'undefined_function();' \
test_session_sync "Pattern d'erreur" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"Call to undefined function"

# Test avec vérification d'erreur
'1/0;' \
test_session_sync "Test d'erreur attendue" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"Division by zero" \
--context monitor --output-check error

# =============================================================================
# SECTION 6: TESTS DE SYNCHRONISATION
# =============================================================================

echo -e "${PURPLE}=== SECTION 6: Tests de synchronisation ===${NC}"

# Test de synchronisation bidirectionnelle
'$global_var = 123;' \
test_session_sync "Synchronisation variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "sync_session"
"123" \
--context monitor --sync-test

# =============================================================================
# SECTION 7: TESTS COMBINÉS ET COMPLEXES
# =============================================================================

echo -e "${PURPLE}=== SECTION 7: Tests combinés ===${NC}"

# Test combiné multiple commandes
'$x = 5;' \
test_session_sync "Combinaison complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'$y = 10;' \
'echo $x + $y;' \
"15"

# =============================================================================
# SECTION 8: TESTS DE PERFORMANCE ET LIMITES
# =============================================================================

echo -e "${PURPLE}=== SECTION 8: Tests de performance ===${NC}"

# Test avec timeout court
'sleep(1); echo \"done\";' \
test_session_sync "Test avec timeout" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"done" \
--context monitor --timeout 2

# Test avec debug activé
'echo \"debug test\";' \
test_session_sync "Test avec debug" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"debug test" \
--context monitor --debug

# =============================================================================
# SECTION 9: DÉMONSTRATION DES TYPES DE VÉRIFICATION
# =============================================================================

echo -e "${PURPLE}=== SECTION 9: Types de vérification ===${NC}"

# Vérification contains (par défaut)
'echo \"Hello World\";' \
test_session_sync "Vérification contains" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"World" \
--context monitor --output-check contains

# Vérification exacte
'echo "42";' \
test_session_sync "Vérification exacte" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"42" \
--context monitor --output-check exact

# Vérification regex
'echo \"test123\";' \
test_session_sync "Vérification regex" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"test[0-9]+" \
--context monitor --output-check regex

# Vérification négative
'echo "success";' \
test_session_sync "Vérification négative" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
"error" \
--context monitor --output-check not_contains

# =============================================================================
# SECTION 10: UTILISATION DES FONCTIONS DE CONVENANCE
# =============================================================================

echo -e "${PURPLE}=== SECTION 10: Fonctions de convenance ===${NC}"

# Utilisation des fonctions héritées pour backward compatibility
    --step "echo "legacy test";" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "Monitor simple legacy" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "legacy test" \
    --context monitor
    --step '$x = \
test_session_sync "Monitor multilignes legacy" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "test" \
    --context monitor --input-type multiline; echo $x;' "test"
    --step 'array_sum([1,2,3])' \
test_session_sync "Monitor expression legacy" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "6" \
    --context monitor --output-check result
    --step 'undefined_var' \
test_session_sync "Monitor erreur legacy" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
    --expect "Undefined" \
    --context monitor --output-check error
    --step "assert "true"" \ --context psysh --output-check contains --tag "default_session"
test_session_sync "PHPUnit legacy" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"
    --expect "✅" \
    --context phpunit

# =============================================================================
# RÉSUMÉ ET NETTOYAGE
# =============================================================================

echo ""
echo -e "${GREEN}=== DÉMONSTRATION TERMINÉE ===${NC}"
echo -e "${YELLOW}Cette démonstration a illustré:${NC}"
echo -e "${CYAN}• ${TEST_COUNT} tests exécutés avec différentes configurations${NC}"
echo -e "${CYAN}• Tous les contextes disponibles (monitor, phpunit, shell, mixed)${NC}"
echo -e "${CYAN}• Tous les types d'input et de vérification${NC}"
echo -e "${CYAN}• Les options avancées (retry, timeout, sync, debug)${NC}"
echo -e "${CYAN}• La compatibilité avec les anciennes fonctions${NC}"

# Afficher le résumé détaillé
test_summary

# Nettoyage
cleanup_test_environment

# Statistiques finales
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    STATISTIQUES FINALES                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}Tests réussis: $PASS_COUNT${NC}"
echo -e "${RED}Tests échoués: $FAIL_COUNT${NC}"
echo -e "${BLUE}Taux de réussite: $(( PASS_COUNT * 100 / TEST_COUNT ))%${NC}"

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "${RED}❌ Certains tests ont échoué${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 Tous les tests sont passés!${NC}"
    exit 0
fi
