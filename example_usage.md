# Utilisation des expressions sans guillemets

Avec les modifications apportées, vous pouvez maintenant utiliser les commandes PHPUnit avec des expressions naturelles sans guillemets :

## Syntaxe avant (avec guillemets)
```bash
>>> phpunit:assert '$result === 42'
>>> phpunit:assert '$user->getName() == "John"'
>>> phpunit:assert 'count($items) > 0'
```

## Syntaxe après (sans guillemets)
```bash
>>> phpunit:assert $result === 42
>>> phpunit:assert $user->getName() == "John"
>>> phpunit:assert count($items) > 0
>>> phpunit:assert $obj instanceof User
>>> phpunit:assert !empty($data)
```

## Commandes supportées

Toutes les commandes PHPUnit qui acceptent des expressions supportent maintenant cette syntaxe :

- `phpunit:assert` - Ajouter une assertion
- `phpunit:eval` - Évaluer une expression (avec analyse détaillée)
- `phpunit:create` - Créer un test (pour les expressions dans les paramètres)
- `phpunit:expect` - Définir une expectation
- `phpunit:mock` - Créer un mock
- Et toutes les autres commandes PHPUnit...

## Exemples pratiques

```bash
# Assertions de comparaison
>>> phpunit:assert $invoice->getTotal() === 100.50
>>> phpunit:assert $user->getAge() >= 18

# Tests d'instance
>>> phpunit:assert $response instanceof JsonResponse
>>> phpunit:assert $service instanceof PaymentService

# Tests de vérification
>>> phpunit:assert !empty($results)
>>> phpunit:assert isset($config['database'])
>>> phpunit:assert is_array($data)

# Expressions complexes
>>> phpunit:assert count($items) > 0 && $items[0] instanceof Product
>>> phpunit:assert $user->hasRole('admin') || $user->hasRole('moderator')
```

## Fonctionnalités

- **Capture automatique** : L'expression complète est capturée automatiquement
- **Fallback intelligent** : Si la capture échoue, utilise les arguments classiques
- **Compatible** : Fonctionne avec les anciennes syntaxes avec guillemets
- **Flexible** : Supporte les expressions complexes avec opérateurs multiples
