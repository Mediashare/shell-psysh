<?php

namespace Psy\Extended\Service;

use Psy\Extended\Command\PsyshMonitorCommand;
use Psy\Extended\Command\PHPUnitCreateCommand;
use Psy\Extended\Command\PHPUnitAddCommand;
use Psy\Extended\Command\PHPUnitCodeCommand;
use Psy\Extended\Command\PHPUnitAssertCommand;
use Psy\Extended\Command\PHPUnitRunCommand;
use Psy\Extended\Command\PHPUnitExportCommand;
use Psy\Extended\Command\PHPUnitListCommand;
use Psy\Extended\Command\PHPUnitHelpCommand;
use Psy\Configuration;
use Psy\Shell;
use Psy\VersionUpdater\Checker;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\DependencyInjection\ParameterBag\ParameterBagInterface;
use Symfony\Component\HttpKernel\KernelInterface;

class PsyshService
{
    private string $projectDir;
    private Shell $shell;
    private array $capturedVariables = [];

    public function __construct(
        private readonly ParameterBagInterface $parameterBag,
        private readonly KernelInterface $kernel,
        private readonly PsyshTestService $test,
    ) {
        $this->projectDir = $this->parameterBag->get('kernel.project_dir');
    }

    public function shell(): void
    {
        $container = $this->kernel->getContainer();;

        $config = new Configuration();

        // Configuration pour éviter les problèmes de buffer
        $config->setUpdateCheck(Checker::NEVER);
        $config->setColorMode(Configuration::COLOR_MODE_FORCED);

        $this->shell = new Shell($config);

        // Variables disponibles dans le shell
        $shellVariables = [
            'container' => $container,
            'kernel' => $this->kernel,
            'parameterBag' => $this->parameterBag,
            // Check if EntityManager service exists before getting it
            'entityManager' => $container->has('doctrine.orm.entity_manager') ? $container->get('doctrine.orm.entity_manager') : null,
            'em' => $container->has('doctrine.orm.entity_manager') ? $container->get('doctrine.orm.entity_manager') : null,
            'router' => $container->has('router') ? $container->get('router') : null,
            'dispatcher' => $container->has('event_dispatcher') ? $container->get('event_dispatcher') : null,
            'psysh' => $this,
            'phpunit' => $this->test,
            'help' => fn() => $this->help(),
        ];

        $this->shell->setScopeVariables($shellVariables);

        // Ajouter les commandes de monitoring
        $this->shell->add(new PsyshMonitorCommand());
        
        // Ajouter les commandes PHPUnit
        $this->shell->add(new PHPUnitCreateCommand());
        $this->shell->add(new PHPUnitAddCommand());
        $this->shell->add(new PHPUnitCodeCommand());
        $this->shell->add(new PHPUnitAssertCommand());
        $this->shell->add(new PHPUnitRunCommand());
        $this->shell->add(new PHPUnitExportCommand());
        $this->shell->add(new PHPUnitListCommand());
        $this->shell->add(new PHPUnitHelpCommand());

        $this->shell->run();
    }

    /**
     * Exécute une commande unique et retourne le résultat
     */
    public function executeSingle(string $command, OutputInterface $output): int
    {
        $this->initializeShell();
        
        try {
            $result = $this->executeInContext($command);
            
            // Afficher le résultat comme PsySH le ferait
            if ($result !== null) {
                $output->writeln($this->formatResult($result));
            }
            
            return \Symfony\Component\Console\Command\Command::SUCCESS;
        } catch (\Throwable $e) {
            $output->writeln('<error>Error: ' . $e->getMessage() . '</error>');
            return \Symfony\Component\Console\Command\Command::FAILURE;
        }
    }
    
    /**
     * Exécute des commandes depuis stdin avec contexte persistant
     */
    public function executePiped(InputInterface $input, OutputInterface $output): int
    {
        $this->initializeShell();
        
        // Lire tout le contenu depuis stdin
        $handle = fopen('php://stdin', 'r');
        $allInput = '';
        
        while (($line = fgets($handle)) !== false) {
            $allInput .= $line;
        }
        
        fclose($handle);
        
        // Traiter le code multi-lignes
        $commands = $this->parseMultilineInput($allInput);
        
        // Exécuter chaque bloc de commande dans le même contexte
        foreach ($commands as $command) {
            try {
                $result = $this->executeInContext($command);
                
                // Afficher le résultat immédiatement
                if ($result !== null) {
                    $output->writeln($this->formatResult($result));
                }
                
            } catch (\Throwable $e) {
                $output->writeln('<error>Error: ' . $e->getMessage() . '</error>');
                // Continuer l'exécution même en cas d'erreur
            }
        }
        
        return \Symfony\Component\Console\Command\Command::SUCCESS;
    }
    
