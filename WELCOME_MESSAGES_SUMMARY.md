# 🎉 Système de Welcome Messages Personnalisés

## ✅ Fonctionnalités Implémentées

### 🔍 **Détection Automatique d'Environnement**

Le système détecte automatiquement l'environnement d'exécution via :

1. **Variables d'environnement** : `APP_ENV`, `SYMFONY_ENV`
2. **Fichiers de configuration** : `.env.local`, `.env.prod`, `.env.staging`
3. **Contexte d'exécution** : Détection des scripts de test

### 🎯 **Messages Personnalisés par Environnement**

#### 🛠️ **Développement (dev)**
- **Apparence** : 🚀 Header avec émojis colorés
- **Contenu** : Liste complète des commandes
- **Variables** : Toutes les variables Symfony/Framework disponibles
- **Message** : "Happy coding! Tapez 'help()' pour commencer."

#### 🔴 **Production (prod)**
- **Apparence** : ⚠️ Header d'avertissement rouge
- **Contenu** : Commandes limitées (lecture seule)
- **Sécurité** : Avertissement de production
- **Message** : "Soyez prudent! Tapez 'exit' pour quitter."

#### 🟡 **Staging**
- **Apparence** : 🎭 Header orange pour pré-production
- **Contenu** : Commandes complètes pour les tests
- **Message** : "Environnement de staging - Testez vos fonctionnalités!"

#### 🧪 **Test (Silencieux)**
- **Comportement** : **Aucun message d'accueil**
- **Détection** : Variables `SIMPLE_MODE`, `AUTO_MODE`, `--no-interactive`
- **Usage** : Compatible avec `./tests/run.sh`

## 🔧 **Intégration avec les Tests**

### ✅ **Détection Automatique des Tests**

Le système détecte les environnements de test via :

```bash
# Variables exportées par ./tests/run.sh
export SIMPLE_MODE=1
export AUTO_MODE=1

# Mode non-interactif
--no-interactive

# Variable d'environnement
APP_ENV=test
```

### ✅ **Compatibilité avec les Scripts de Test**

```bash
# Le script ./tests/run.sh fonctionne sans message d'accueil
./tests/run.sh --simple

# Sortie propre pour les tests automatisés
echo "commands" | psysh --config config/config.php --no-interactive
```

## 📊 **Exemples d'Utilisation**

### 🛠️ **Mode Développement**
```bash
# Lancement normal
./vendor/bin/psysh --config config/config.php

# Affiche:
🚀 ================================================================================
✨ PsySH Shell Enhanced - Symfony 6.3
🛠️  Environnement de développement
📁 Project: mon-projet
================================================================================

🎯 COMMANDES DISPONIBLES:
   📊 Monitoring:
     • monitor <code>           - Monitor code execution
     • monitor-advanced <code>  - Advanced monitoring

   🧪 PHPUnit Enhanced:
     • phpunit:create <service> - Create interactive test
     • phpunit:add <method>     - Add test method
     • phpunit:code             - Enter code mode
     • phpunit:run              - Run tests
     • phpunit:mock <class>     - Create mocks
     • phpunit:list             - List active tests

   🔧 Aide avancée:
     • help phpunit:add         - Aide détaillée pour une commande
     • help()                   - Aide générale

   🎛️  Variables Symfony disponibles:
     • $kernel, $container, $em (EntityManager)
     • $router, $security, $cache, $logger

================================================================================
🛠️  Happy coding! Tapez 'help()' pour commencer.
```

### 🔴 **Mode Production**
```bash
APP_ENV=prod ./vendor/bin/psysh --config config/config.php

# Affiche:
🔴 ================================================================================
⚠️  PsySH Shell Enhanced - Symfony [PRODUCTION]
🚨 ATTENTION: Vous êtes en environnement de PRODUCTION!
📁 Project: mon-projet
================================================================================

🎯 COMMANDES DISPONIBLES:
   • help()                   - Aide et documentation
   • ls                       - Lister les variables
   • show $variable           - Examiner une variable
   • exit                     - Quitter le shell

🚨 En production, les commandes de modification sont désactivées.

================================================================================
⚠️  Soyez prudent! Tapez 'exit' pour quitter.
```

### 🧪 **Mode Test (Silencieux)**
```bash
SIMPLE_MODE=1 ./vendor/bin/psysh --config config/config.php --no-interactive

# Affiche seulement:
Psy Shell v0.12.9 (PHP 8.4.10 — cli) by Justin Hileman
# Pas de message d'accueil personnalisé
```

## 🚀 **Avantages**

### ✅ **Sécurité**
- Avertissements clairs en production
- Commandes limitées selon l'environnement
- Détection automatique du contexte

### ✅ **Expérience Utilisateur**
- Messages adaptés à chaque situation
- Guide visuel avec émojis et couleurs
- Information claire sur les fonctionnalités disponibles

### ✅ **Compatibilité**
- Tests automatisés sans pollution de sortie
- Intégration transparente avec les scripts existants
- Support de tous les frameworks PHP

### ✅ **Maintenabilité**
- Configuration centralisée dans `EnvironmentLoader`
- Facilement extensible pour de nouveaux environnements
- Tests automatisés inclus

## 🔧 **Configuration**

### 📝 **Variables d'Environnement Supportées**

```bash
# Environnement principal
APP_ENV=dev|prod|staging|test
SYMFONY_ENV=dev|prod|staging|test  # Legacy

# Tests automatisés
SIMPLE_MODE=1    # Désactive le welcome message
AUTO_MODE=1      # Mode automatique pour tests

# Détection PsySH
--no-interactive # Mode non-interactif
```

### 🎯 **Fichiers de Configuration**

- `.env` : Configuration par défaut
- `.env.local` : Indique un environnement de développement
- `.env.prod` : Indique un environnement de production
- `.env.staging` : Indique un environnement de staging

## 📈 **Tests et Validation**

- ✅ **Tests unitaires** pour la détection d'environnement
- ✅ **Tests d'intégration** avec `./tests/run.sh`
- ✅ **Validation** des messages dans tous les environnements
- ✅ **Compatibilité** avec les workflows CI/CD

Le système de welcome messages personnalisés améliore significativement l'expérience utilisateur tout en maintenant la compatibilité avec l'automatisation et les tests.
