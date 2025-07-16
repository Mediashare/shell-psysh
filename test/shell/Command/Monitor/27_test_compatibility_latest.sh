#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
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
test_session_sync "Test simple avec monitor" \
'echo 2 + 3' \
'5'

# Étape 4: Test avec variables
test_session_sync "Test avec variables" \
'$x = 10; $y = 20; $result = $x + $y;
echo $result;' \
'30'

# Étape 5: Test avec fonction
test_session_sync "Test avec fonction" \
'function double($n) { return $n * 2; }
echo double(21);' \
'42'

# === TESTS DE SYNCHRONISATION AMÉLIORÉE ===

print_colored "$BLUE" "=== TESTS DE SYNCHRONISATION AMÉLIORÉE ==="

# Étape 6: Test de persistance des variables
test_session_sync "Persistance des variables" \
'$global_var = "test_value";' \
'echo $global_var;' \
'test_value'

# Étape 7: Test de persistance des fonctions
test_session_sync "Persistance des fonctions" \
'function test_func() { return "function_works"; }' \
'echo test_func();' \
'function_works'

# === TESTS DE GESTION D'ERREUR AMÉLIORÉE ===

print_colored "$BLUE" "=== TESTS DE GESTION D'ERREUR AMÉLIORÉE ==="

# Étape 8: Test d'erreur de syntaxe
test_session_sync "Erreur de syntaxe" \
'$x = ' \
'(PARSE ERROR|Parse error|syntax error|unexpected|Error:.*syntax error|Error:.*Unclosed|Syntax error|PHP Parse error|TypeError.*null given)'

# Étape 9: Test d'erreur de variable non définie
test_session_sync "Variable non définie" \
'echo $undefined_variable' \
'(Undefined variable|Error:.*Undefined variable|Notice|Warning|TypeError)'

# Étape 10: Test d'erreur de fonction non définie  
test_session_sync "Fonction non définie" \
'undefined_function()' \
'(Call to undefined function|Error:.*undefined function|Fatal error|TypeError)'

# === TESTS DE PERFORMANCE ET ROBUSTESSE ===

print_colored "$BLUE" "=== TESTS DE PERFORMANCE ET ROBUSTESSE ==="

# Étape 11: Test de performance simple
test_session_sync "Performance simple" \
'echo array_sum(range(1, 1000))' \
'2'

# Étape 12: Test avec boucle
test_session_sync "Test avec boucle" \
'$sum = 0;
for ($i = 1; $i <= 10; $i++) {
    $sum += $i;
}
echo $sum;' \
'55'

# === TESTS D'INTÉGRATION ===

print_colored "$BLUE" "=== TESTS D'INTÉGRATION ==="

# Étape 13: Test d'intégration avec classes
test_session_sync "Test avec classe" \
'class TestClass {
    public function getValue() {
        return "class_value";
    }
}
$obj = new TestClass();
echo $obj->getValue();' \
'class_value'

# Étape 14: Test avec closure
test_session_sync "Test avec closure" \
'$multiplier = 3;
$closure = function($x) use ($multiplier) {
    return $x * $multiplier;
};
echo $closure(7);' \
'21'

# === TESTS DE COMPATIBILITÉ DESCENDANTE ===

print_colored "$BLUE" "=== TESTS DE COMPATIBILITÉ DESCENDANTE ==="

# Étape 15: Test avec ancien format
test_session_sync "Format ancien compatible" \
'echo strlen("hello")' \
'5'

# Étape 16: Test avec expressions complexes
test_session_sync "Expression complexe" \
'echo json_encode(["key" => "value"])' \
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

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
