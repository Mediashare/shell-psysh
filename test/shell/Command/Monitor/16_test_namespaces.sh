#!/bin/bash

# Test 16: Namespaces
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 16: Namespaces"

# Étape 1: Définition classe avec namespace
'class TestClass {
test_session_sync "Classe avec namespace" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    public static function greet($name) {
        return "Hello, $name!";
    }
}
echo "Classe définie";' \
'Classe définie'

# Étape 2: Appel avec namespace complet
'class TestClass {
test_session_sync "Appel méthode statique" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    public static function greet($name) {
        return "Hello, $name!";
    }
}
echo TestClass::greet("World");' \
'Hello, World!'

# Étape 3: Test use statement
'class Calculator {
test_session_sync "Méthode statique calculatrice" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    public static function add($a, $b) {
        return $a + $b;
    }
}
echo Calculator::add(5, 3);' \
'8'

# Étape 4: Interface simple
'interface OperationInterface {
test_session_sync "Interface implémentation" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
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
