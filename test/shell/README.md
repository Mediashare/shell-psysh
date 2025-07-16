# Suite de tests pour la commande monitor de PsySH

## 🚀 Utilisation rapide

```bash
cd tests
./run_all_tests.sh
```

## 📖 Guide d'utilisation

### Navigation dans les tests

1. **Lancer la suite de tests** : `./run_all_tests.sh`

2. **Contrôles pendant l'exécution** :
   - **ENTRÉE** : Lance le test affiché
   - **ESC** : Passe au test suivant sans l'exécuter
   - **CTRL+C** : Quitte complètement la suite de tests

3. **Dans PsySH** :
   - Les tests s'exécutent automatiquement
   - Tapez `exit` ou utilisez **CTRL+D** pour quitter PsySH
   - Les résultats s'affichent dans le terminal

### Structure des tests

- **Tests 01-05** : Tests basiques (variables, fonctions, classes)
- **Tests 06-10** : Tests temps réel et debug
- **Tests 11-15** : Tests avec services Symfony
- **Tests 16-20** : Tests PHP avancés

### Options du menu principal

1. **Exécuter tous les tests** : Lance les 20 tests en séquence
2. **Choisir un test spécifique** : Sélection manuelle d'un test
3. **Tests par catégorie** : Exécute un groupe de 5 tests

### Conseils

- Commencez par les tests basiques (option 3) pour comprendre le fonctionnement
- Utilisez ESC pour passer rapidement les tests que vous connaissez déjà
- Le mode debug (test 07) montre des informations détaillées sur l'exécution

## 🔍 Que teste chaque script ?

| Test | Description |
|------|-------------|
| 01 | Variables et expressions simples |
| 02 | Définition et utilisation de fonctions |
| 03 | Classes et objets |
| 04 | Services Symfony du projet |
| 05 | Performance avec boucles |
| 06 | Affichage temps réel avec sleep |
| 07 | Mode debug (--debug) |
| 08 | Gestion des erreurs |
| 09 | Consommation mémoire |
| 10 | Code multi-lignes complexe |
| 11 | Service DataProcessing |
| 12 | Service ImageProcessing |
| 13 | Closures et callbacks |
| 14 | Calculs intensifs (stress test) |
| 15 | Gestion des exceptions |
| 16 | Namespaces et autoloading |
| 17 | Générateurs PHP |
| 18 | Traits PHP |
| 19 | Itérateurs personnalisés |
| 20 | Comparaison de performance |

## 🛠️ Résolution de problèmes

- Si un test ne se ferme pas : Utilisez CTRL+D dans PsySH
- Si l'affichage est trop rapide : Le script attend maintenant votre confirmation entre chaque étape
- Pour voir plus de détails : Lancez le test 07 qui active le mode debug
