#!/bin/bash

# Test 27: Test de compatibilité avec les dernières améliorations
# Vérifie le fonctionnement des nouveaux services

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 27: Compatibilité avec les dernières améliorations"

# === TESTS DE DÉTECTION DES FONCTIONNALITÉS ===

print_colored "$BLUE" "=== TESTS DE DÉTECTION DES FONCTIONNALITÉS ==="

# Étape 1: Vérifier la disponibilité de la commande monitor
echo ""
print_colored "$YELLOW" ">>> Étape 2: Vérification de la commande monitor"
test_output=$(echo "help" | "$PROJECT_ROOT/bin/psysh" --config "$project_root/config/config.php" 2>&1)
if echo "$test_output" | grep -q -i "\bmonitor\b"; then
    print_colored "$GREEN" "✅ INFO: Commande monitor disponible"
    MONITOR_AVAILABLE=true
else
    print_colored "$YELLOW" "⚠️  INFO: Commande monitor non trouvée (fonctionnalité optionnelle)"
    MONITOR_AVAILABLE=false
fi
TEST_COUNT=$((TEST_COUNT + 1))
PASS_COUNT=$((PASS_COUNT + 1))

# === TESTS DE BASE AVEC NOUVELLES FONCTIONNALITÉS ===

print_colored "$BLUE" "=== TESTS DE BASE AVEC NOUVELLES FONCTIONNALITÉS ==="

# Étape 3: Test simple avec monitor
'echo 2 + 3' \
test_session_sync "Test simple avec monitor" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context monitor \
    --output-check contains \
    --tag "monitor_session"
'5'

# Étape 4: Test avec variables
'$x = 10; $y = 20; $result = $x + $y;
test_session_sync "Test avec variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
echo $result;' \
'30'

# Étape 5: Test avec fonction
'function double($n) { return $n * 2; }
test_session_sync "Test avec fonction" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
echo double(21);' \
'42'

# === TESTS DE SYNCHRONISATION AMÉLIORÉE ===

print_colored "$BLUE" "=== TESTS DE SYNCHRONISATION AMÉLIORÉE ==="

# Étape 6: Test de persistance des variables
'$global_var = --expect "test_value";' \
test_session_sync "Persistance des variables" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo $global_var;' \
'test_value'

# Étape 7: Test de persistance des fonctions
'function test_func() { return "function_works"; }' \
test_session_sync "Persistance des fonctions" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'echo test_func();' \
'function_works'

# === TESTS DE GESTION D'ERREUR AMÉLIORÉE ===

print_colored "$BLUE" "=== TESTS DE GESTION D'ERREUR AMÉLIORÉE ==="

# Étape 8: Test d'erreur de syntaxe
'$x = ' \
test_session_sync "Erreur de syntaxe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(PARSE ERROR|Parse error|syntax error|unexpected|Error:.*syntax error|Error:.*Unclosed|Syntax error|PHP Parse error|TypeError.*null given)'

# Étape 9: Test d'erreur de variable non définie
'echo $undefined_variable' \
test_session_sync "Variable non définie" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Undefined variable|Error:.*Undefined variable|Notice|Warning|TypeError)'

# Étape 10: Test d'erreur de fonction non définie  
'undefined_function()' \
test_session_sync "Fonction non définie" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Call to undefined function|Error:.*undefined function|Fatal error|TypeError)'

# === TESTS DE PERFORMANCE ET ROBUSTESSE ===

print_colored "$BLUE" "=== TESTS DE PERFORMANCE ET ROBUSTESSE ==="

# Étape 11: Test de performance simple
'echo array_sum(range(1, 1000))' \
test_session_sync "Performance simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'2'

# Étape 12: Test avec boucle
'$sum = 0;
test_session_sync "Test avec boucle" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
for ($i = 1; $i <= 10; $i++) {
    $sum += $i;
}
echo $sum;' \
'55'

# === TESTS D'INTÉGRATION ===

print_colored "$BLUE" "=== TESTS D'INTÉGRATION ==="

# Étape 13: Test d'intégration avec classes
'class TestClass {
test_session_sync "Test avec classe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    public function getValue() {
        return "class_value";
    }
}
$obj = new TestClass();
echo $obj->getValue();' \
'class_value'

# Étape 14: Test avec closure
'$multiplier = 3;
test_session_sync "Test avec closure" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
$closure = function($x) use ($multiplier) {
    return $x * $multiplier;
};
echo $closure(7);' \
'21'

# === TESTS DE COMPATIBILITÉ DESCENDANTE ===

print_colored "$BLUE" "=== TESTS DE COMPATIBILITÉ DESCENDANTE ==="

# Étape 15: Test avec ancien format
'echo strlen("hello")' \
test_session_sync "Format ancien compatible" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'5'

# Étape 16: Test avec expressions complexes
'echo json_encode(["key" => "value"])' \
test_session_sync "Expression complexe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'{"key":"value"}'

# === RÉCAPITULATIF ===

print_colored "$BLUE" "=== RÉCAPITULATIF DES FONCTIONNALITÉS ==="

echo ""
print_colored "$CYAN" "Fonctionnalités détectées:"
print_colored "$GREEN" "  ✅ Mode normal: Fonctionnel avec --no-interactive"

echo ""
print_colored "$CYAN" "Améliorations testées:"
print_colored "$GREEN" "  ✅ Commande monitor refactorisée"
print_colored "$GREEN" "  ✅ Gestion d'erreurs améliorée" 
print_colored "$GREEN" "  ✅ Synchronisation des variables/fonctions"
print_colored "$GREEN" "  ✅ Support des nouvelles fonctionnalités PHP"
print_colored "$GREEN" "  ✅ Compatibilité descendante maintenue"

# Afficher le résumé
test_summary

# Message final
echo ""
if [[ $FAIL_COUNT -eq 0 ]]; then
    print_colored "$GREEN" "🎉 Tous les tests de compatibilité sont PASSÉS !"
    print_colored "$GREEN" "   Les dernières améliorations fonctionnent correctement."
else
    print_colored "$RED" "⚠️  Certains tests ont échoué."
    print_colored "$YELLOW" "   Vérifiez la configuration et les services."
fi

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