    /**
     * Parse le code multi-lignes pour grouper les blocs logiques
     */
    private function parseMultilineInput(string $input): array
    {
        $lines = explode("\n", $input);
        $commands = [];
        $currentCommand = '';
        $braceDepth = 0;
        $inClass = false;
        $inFunction = false;
        $inString = false;
        $stringChar = '';
        
        foreach ($lines as $line) {
            $line = trim($line);
            
            // Ignorer les lignes vides et les commentaires
            if (empty($line) || (substr($line, 0, 1) === '#' && !$inString)) {
                continue;
            }
            
            // Arrêter sur "exit"
            if ($line === 'exit' && $braceDepth === 0) {
                break;
            }
            
            // Gérer les chaînes de caractères pour éviter de compter les accolades dans les strings
            for ($i = 0; $i < strlen($line); $i++) {
                $char = $line[$i];
                
                if (!$inString && ($char === '"' || $char === "'")) {
                    $inString = true;
                    $stringChar = $char;
                } elseif ($inString && $char === $stringChar && ($i === 0 || $line[$i-1] !== '\\')) {
                    $inString = false;
                    $stringChar = '';
                } elseif (!$inString) {
                    if ($char === '{') {
                        $braceDepth++;
                    } elseif ($char === '}') {
                        $braceDepth--;
                    }
                }
            }
            
            // Détecter les structures qui nécessitent un groupage
            if ($braceDepth === 0 && preg_match('/^\s*(class|interface|trait|function)\s+/i', $line)) {
                if (preg_match('/^\s*class\s+/i', $line)) {
                    $inClass = true;
                } elseif (preg_match('/^\s*function\s+/i', $line)) {
                    $inFunction = true;
                }
            }
            
            $currentCommand .= $line . "\n";
            
            // Finir le bloc si on est au niveau racine et on a une instruction complète
            if ($braceDepth === 0 && !$inString) {
                // Structures de contrôle ou déclarations qui se terminent naturellement
                if ($inClass || $inFunction) {
                    $inClass = false;
                    $inFunction = false;
                    $commands[] = trim($currentCommand);
                    $currentCommand = '';
                }
                // Ne pas séparer les instructions simples - laisser tout dans un bloc
                // sauf pour les classes et fonctions qui doivent être séparées
            }
        }
        
        // Ajouter le dernier bloc s'il y en a un
        if (!empty(trim($currentCommand))) {
            $commands[] = trim($currentCommand);
        }
        
        return $commands;
    }
    
    /**
     * Initialise le shell sans le démarrer en mode interactif
     */
    private function initializeShell(): void
    {
        if (isset($this->shell)) {
            return;
        }
        
        $container = $this->kernel->getContainer();
        
        $config = new Configuration();
        $config->setUpdateCheck(Checker::NEVER);
        $config->setColorMode(Configuration::COLOR_MODE_FORCED);
        
        $this->shell = new Shell($config);
        
        // Variables disponibles dans le shell
        $shellVariables = [
            'container' => $container,
            'kernel' => $this->kernel,
            'parameterBag' => $this->parameterBag,
            'entityManager' => $container->has('doctrine.orm.entity_manager') ? $container->get('doctrine.orm.entity_manager') : null,
            'em' => $container->has('doctrine.orm.entity_manager') ? $container->get('doctrine.orm.entity_manager') : null,
            'router' => $container->has('router') ? $container->get('router') : null,
            'dispatcher' => $container->has('event_dispatcher') ? $container->get('event_dispatcher') : null,
            'psysh' => $this,
            'phpunit' => $this->test,
            'help' => fn() => $this->help(),
        ];
        
        $this->shell->setScopeVariables($shellVariables);
        
        // Ajouter les commandes de monitoring
        $this->shell->add(new PsyshMonitorCommand());
        
        // Ajouter les commandes PHPUnit
        $this->shell->add(new PHPUnitCreateCommand());
        $this->shell->add(new PHPUnitAddCommand());
        $this->shell->add(new PHPUnitCodeCommand());
        $this->shell->add(new PHPUnitAssertCommand());
        $this->shell->add(new PHPUnitRunCommand());
        $this->shell->add(new PHPUnitExportCommand());
        $this->shell->add(new PHPUnitListCommand());
        $this->shell->add(new PHPUnitHelpCommand());
    }
    
