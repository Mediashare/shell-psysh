#!/bin/bash

# Test 01: Variables et expressions basiques
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/psysh_utils.sh"

# Initialiser le test
init_test "TEST 01: Variables et expressions basiques"

# Étape 1: Variable simple
test_monitor_multiline "Variable simple" \
'$x = 42;
echo $x;' \
'42'

# Étape 2: Variables multiples avec calcul (corrigé)
test_monitor_multiline "Variables multiples" \
'$a = 10; $b = 20; $c = $a + $b;
echo $c;' \
'30'

# Étape 3: Expression avec array_sum
test_monitor_expression "Array sum" 'echo array_sum(range(1, 10))' '55'

# Étape 4: Array sum plus grand
test_monitor_expression "Array sum étendu" 'echo array_sum(range(1, 100))' '5050'

# Étape 5: Manipulation de chaînes - concaténation
test_monitor_expression "Concaténation de chaînes" '"Hello" . " " . "World"' 'Hello World'

# Étape 6: Fonction strlen
test_monitor_expression "Longueur de chaîne" 'echo strlen("Hello World")' '11'

# Étape 7: Variables avec chaînes
test_monitor_multiline "Variables chaînes multi-lignes" \
'$str = "Hello";
$str .= " World";
echo $str;' \
'Hello World'

# Étape 8: Calculs mathématiques complexes
test_monitor_expression "Calcul complexe" '(5 + 3) * 2 - 1' '15'

# Étape 9: Vérification de type array
test_monitor_expression "Test array" 'echo count([1, 2, 3, 4, 5])' '5'

# Étape 10: Test d'erreur - variable non définie
test_monitor_error "Variable non définie" \
'$undefined_var' \
'Undefined variable'

# Étape 11: Test d'erreur - syntaxe invalide
test_monitor_error "Syntaxe invalide" \
'$x = ;' \
'Syntax error'

# Étape 12: Test edge case - division par zéro
test_monitor_error "Division par zéro" \
'1 / 0' \
'Division by zero'

# Étape 13: Test sync bidirectionnelle - variables persistantes
test_shell_responsiveness "Variables persistantes entre commandes" \
'$global_var = 123;' \
'echo $global_var;' \
'123'

# Étape 14: Test sync - modification de variable
test_shell_responsiveness "Modification de variable" \
'$counter = 5; $counter++;' \
'echo $counter;' \
'6'

# Étape 15: Test edge case - très grandes valeurs
test_monitor_expression "Très grande valeur" \
'pow(10, 15)' \
'1000000000000000'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
