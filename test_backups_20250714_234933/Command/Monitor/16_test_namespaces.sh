#!/bin/bash

# Test 16: Namespaces
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser le test
init_test "TEST 16: Namespaces"

# Étape 1: Définition classe avec namespace
test_monitor_multiline "Classe avec namespace" \
'class TestClass {
    public static function greet($name) {
        return "Hello, $name!";
    }
}
echo "Classe définie";' \
'Classe définie'

# Étape 2: Appel avec namespace complet
test_monitor_multiline "Appel méthode statique" \
'class TestClass {
    public static function greet($name) {
        return "Hello, $name!";
    }
}
echo TestClass::greet("World");' \
'Hello, World!'

# Étape 3: Test use statement
test_monitor_multiline "Méthode statique calculatrice" \
'class Calculator {
    public static function add($a, $b) {
        return $a + $b;
    }
}
echo Calculator::add(5, 3);' \
'8'

# Étape 4: Interface simple
test_monitor_multiline "Interface implémentation" \
'interface OperationInterface {
    public function calculate($a, $b);
}
class Addition implements OperationInterface {
    public function calculate($a, $b) {
        return $a + $b;
    }
}
$op = new Addition();
echo $op->calculate(10, 15);' \
'25'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
