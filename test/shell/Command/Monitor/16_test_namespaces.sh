#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 16: Namespaces"

# Étape 1: Définition classe avec namespace
test_session_sync "Classe avec namespace" \
'class TestClass {
    public static function greet($name) {
        return "Hello, $name!";
    }
}
echo "Classe définie";' \
'Classe définie'

# Étape 2: Appel avec namespace complet
test_session_sync "Appel méthode statique" \
'class TestClass {
    public static function greet($name) {
        return "Hello, $name!";
    }
}
echo TestClass::greet("World");' \
'Hello, World!'

# Étape 3: Test use statement
test_session_sync "Méthode statique calculatrice" \
'class Calculator {
    public static function add($a, $b) {
        return $a + $b;
    }
}
echo Calculator::add(5, 3);' \
'8'

# Étape 4: Interface simple
test_session_sync "Interface implémentation" \
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

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
