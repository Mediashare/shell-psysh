#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

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
test_execute "Monitor simple avec echo" \
'$x = 42; echo $x;' \
"42" \
--context=monitor --input-type=echo

# Test monitor avec input multilignes
test_execute "Monitor multilignes" \
'$a = 10;
$b = 20;
$result = $a + $b;
echo $result;' \
"30" \
--context=monitor --input-type=multiline

# Test monitor avec vérification regex
test_execute "Monitor avec regex" \
'echo date("Y-m-d");' \
"[0-9]{4}-[0-9]{2}-[0-9]{2}" \
--context=monitor --output-check=regex

# Test monitor avec retry automatique
test_execute "Monitor avec retry" \
'echo "test";' \
"test" \
--context=monitor --retry=3 --timeout=5

# =============================================================================
# SECTION 2: TESTS PHPUNIT AVEC OPTIONS AVANCÉES
# =============================================================================

echo -e "${PURPLE}=== SECTION 2: Tests PHPUnit avancés ===${NC}"

# Test phpunit avec assertion complexe
test_execute "PHPUnit assert complexe" \
"assert 'array_sum([1,2,3]) == 6' --message='Array sum test'" \
"✅" \
--context=phpunit

# Test phpunit avec vérification exacte
test_execute "PHPUnit vérification exacte" \
"assert 'true'" \
"✅ Assertion réussie" \
--context=phpunit --output-check=exact

# =============================================================================
# SECTION 3: TESTS SHELL ET MIXED
# =============================================================================

echo -e "${PURPLE}=== SECTION 3: Tests Shell et Mixed ===${NC}"

# Test shell simple
test_execute "Shell simple" \
"echo 'Hello from shell'" \
"Hello from shell" \
--context=shell

# Test mixed (combinaison shell + monitor)
test_execute "Test mixte shell + monitor" \
"echo 'Setup' && monitor 'echo \"PsySH ready\";'" \
"PsySH ready" \
--context=mixed

# =============================================================================
# SECTION 4: TESTS AVEC FICHIERS
# =============================================================================

echo -e "${PURPLE}=== SECTION 4: Tests avec fichiers ===${NC}"

# Créer un fichier temporaire de test
echo 'monitor "$x = \"Hello World\"; echo $x;"' > /tmp/demo_test.txt

# Test depuis fichier
test_from_file "Test depuis fichier" "/tmp/demo_test.txt" "Hello World"

# Nettoyage
rm -f /tmp/demo_test.txt

# =============================================================================
# SECTION 5: TESTS D'ERREURS ET PATTERNS
# =============================================================================

echo -e "${PURPLE}=== SECTION 5: Tests d'erreurs ===${NC}"

# Test d'erreur avec pattern spécifique
test_error_pattern "Pattern d'erreur" \
'undefined_function();' \
"Call to undefined function"

# Test avec vérification d'erreur
test_execute "Test d'erreur attendue" \
'1/0;' \
"Division by zero" \
--context=monitor --output-check=error

# =============================================================================
# SECTION 6: TESTS DE SYNCHRONISATION
# =============================================================================

echo -e "${PURPLE}=== SECTION 6: Tests de synchronisation ===${NC}"

# Test de synchronisation bidirectionnelle
test_execute "Synchronisation variables" \
'$global_var = 123;' \
"123" \
--context=monitor --sync-test

# =============================================================================
# SECTION 7: TESTS COMBINÉS ET COMPLEXES
# =============================================================================

echo -e "${PURPLE}=== SECTION 7: Tests combinés ===${NC}"

# Test combiné multiple commandes
test_combined_commands "Combinaison complexe" \
'$x = 5;' \
'$y = 10;' \
'echo $x + $y;' \
"15"

# =============================================================================
# SECTION 8: TESTS DE PERFORMANCE ET LIMITES
# =============================================================================

echo -e "${PURPLE}=== SECTION 8: Tests de performance ===${NC}"

# Test avec timeout court
test_execute "Test avec timeout" \
'sleep(1); echo \"done\";' \
"done" \
--context=monitor --timeout=2

# Test avec debug activé
test_execute "Test avec debug" \
'echo \"debug test\";' \
"debug test" \
--context=monitor --debug

# =============================================================================
# SECTION 9: DÉMONSTRATION DES TYPES DE VÉRIFICATION
# =============================================================================

echo -e "${PURPLE}=== SECTION 9: Types de vérification ===${NC}"

# Vérification contains (par défaut)
test_execute "Vérification contains" \
'echo \"Hello World\";' \
"World" \
--context=monitor --output-check=contains

# Vérification exacte
test_execute "Vérification exacte" \
'echo "42";' \
"42" \
--context=monitor --output-check=exact

# Vérification regex
test_execute "Vérification regex" \
'echo \"test123\";' \
"test[0-9]+" \
--context=monitor --output-check=regex

# Vérification négative
test_execute "Vérification négative" \
'echo "success";' \
"error" \
--context=monitor --output-check=not_contains

# =============================================================================
# SECTION 10: UTILISATION DES FONCTIONS DE CONVENANCE
# =============================================================================

echo -e "${PURPLE}=== SECTION 10: Fonctions de convenance ===${NC}"

# Utilisation des fonctions héritées pour backward compatibility
test_monitor "Monitor simple legacy" 'echo "legacy test";' "legacy test"
test_monitor_multiline "Monitor multilignes legacy" '$x = "test"; echo $x;' "test"
test_monitor_expression "Monitor expression legacy" 'array_sum([1,2,3])' "6"
test_monitor_error "Monitor erreur legacy" 'undefined_var' "Undefined"
test_phpunit "PHPUnit legacy" 'assert "true"' "✅"

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
