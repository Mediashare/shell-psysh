# Commande Monitor PsySH

## Description

La commande `monitor` permet de surveiller en temps réel l'exécution du code PHP dans le shell PsySH. Elle affiche des métriques de performance détaillées pendant l'exécution :

- ⏱ Temps d'exécution en temps réel
- 💾 Utilisation de la mémoire RAM
- 📈 Pic de mémoire utilisée
- 🔄 Nombre de ticks (instructions)
- 📤 Affichage en direct des outputs
- 📍 Ligne de code en cours d'exécution

## Installation

La commande est automatiquement enregistrée lors du lancement du shell PsySH via :

```bash
bin/psysh
```

## Utilisation

### Syntaxe de base

```php
>>> monitor "code PHP à exécuter"
```

### Exemples

#### 1. Test simple
```php
>>> monitor "echo 'Hello World'"
```

#### 2. Utilisation avec des variables du contexte
```php
>>> $counter = 20
>>> monitor "echo $counter"
```

#### 3. Monitoring d'une boucle avec affichage en temps réel
```php
>>> monitor "foreach ([1,2,3,4,5] as $i) { sleep(1); echo \"$i\n\"; }"
```

#### 4. Utilisation avec l'EntityManager Symfony
```php
>>> monitor "$em->getRepository('App\Entity\User')->findAll()"
```

#### 5. Test de performance avec calcul intensif
```php
>>> monitor "array_sum(range(1, 1000000))"
```

## Fonctionnalités

### Monitoring en temps réel

La commande affiche en temps réel :
- Les outputs du code au moment où ils sont générés
- Les métriques de performance mises à jour toutes les 100 ticks
- La ligne de code en cours d'exécution toutes les 1000 ticks

### Résumé final

À la fin de l'exécution, un tableau récapitulatif affiche :
- Le temps d'exécution total
- La mémoire utilisée
- Le pic de mémoire
- Le nombre total de ticks
- Le type et la valeur du résultat
- Les ticks par seconde

### Graphique de mémoire

Un graphique ASCII montre l'évolution de l'utilisation mémoire au cours du temps.

### Alertes de performance

Des alertes sont affichées si :
- L'exécution dure plus d'1 seconde
- L'utilisation mémoire dépasse 80% de la limite

## Architecture technique

La commande utilise :
- Les ticks PHP pour intercepter l'exécution à chaque instruction
- `ob_start()` pour capturer les outputs en temps réel
- Le contexte PsySH pour accéder aux variables du shell
- Les helpers Symfony Console pour l'affichage formaté

## Limitations

- Le monitoring par ticks peut ralentir l'exécution du code
- La précision dépend de la configuration PHP (declare(ticks=1))
- Les outputs capturés sont bufferisés par blocs de 1 octet minimum

## Développement

Le code source se trouve dans `.psysh/PsyCommand/PsyshMonitorCommand.php`

Pour modifier la commande :
1. Éditer le fichier
2. Relancer le shell PsySH pour recharger la commande