    /**
     * Exécute une commande dans le contexte persistant du shell
     */
    private function executeInContext(string $command): mixed
    {
        // Préparer le code PHP
        $code = $this->preparePhpCode($command);
        
        // Récupérer le contexte actuel
        $scopeVariables = $this->shell->getScopeVariables();
        
        // Construire le code avec import des variables
        $contextCode = '';
        
        // Importer les variables dans le scope d'exécution
        foreach ($scopeVariables as $varName => $varValue) {
            if (!in_array($varName, ['GLOBALS', '_SERVER', '_GET', '_POST', '_COOKIE', '_SESSION', '_ENV', '_FILES']) 
                && $varName !== 'this') {
                try {
                    if (is_scalar($varValue) || is_array($varValue) || is_null($varValue)) {
                        $contextCode .= '$' . $varName . ' = ' . var_export($varValue, true) . ";\n";
                    } elseif (is_object($varValue)) {
                        // Pour les objets, on les stocke directement dans GLOBALS
                        $GLOBALS['_psysh_' . $varName] = $varValue;
                        $contextCode .= '$' . $varName . ' = $GLOBALS["_psysh_' . $varName . '"];' . "\n";
                    }
                } catch (\Exception $e) {
                    // Ignorer les variables non sérialisables
                }
            }
        }
        
        // Exécuter le code dans un contexte isolé
        $evalCode = '$GLOBALS["_psysh_result"] = null; ' . $contextCode . ' ' . $code . '; $GLOBALS["_psysh_vars"] = get_defined_vars();';
        
        // Exécuter le code
        $result = eval($evalCode);
        
        // Récupérer les variables définies dans le contexte d'exécution
        $newVars = $GLOBALS['_psysh_vars'] ?? [];
        
        // Fusionner avec les variables existantes
        foreach ($newVars as $varName => $varValue) {
            if (!in_array($varName, ['_psysh_result', '_psysh_vars']) && 
                $varName !== 'this') {
                $scopeVariables[$varName] = $varValue;
            }
        }
        
        // Mettre à jour le shell avec toutes les variables
        $this->shell->setScopeVariables($scopeVariables);
        
        return $result;
    }
    
    /**
     * Prépare le code PHP pour exécution
     */
    private function preparePhpCode(string $command): string
    {
        $command = trim($command);
        
        // Si c'est déjà une instruction return
        if (preg_match('/^\s*return\s+/i', $command)) {
            return $command . ';';
        }
        
        // Si c'est une assignation ou une déclaration
        if (preg_match('/^\s*(\$\w+\s*=|function\s+|class\s+|interface\s+|trait\s+|namespace\s+)/i', $command)) {
            return $command . '; return null;';
        }
        
        // Si c'est un appel de fonction comme monitor
        if (preg_match('/^\s*monitor\s+/i', $command)) {
            return $command . '; return null;';
        }
        
        // Si c'est une structure de contrôle (for, foreach, if, while, etc.)
        if (preg_match('/^\s*(for|foreach|if|while|do|switch|try)\s*\(/i', $command)) {
            return $command . '; return null;';
        }
        
        // Si c'est une commande d'affichage (echo, print, var_dump, etc.)
        if (preg_match('/^\s*(echo|print|var_dump|print_r)\s+/i', $command)) {
            return $command . '; return null;';
        }
        
        // Si c'est une commande unset
        if (preg_match('/^\s*unset\s*\(/i', $command)) {
            return $command . '; return null;';
        }
        
        // Si ça se termine déjà par un point-virgule, c'est un statement
        if (preg_match('/;\s*$/', $command)) {
            return $command . ' return null;';
        }
        
        // Si c'est un bloc multi-lignes avec accolades
        if (preg_match('/\{[^}]*\}/s', $command)) {
            return $command . '; return null;';
        }
        
        // Sinon, traiter comme une expression à retourner
        return 'return ' . $command . ';';
    }
    
