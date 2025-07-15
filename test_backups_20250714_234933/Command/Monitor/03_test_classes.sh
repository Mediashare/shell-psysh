#!/bin/bash

# Test 03: Classes et objets
# Test automatisé avec assertions efficaces

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser le test
init_test "TEST 03: Classes et objets"

# Étape 1: Test création de classe simple
test_monitor_multiline "Classe simple Calculator" \
'class Calculator {
    public function add($a, $b) {
        return $a + $b;
    }
}
$calc = new Calculator();
echo $calc->add(5, 3);' \
'8'

# Étape 2: Test classe avec propriétés privées
test_monitor_multiline "Classe avec propriétés" \
'class Counter {
    private $count = 0;
    
    public function increment() {
        return ++$this->count;
    }
    
    public function getCount() {
        return $this->count;
    }
}
$counter = new Counter();
$counter->increment();
$counter->increment();
echo $counter->getCount();' \
'2'

# Étape 3: Test classe avec constructeur
test_monitor_multiline "Classe avec constructeur" \
'class Person {
    private $name;
    private $age;
    
    public function __construct($name, $age) {
        $this->name = $name;
        $this->age = $age;
    }
    
    public function introduce() {
        return "Je suis {$this->name}, {$this->age} ans";
    }
}
$person = new Person("Alice", 30);
echo $person->introduce();' \
'Je suis Alice, 30 ans'

# Étape 4: Test héritage de classe
test_monitor_multiline "Héritage de classe" \
'class Animal {
    protected $name;
    
    public function __construct($name) {
        $this->name = $name;
    }
    
    public function speak() {
        return "Animal noise";
    }
}

class Dog extends Animal {
    public function speak() {
        return "{$this->name} says Woof!";
    }
}

$dog = new Dog("Buddy");
echo $dog->speak();' \
'Buddy says Woof!'

# Étape 5: Test méthodes statiques
test_monitor_multiline "Méthodes statiques" \
'class MathHelper {
    public static function square($n) {
        return $n * $n;
    }
    
    public static function cube($n) {
        return $n * $n * $n;
    }
}
echo MathHelper::square(4) . "," . MathHelper::cube(3);' \
'16,27'

# Étape 6: Test interface
test_monitor_multiline "Interface" \
'interface Drawable {
    public function draw();
}

class Circle implements Drawable {
    private $radius;
    
    public function __construct($radius) {
        $this->radius = $radius;
    }
    
    public function draw() {
        return "Circle with radius {$this->radius}";
    }
}

$circle = new Circle(5);
echo $circle->draw();' \
'Circle with radius 5'

# Étape 7: Test classe avec historique
test_monitor_multiline "Classe avec historique" \
'class Calculator {
    private $history = [];
    
    public function add($a, $b) {
        $result = $a + $b;
        $this->history[] = "$a+$b=$result";
        return $result;
    }
    
    public function getHistoryCount() {
        return count($this->history);
    }
}

$calc = new Calculator();
$calc->add(2, 3);
$calc->add(4, 5);
echo $calc->getHistoryCount();' \
'2'

# Étape 8: Test exceptions dans les classes
test_monitor_multiline "Classe avec exceptions" \
'class SafeDivider {
    public function divide($a, $b) {
        if ($b == 0) {
            throw new Exception("Division by zero");
        }
        return $a / $b;
    }
}

$divider = new SafeDivider();
try {
    echo $divider->divide(10, 2);
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}' \
'5'

# Étape 9: Test d'erreur - classe inexistante
test_monitor_error "Classe inexistante" \
'new NonExistentClass()' \
'Class.*not found'

# Étape 10: Test d'erreur - méthode inexistante
test_monitor_error "Méthode inexistante" \
'class Calculator { public function add($a, $b) { return $a + $b; } } $calc = new Calculator(); $calc->nonExistentMethod()' \
'Call to undefined method'

# Étape 11: Test d'erreur - propriété privée
test_monitor_multiline "Accès propriété privée" \
'class PrivateClass { 
    private $secret = 42; 
} 
$p = new PrivateClass(); 
try {
    echo $p->secret;
} catch (Error $e) {
    echo "Error: Cannot access private property";
}' \
'Error: Cannot access private property'

# Étape 12: Test sync - classes persistantes
test_monitor_multiline "Classes persistantes" \
'class GlobalClass { 
    public $value = 123; 
}
$obj = new GlobalClass(); 
echo $obj->value;' \
'123'

# Étape 13: Test edge case - héritage complexe
test_monitor_multiline "Héritage avec surcharge" \
'class BaseClass { protected function method() { return "parent"; } }
class ChildClass extends BaseClass { protected function method() { return "child"; } public function test() { return $this->method(); } }
$c = new ChildClass();
echo $c->test();' \
'child'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
