#!/bin/bash

# Test 33: Commande phpunit:assert - Assertions PHPUnit
# Tests d'intégration pour les assertions dans les tests PHPUnit

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 33: Commande phpunit:assert"

# Étape 1: Créer un test pour les assertions
'phpunit:create AssertionTest' \
test_session_sync "Créer un test pour assertions" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Test créé : AssertionTest'

# Étape 2: Ajouter assertion simple
'phpunit:assert "$this->assertTrue(true)"' \
test_session_sync "Assertion assertTrue simple" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée : $this->assertTrue(true)'

# Étape 3: Assertion assertEquals
'phpunit:assert "$this->assertEquals(5, 2 + 3)"' \
test_session_sync "Assertion assertEquals" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 4: Assertion assertSame
'phpunit:assert "$this->assertSame(\"expected\", \"expected\")"' \
test_session_sync "Assertion assertSame" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 5: Assertion assertInstanceOf
'phpunit:assert "$this->assertInstanceOf(stdClass::class, new stdClass())"' \
test_session_sync "Assertion assertInstanceOf" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 6: Assertion assertArrayHasKey
'phpunit:assert "$this->assertArrayHasKey(\"key\", [\"key\" => \"value\"])"' \
test_session_sync "Assertion assertArrayHasKey" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 7: Assertion assertCount
'phpunit:assert "$this->assertCount(3, [1, 2, 3])"' \
test_session_sync "Assertion assertCount" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 8: Assertion assertEmpty
'phpunit:assert "$this->assertEmpty([])"' \
test_session_sync "Assertion assertEmpty" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 9: Assertion assertNotEmpty
'phpunit:assert "$this->assertNotEmpty([1, 2, 3])"' \
test_session_sync "Assertion assertNotEmpty" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 10: Assertion assertNull
'phpunit:assert "$this->assertNull(null)"' \
test_session_sync "Assertion assertNull" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 11: Assertion assertNotNull
'phpunit:assert "$this->assertNotNull(\"value\")"' \
test_session_sync "Assertion assertNotNull" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 12: Assertion complexe avec message
'phpunit:assert "$this->assertTrue($result, \"Custom failure message\")"' \
test_session_sync "Assertion avec message personnalisé" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 13: Assertion expectException
'phpunit:assert "$this->expectException(InvalidArgumentException::class)"' \
test_session_sync "Assertion expectException" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 14: Test sans test actuel (erreur)
'unset($GLOBALS["phpunit_current_test"])
test_session_sync "Test sans contexte de test" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:assert "$this->assertTrue(true)"' \
'❌ Aucun test actuel'

# Étape 15: Test avec assertion invalide
'phpunit:create ErrorTest
test_session_sync "Assertion syntaxe invalide" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:assert "invalidSyntax("' \
'❌'

# Étape 16: Multiple assertions dans le même test
'phpunit:create MultipleAssertTest
test_session_sync "Multiples assertions" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:assert "$this->assertTrue($condition1)"
phpunit:assert "$this->assertFalse($condition2)"
phpunit:assert "$this->assertEquals(5, $result)"' \
'✅ Assertion ajoutée'

# Étape 17: Assertion avec regex
'phpunit:assert "$this->assertMatchesRegularExpression(\"/[a-z]+/\", \"hello\")"' \
test_session_sync "Assertion avec regex" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 18: Assertion JSON
'phpunit:assert "$this->assertJson(json_encode([\"key\" => \"value\"]))"' \
test_session_sync "Assertion JSON" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
'✅ Assertion ajoutée'

# Étape 19: Vérifier l'ordre des assertions dans le code généré
'phpunit:create OrderTest
test_session_sync "Vérifier ordre des assertions" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:assert "$this->assertTrue($first)"
phpunit:assert "$this->assertFalse($second)"
phpunit:assert "$this->assertEquals(5, $third)"' \
'✅ Assertion ajoutée'

# Étape 20: Test avec assertion et code mixte
'phpunit:create MixedTest
test_session_sync "Mélange assertions et code" \
    --step "" \ --context psysh --output-check contains --tag "default_session"
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"
phpunit:code --snippet "$user = new stdClass();"
phpunit:assert "$this->assertInstanceOf(stdClass::class, $user)"' \
'✅ Assertion ajoutée'

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