    /**
     * Formate le résultat comme PsySH
     */
    private function formatResult(mixed $result): string
    {
        if ($result === null) {
            return '';
        }
        
        if (is_bool($result)) {
            return $result ? 'true' : 'false';
        }
        
        if (is_scalar($result)) {
            return (string) $result;
        }
        
        if (is_array($result)) {
            return var_export($result, true);
        }
        
        if (is_object($result)) {
            if (method_exists($result, '__toString')) {
                return (string) $result;
            }
            return get_class($result) . ' {#' . spl_object_id($result) . '}';
        }
        
        return var_export($result, true);
    }

    public function help(): void
    {
        $this->shell->writeStdout("\n<fg=yellow;options=bold>✨ Bienvenue dans Psysh Shell de Symfony avec Monitoring Xdebug !</>\n");
        $this->shell->writeStdout("<fg=white>Ce shell vous permet d'exécuter du code PHP dans un environnement Symfony</>\n");
        $this->shell->writeStdout("<fg=white>et de le monitorer en temps réel grâce aux commandes monitor et monitor-advanced.</>\n\n");

        $this->shell->writeStdout("<fg=1;33m🚀 COMMANDES DE MONITORING PRINCIPALES:</>\n");
        $this->shell->writeStdout("  • <fg=green;options=bold>monitor <code></> - Monitor l'exécution du code PHP avec Xdebug.\n");
        $this->shell->writeStdout("  • <fg=green;options=bold>monitor-advanced <code></> - Monitoring avancé avec toutes les fonctionnalités Xdebug 3.x.\n\n");

        $this->shell->writeStdout("<fg=1;33m⚙️ OPTIONS COMMUNES:</>\n");
        $this->shell->writeStdout("  • <fg=cyan>--symfony</> / <fg=cyan>-s</> - Inclure le contexte Symfony (EntityManager, Kernel, etc.)\n");
        $this->shell->writeStdout("  • <fg=cyan>--debug</> / <fg=cyan>-d</> - Afficher des informations de débogage détaillées\n");
        $this->shell->writeStdout("  • <fg=cyan>--timeout=N</> / <fg=cyan>-t N</> - Définir un timeout d'exécution en secondes (défaut: 30)\n");
        $this->shell->writeStdout("  • <fg=cyan>--output-file=path</> - Sauvegarder les rapports dans un fichier (monitor-advanced)\n\n");

        $this->shell->writeStdout("<fg=1;33>✨ EXEMPLES DE MONITORING SIMPLE (<fg=green>monitor</>):</>\n");
        $this->shell->writeStdout("  • <fg=0;36mmonitor \"1+1\"</>\n");
        $this->shell->writeStdout("  • <fg=0;36mmonitor --symfony \"\$em->getRepository('App\\\\Entity\\\\User')->count()\"</>\n");
        $this->shell->writeStdout("  • <fg=0;36mmonitor --trace --xdebug \"for (\$i=0; \$i<100000; \$i++) { /* ... */ }\"</>\n");

        $this->shell->writeStdout("<fg=1;33>⚡ FONCTIONS HELPER:</>\n");
        $this->shell->writeStdout("  • <fg=0;36mresetTerminal()</> # Nettoyer l'affichage\n");
        $this->shell->writeStdout("  • <fg=0;36mhelp()</> # Cette aide\n\n");

        $this->shell->writeStdout("<fg=1;33>📊 MÉTRIQUES AFFICHÉES:</>\n");
        $this->shell->writeStdout("  • ⏱️ Temps d'exécution en temps réel\n");
        $this->shell->writeStdout("  • 💾 Mémoire utilisée / Pic mémoire\n");
        $this->shell->writeStdout("  • 📤 Output du code en temps réel\n");
        $this->shell->writeStdout("  • 📜 Trace d'exécution (avec --trace ou modes avancés)\n");
        $this->shell->writeStdout("  • 🚨 Alertes et suggestions (monitor-advanced)\n\n");

        $this->shell->writeStdout("<fg=white>Utilisez <fg=yellow>list</> pour voir toutes les commandes Psysh disponibles.\n");
        $this->shell->writeStdout("Appuyez sur <fg=red>Ctrl+D</> ou tapez <fg=red>exit</> pour quitter le shell.</>\n");
        $this->shell->writeStdout(str_repeat('━', 100) . "\n");
    }
}
