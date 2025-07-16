#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/func/loader.sh"

# Initialiser l'environnement de test
init_test_environment
init_test "TEST 33: Commande phpunit:assert"

# Étape 1: Créer un test pour les assertions
test_session_sync "Créer un test pour assertions" \
'phpunit:create AssertionTest' \
'✅ Test créé : AssertionTest'

# Étape 2: Ajouter assertion simple
test_session_sync "Assertion assertTrue simple" \
'phpunit:assert "$this->assertTrue(true)"' \
'✅ Assertion ajoutée : $this->assertTrue(true)'

# Étape 3: Assertion assertEquals
test_session_sync "Assertion assertEquals" \
'phpunit:assert "$this->assertEquals(5, 2 + 3)"' \
'✅ Assertion ajoutée'

# Étape 4: Assertion assertSame
test_session_sync "Assertion assertSame" \
'phpunit:assert "$this->assertSame(\"expected\", \"expected\")"' \
'✅ Assertion ajoutée'

# Étape 5: Assertion assertInstanceOf
test_session_sync "Assertion assertInstanceOf" \
'phpunit:assert "$this->assertInstanceOf(stdClass::class, new stdClass())"' \
'✅ Assertion ajoutée'

# Étape 6: Assertion assertArrayHasKey
test_session_sync "Assertion assertArrayHasKey" \
'phpunit:assert "$this->assertArrayHasKey(\"key\", [\"key\" => \"value\"])"' \
'✅ Assertion ajoutée'

# Étape 7: Assertion assertCount
test_session_sync "Assertion assertCount" \
'phpunit:assert "$this->assertCount(3, [1, 2, 3])"' \
'✅ Assertion ajoutée'

# Étape 8: Assertion assertEmpty
test_session_sync "Assertion assertEmpty" \
'phpunit:assert "$this->assertEmpty([])"' \
'✅ Assertion ajoutée'

# Étape 9: Assertion assertNotEmpty
test_session_sync "Assertion assertNotEmpty" \
'phpunit:assert "$this->assertNotEmpty([1, 2, 3])"' \
'✅ Assertion ajoutée'

# Étape 10: Assertion assertNull
test_session_sync "Assertion assertNull" \
'phpunit:assert "$this->assertNull(null)"' \
'✅ Assertion ajoutée'

# Étape 11: Assertion assertNotNull
test_session_sync "Assertion assertNotNull" \
'phpunit:assert "$this->assertNotNull(\"value\")"' \
'✅ Assertion ajoutée'

# Étape 12: Assertion complexe avec message
test_session_sync "Assertion avec message personnalisé" \
'phpunit:assert "$this->assertTrue($result, \"Custom failure message\")"' \
'✅ Assertion ajoutée'

# Étape 13: Assertion expectException
test_session_sync "Assertion expectException" \
'phpunit:assert "$this->expectException(InvalidArgumentException::class)"' \
'✅ Assertion ajoutée'

# Étape 14: Test sans test actuel (erreur)
test_session_sync "Test sans contexte de test" \
'unset($GLOBALS["phpunit_current_test"])
phpunit:assert "$this->assertTrue(true)"' \
'❌ Aucun test actuel'

# Étape 15: Test avec assertion invalide
test_session_sync "Assertion syntaxe invalide" \
'phpunit:create ErrorTest
phpunit:assert "invalidSyntax("' \
'❌'

# Étape 16: Multiple assertions dans le même test
test_session_sync "Multiples assertions" \
'phpunit:create MultipleAssertTest
phpunit:assert "$this->assertTrue($condition1)"
phpunit:assert "$this->assertFalse($condition2)"
phpunit:assert "$this->assertEquals(5, $result)"' \
'✅ Assertion ajoutée'

# Étape 17: Assertion avec regex
test_session_sync "Assertion avec regex" \
'phpunit:assert "$this->assertMatchesRegularExpression(\"/[a-z]+/\", \"hello\")"' \
'✅ Assertion ajoutée'

# Étape 18: Assertion JSON
test_session_sync "Assertion JSON" \
'phpunit:assert "$this->assertJson(json_encode([\"key\" => \"value\"]))"' \
'✅ Assertion ajoutée'

# Étape 19: Vérifier l'ordre des assertions dans le code généré
test_session_sync "Vérifier ordre des assertions" \
'phpunit:create OrderTest
phpunit:assert "$this->assertTrue($first)"
phpunit:assert "$this->assertFalse($second)"
phpunit:assert "$this->assertEquals(5, $third)"' \
'✅ Assertion ajoutée'

# Étape 20: Test avec assertion et code mixte
test_session_sync "Mélange assertions et code" \
'phpunit:create MixedTest
phpunit:code --snippet "$user = new stdClass();"
phpunit:assert "$this->assertInstanceOf(stdClass::class, $user)"' \
'✅ Assertion ajoutée'

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
