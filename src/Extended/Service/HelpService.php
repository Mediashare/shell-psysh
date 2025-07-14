<?php

namespace Psy\Extended\Service;

class HelpService
{
    public static function displayHelp(array $projectContext): void
    {
        $framework = $projectContext['framework'];
        $type = $projectContext['type'];
        
        echo "\n";
        echo "🚀 " . str_repeat('=', 80) . "\n";
        echo "✨ PsySH Shell Enhanced - {$framework}\n";
        echo str_repeat('=', 80) . "\n\n";
        
        // Commandes de monitoring
        echo "📊 COMMANDES DE MONITORING:\n";
        echo "  • monitor <code>           - Monitor l'exécution du code PHP avec Xdebug\n";
        echo "  • monitor-advanced <code>  - Monitoring avancé avec toutes les fonctionnalités\n\n";
        
        // Commandes PHPUnit de base
        echo "🧪 COMMANDES PHPUNIT DE BASE:\n";
        echo "  • phpunit:create <service> - Créer un nouveau test PHPUnit interactif\n";
        echo "  • phpunit:add <method>     - Ajouter une méthode de test\n";
        echo "  • phpunit:code             - Entrer en mode code interactif\n";
        echo "  • phpunit:run [test]       - Exécuter un test\n";
        echo "  • phpunit:export <test>    - Exporter un test vers un fichier\n";
        echo "  • phpunit:list             - Lister tous les tests actifs\n";
        echo "  • phpunit:help <class>     - Aide contextuelle pour une classe\n\n";
        
        // Commandes d'assertions
        echo "🎯 ASSERTIONS PHPUNIT:\n";
        echo "  • phpunit:assert <expr> [-m message]     - Assertion simple avec message\n";
        echo "  • phpunit:assert-type <type> <expr>      - Vérifier le type\n";
        echo "  • phpunit:assert-instance <class> <expr> - Vérifier l'instance\n";
        echo "  • phpunit:assert-count <num> <expr>      - Vérifier le nombre\n";
        echo "  • phpunit:assert-empty <expr>            - Vérifier si vide\n";
        echo "  • phpunit:assert-not-empty <expr>        - Vérifier si non vide\n";
        echo "  • phpunit:assert-true <expr>             - Vérifier si true\n";
        echo "  • phpunit:assert-false <expr>            - Vérifier si false\n";
        echo "  • phpunit:assert-null <expr>             - Vérifier si null\n";
        echo "  • phpunit:assert-not-null <expr>         - Vérifier si non null\n\n";
        
        // Commandes d'exceptions
        echo "⚡ ASSERTIONS D'EXCEPTIONS:\n";
        echo "  • phpunit:expect-exception <class> <expr> [-m message] - Attendre exception\n";
        echo "  • phpunit:expect-no-exception <expr>                   - Aucune exception\n\n";
        
        // Commandes de snapshots
        echo "📸 SNAPSHOTS ET CAPTURES:\n";
        echo "  • phpunit:snapshot <name> <expr>     - Créer un snapshot\n";
        echo "  • phpunit:compare <name> <expr>      - Comparer avec snapshot\n";
        echo "  • phpunit:save-snapshot <name> [-p]  - Sauvegarder snapshot\n\n";
        
        // Commandes de configuration
        echo "⚙️ CONFIGURATION PHPUNIT:\n";
        echo "  • phpunit:config [--show]             - Afficher/gérer la configuration\n";
        echo "  • phpunit:config --testsuite=<name>   - Définir le testsuite\n";
        echo "  • phpunit:config --coverage=<type>    - Activer coverage (html/text/clover)\n";
        echo "  • phpunit:config --bootstrap=<file>   - Définir le bootstrap\n";
        echo "  • phpunit:temp-config                 - Configuration temporaire\n";
        echo "  • phpunit:restore-config              - Restaurer configuration\n\n";
        
        // Commandes d'exécution
        echo "🚀 EXÉCUTION DES TESTS:\n";
        echo "  • phpunit:run                         - Exécuter le test actuel\n";
        echo "  • phpunit:run-all                     - Exécuter tous les tests interactifs\n";
        echo "  • phpunit:run-project [--coverage]    - Exécuter les tests du projet\n";
        echo "  • phpunit:watch [-p path]             - Mode surveillance automatique\n\n";
        
        // Commandes de debugging
        echo "🐛 DEBUGGING ET ANALYSE:\n";
        echo "  • phpunit:debug [on/off/status]       - Activer/gérer le mode debug\n";
        echo "  • phpunit:trace                       - Afficher la stack trace du dernier échec\n";
        echo "  • phpunit:profile <expression>        - Profiler une expression PHP\n";
        echo "  • phpunit:explain                     - Analyser et expliquer le dernier échec\n\n";
        
        // Commandes de monitoring
        echo "📊 MONITORING ET MÉTRIQUES:\n";
        echo "  • phpunit:monitor [--once]            - Monitoring en temps réel des tests\n";
        echo "  • phpunit:benchmark <expr> [iter]     - Benchmark de performance\n";
        echo "  • phpunit:compare-performance <expr1> vs <expr2> - Comparer performances\n\n";
        
        // Commandes de gestion des tests existants
        echo "📁 GESTION DES TESTS EXISTANTS:\n";
        echo "  • phpunit:list-project [--type]       - Lister les tests du projet\n";
        echo "  • phpunit:run-test <path>::<method>   - Exécuter un test spécifique\n";
        echo "  • phpunit:import <path>::<method>     - Importer un test dans la session\n";
        echo "  • phpunit:create-file <path>          - Créer un nouveau fichier de test\n\n";
        
        // Variables disponibles selon le framework
        echo "📋 VARIABLES DISPONIBLES:\n";
        
        if ($type === 'symfony') {
            echo "  Symfony:\n";
            echo "    • \$kernel          - Instance du kernel Symfony\n";
            echo "    • \$container       - Container de dépendances\n";
            echo "    • \$em / \$entityManager - Entity Manager Doctrine\n";
            echo "    • \$router          - Service de routage\n";
            echo "    • \$dispatcher      - Event dispatcher\n";
            echo "    • \$security        - Token storage\n";
            echo "    • \$session         - Service de session\n";
        } elseif ($type === 'laravel') {
            echo "  Laravel:\n";
            echo "    • \$app             - Instance de l'application Laravel\n";
            echo "    • \$db              - Base de données\n";
            echo "    • \$cache           - Service de cache\n";
            echo "    • \$config          - Configuration\n";
        }
        
        echo "  Génériques:\n";
        echo "    • \$projectRoot     - Racine du projet\n";
        echo "    • \$phpunitService  - Service PHPUnit\n";
        echo "    • \$project         - Informations du projet\n\n";
        
        // Exemples d'utilisation
        echo "💡 EXEMPLES D'UTILISATION:\n";
        echo "  Créer et développer un test:\n";
        echo "    >>> phpunit:create App\\Service\\InvoiceService\n";
        echo "    >>> phpunit:add testCalculate\n";
        echo "    >>> phpunit:code\n";
        echo "    [Code Mode] >>> \$service = new InvoiceService();\n";
        echo "    [Code Mode] >>> \$result = \$service->calculate(100);\n";
        echo "    [Code Mode] >>> exit\n";
        echo "    >>> phpunit:assert \$result == 120\n";
        echo "    >>> phpunit:run\n";
        echo "    >>> phpunit:export InvoiceServiceTest\n\n";
        
        if ($type === 'symfony') {
            echo "  Symfony - Tester un service:\n";
            echo "    >>> \$userService = \$container->get('App\\Service\\UserService');\n";
            echo "    >>> monitor '\$userService->createUser([\"email\" => \"test@example.com\"])'\n\n";
        }
        
        echo "  Monitoring de performance:\n";
        echo "    >>> monitor 'for(\$i=0; \$i<10000; \$i++) { hash(\"sha256\", \$i); }'\n";
        echo "    >>> monitor-advanced --symfony '\$em->getRepository(User::class)->findAll()'\n\n";
        
        // Informations sur le projet
        echo "📁 INFORMATIONS DU PROJET:\n";
        echo "  • Type: {$type}\n";
        echo "  • Framework: {$framework}\n";
        
        if (isset($projectContext['info']['symfony_version'])) {
            echo "  • Version Symfony: {$projectContext['info']['symfony_version']}\n";
        }
        
        echo "  • Répertoire: " . basename($projectContext['variables']['projectRoot'] ?? getcwd()) . "\n";
        
        if ($projectContext['variables']['composerAutoloader']) {
            echo "  • Autoloader Composer: ✅ Disponible\n";
        } else {
            echo "  • Autoloader Composer: ❌ Non trouvé\n";
        }
        
        echo "\n";
        echo "📝 NOTES:\n";
        echo "  • Tapez 'list' pour voir toutes les commandes PsySH disponibles\n";
        echo "  • Tapez 'exit' ou Ctrl+D pour quitter\n";
        echo "  • Les variables sont persistantes entre les commandes\n";
        echo "  • Utilisez 'help()' pour revoir cette aide\n\n";
        
        echo str_repeat('=', 80) . "\n";
    }
}
