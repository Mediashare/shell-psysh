#!/bin/bash

# Test 18: Traits
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser le test
init_test "TEST 18: Traits"

# Étape 1: Trait basique
test_monitor_multiline "Trait Logger" \
'trait Logger {
    public function log($message) {
        return "[LOG] $message";
    }
}
class MyClass {
    use Logger;
}
$obj = new MyClass();
echo $obj->log("Test message");' \
'[LOG] Test message'

# Étape 2: Trait avec conflit de méthodes
test_monitor_multiline "Résolution de conflit" \
'trait A {
    public function hello() { return "Hello from A"; }
}
trait B {
    public function hello() { return "Hello from B"; }
}
class C {
    use A, B {
        A::hello insteadof B;
    }
}
$c = new C();
echo $c->hello();' \
'Hello from A'

# Étape 3: Trait avec propriétés
test_monitor_multiline "Trait avec propriétés" \
'trait Counter {
    protected $count = 0;
    public function increment() {
        $this->count++;
    }
    public function getCount() {
        return $this->count;
    }
}
class MyCounter {
    use Counter;
}
$counter = new MyCounter();
$counter->increment();
$counter->increment();
echo $counter->getCount();' \
'2'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
