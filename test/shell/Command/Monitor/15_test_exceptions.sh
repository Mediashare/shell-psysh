#!/bin/bash

# Test 15: Gestion des exceptions
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 15: Gestion des exceptions"

# Étape 1: Test exception simple avec try/catch
'try { throw new Exception("Test"); } catch (Exception $e) { echo $e->getMessage(); }' \
test_session_sync "Exception simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Test'

# Étape 2: Test exception avec message personnalisé
'try { throw new Exception("Error 404"); } catch (Exception $e) { echo "Caught: " . $e->getMessage(); }' \
test_session_sync "Exception personnalisée" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'Caught: Error 404'

# Étape 3: Test multiple exceptions
'function testFunction($type) {
test_session_sync "Multiple exceptions" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    switch($type) {
        case "invalid":
            throw new InvalidArgumentException("Invalid argument");
        case "runtime":
            throw new RuntimeException("Runtime error");
        default:
            return "OK";
    }
}

try {
    echo testFunction("normal");
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}' \
'OK'

# Étape 4: Test capture d'exception spécifique
'function divide($a, $b) {
test_session_sync "Exception spécifique" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    if ($b == 0) {
        throw new InvalidArgumentException("Division by zero");
    }
    return $a / $b;
}

try {
    echo divide(10, 0);
} catch (InvalidArgumentException $e) {
    echo "Invalid: " . $e->getMessage();
}' \
'Invalid: Division by zero'

# Étape 5: Test exception dans une classe
'class Calculator {
test_session_sync "Exception dans classe" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    public function sqrt($number) {
        if ($number < 0) {
            throw new Exception("Negative number");
        }
        return sqrt($number);
    }
}

$calc = new Calculator();
try {
    echo $calc->sqrt(16);
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}' \
'4'

# Étape 6: Test finally block
'$executed = "";
test_session_sync "Finally block" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
try {
    $executed .= "try ";
    throw new Exception("test");
} catch (Exception $e) {
    $executed .= "catch ";
} finally {
    $executed .= "finally";
}
echo $executed;' \
'try catch finally'

# Étape 7: Test exception personnalisée
'class CustomException extends Exception {
test_session_sync "Exception personnalisée" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
    public function __construct($message, $code = 0) {
        parent::__construct("Custom: " . $message, $code);
    }
}

try {
    throw new CustomException("My error");
} catch (CustomException $e) {
    echo $e->getMessage();
}' \
'Custom: My error'

# Étape 8: Test exception non capturée (devrait générer une erreur)
'throw new Exception("Uncaught exception");' \
test_session_sync "Exception non capturée" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'(Uncaught exception|Fatal error|Error: Uncaught)'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
