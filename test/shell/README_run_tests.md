# Guide d'utilisation de run_all_tests.sh

## Nouvelles options disponibles

### Mode simple (--simple)
Affiche une progression minimale des tests, juste le numéro du test et son statut (SUCCESS ou FAIL).

```bash
./run_all_tests.sh --simple
```

### Mode simple avec pause sur échec (--simple --pause-on-fail)
En mode simple, met automatiquement en pause lorsqu'un test échoue, affiche les détails de l'échec et attend que l'utilisateur appuie sur ENTRÉE pour continuer ou ESC pour arrêter.

```bash
./run_all_tests.sh --simple --pause-on-fail
```

### Autres options existantes

- `--all` : Exécute tous les tests en mode automatique (affichage complet)
- `--help` ou `-h` : Affiche l'aide

### Exemples d'utilisation

1. **Exécution rapide pour vérifier que tout passe** :
   ```bash
   ./run_all_tests.sh --simple
   ```

2. **Debug avec arrêt sur erreur** :
   ```bash
   ./run_all_tests.sh --simple --pause-on-fail
   ```

3. **Mode interactif classique** :
   ```bash
   ./run_all_tests.sh
   ```

### Format de sortie en mode simple

```
Test 1/27: 01_test_basic_variables.sh ... ✓ SUCCESS
Test 2/27: 02_test_functions.sh ... ✓ SUCCESS
Test 3/27: 03_test_classes.sh ... ✗ FAIL
```

Avec `--pause-on-fail`, les détails de l'échec s'affichent automatiquement.
