#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 18: Traits"

# Étape 1: Trait basique
test_session_sync "Trait Logger" \
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
test_session_sync "Résolution de conflit" \
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
test_session_sync "Trait avec propriétés" \
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

# Nettoyer l'environnement de test
cleanup_test_environment

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
