<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputOption;

class PHPUnitWatchCommand extends \Psy\Extended\Command\BaseCommand
{

    private bool $shouldStop = false;
    private array $watchedFiles = [];
    private array $lastModified = [];

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Surveille les fichiers et re-exécute automatiquement les tests affectés.\n" .
               "Usage: phpunit:watch [options]";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:watch',
            'description' => 'Système de surveillance intelligent qui détecte les changements et exécute automatiquement les tests concernés',
            'usage' => [
                'phpunit:watch',
                'phpunit:watch --paths=src,tests',
                'phpunit:watch --filter=UserTest',
                'phpunit:watch --delay=500'
            ],
            'options' => [
                '--paths' => 'Répertoires à surveiller (séparés par des virgules)',
                '--filter' => 'Filtre les tests à exécuter selon un pattern',
                '--delay' => 'Délai en millisecondes avant re-exécution (défaut: 1000)',
                '--exclude' => 'Patterns de fichiers à ignorer'
            ],
            'examples' => [
                'phpunit:watch' => 'Surveille src/ et tests/ avec détection automatique des tests affectés',
                'phpunit:watch --paths=app/Services' => 'Surveille uniquement le répertoire Services',
                'phpunit:watch --filter=Integration' => 'Exécute seulement les tests d\'intégration lors des changements',
                'phpunit:watch --delay=2000' => 'Attend 2 secondes avant de relancer les tests'
            ],
            'tips' => [
                'Utilisez Ctrl+C pour arrêter la surveillance proprement',
                'Les tests sont exécutés seulement si les fichiers concernés changent',
                'La détection intelligente évite les exécutions multiples rapides',
                'Les résultats sont conservés entre les exécutions pour comparaison'
            ],
            'workflows' => [
                'Développement TDD' => [
                    '1. Lancer phpunit:watch en arrière-plan',
                    '2. Écrire ou modifier un test',
                    '3. Voir l\'exécution automatique du test',
                    '4. Implémenter le code jusqu\'à validation'
                ],
                'Refactoring sécurisé' => [
                    '1. Activer la surveillance avec phpunit:watch',
                    '2. Modifier le code source',
                    '3. Observer les tests impactés exécutés automatiquement',
                    '4. Corriger immédiatement si des tests échouent'
                ]
            ],
            'related' => [
                'phpunit:run' => 'Exécute manuellement un test spécifique',
                'phpunit:list' => 'Voir tous les tests disponibles pour surveillance',
                'phpunit:debug' => 'Active le mode debug pour la surveillance'
            ]
        ]);
    }

    public function __construct()
    {
        parent::__construct('phpunit:watch');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Mode watch - Les tests se relancent automatiquement')
            ->addOption('path', 'p', InputOption::VALUE_OPTIONAL, 'Répertoire à surveiller', 'src')
            ->addOption('test-path', 't', InputOption::VALUE_OPTIONAL, 'Répertoire des tests', 'tests')
            ->addOption('interval', 'i', InputOption::VALUE_OPTIONAL, 'Intervalle de vérification (secondes)', '1')
            ->addOption('extensions', 'e', InputOption::VALUE_OPTIONAL, 'Extensions à surveiller', 'php');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $watchPath = $input->getOption('path');
        $testPath = $input->getOption('test-path');
        $interval = (int) $input->getOption('interval');
        $extensions = explode(',', $input->getOption('extensions'));
        
        try {
            $this->initializeWatcher($watchPath, $testPath, $extensions, $output);
            
            $output->writeln($this->formatTest("👁️ Mode watch activé - Les tests se relancent automatiquement..."));
            $output->writeln($this->formatInfo("📁 Surveillance: {$watchPath}"));
            $output->writeln($this->formatInfo("🧪 Tests: {$testPath}"));
            $output->writeln($this->formatInfo("⏱️  Intervalle: {$interval}s"));
            $output->writeln($this->formatInfo("📄 Extensions: " . implode(', ', $extensions)));
            $output->writeln($this->formatInfo("⌨️  Appuyez sur Ctrl+C pour arrêter"));
            $output->writeln("");
            
            // Gestionnaire de signal pour arrêt propre
            if (function_exists('pcntl_signal')) {
                pcntl_signal(SIGINT, [$this, 'handleSignal']);
                pcntl_signal(SIGTERM, [$this, 'handleSignal']);
            }
            
            // Exécuter les tests une première fois
            $this->runTests($output);
            
            // Boucle principale de surveillance
            while (!$this->shouldStop) {
                if (function_exists('pcntl_signal_dispatch')) {
                    pcntl_signal_dispatch();
                }
                
                $changedFiles = $this->checkForChanges();
                
                if (!empty($changedFiles)) {
                    $output->writeln("");
                    $output->writeln($this->formatInfo("🔄 Changements détectés:"));
                    foreach ($changedFiles as $file) {
                        $output->writeln("  • " . basename($file));
                    }
                    $output->writeln("");
                    
                    $this->runTests($output);
                }
                
                sleep($interval);
            }
            
            $output->writeln("");
            $output->writeln($this->formatInfo("🛑 Mode watch arrêté"));
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur en mode watch: " . $e->getMessage()));
            return 1;
        }
    }
    
    public function handleSignal(int $signal, int|false $previousExitCode = 0): int|false
    {
        $this->shouldStop = true;
        return false;
    }
    
    private function initializeWatcher(string $watchPath, string $testPath, array $extensions, OutputInterface $output): void
    {
        $this->watchedFiles = [];
        $this->lastModified = [];
        
        // Ajouter les fichiers des répertoires surveillés
        $paths = [$watchPath, $testPath];
        
        foreach ($paths as $path) {
            if (is_dir($path)) {
                $this->addFilesFromDirectory($path, $extensions);
            }
        }
        
        $output->writeln($this->formatInfo("📋 " . count($this->watchedFiles) . " fichiers surveillés"));
    }
    
    private function addFilesFromDirectory(string $directory, array $extensions): void
    {
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($directory, \RecursiveDirectoryIterator::SKIP_DOTS)
        );
        
        foreach ($iterator as $file) {
            if ($file->isFile()) {
                $extension = pathinfo($file->getPathname(), PATHINFO_EXTENSION);
                if (in_array($extension, $extensions)) {
                    $filePath = $file->getPathname();
                    $this->watchedFiles[] = $filePath;
                    $this->lastModified[$filePath] = filemtime($filePath);
                }
            }
        }
    }
    
    private function checkForChanges(): array
    {
        $changedFiles = [];
        
        foreach ($this->watchedFiles as $file) {
            if (!file_exists($file)) {
                // Fichier supprimé, le retirer de la surveillance
                $this->removeFromWatch($file);
                $changedFiles[] = $file;
                continue;
            }
            
            $currentModified = filemtime($file);
            
            if ($currentModified > $this->lastModified[$file]) {
                $this->lastModified[$file] = $currentModified;
                $changedFiles[] = $file;
            }
        }
        
        return $changedFiles;
    }
    
    private function removeFromWatch(string $file): void
    {
        $key = array_search($file, $this->watchedFiles);
        if ($key !== false) {
            unset($this->watchedFiles[$key]);
        }
        unset($this->lastModified[$file]);
    }
    
    private function runTests(OutputInterface $output): void
    {
        $timestamp = date('H:i:s');
        $output->writeln(str_repeat("─", 60));
        $output->writeln($this->formatTest("🧪 [{$timestamp}] Exécution des tests..."));
        $output->writeln(str_repeat("─", 60));
        
        try {
            // Exécuter les tests interactifs d'abord
            $service = $this->phpunit();
            $activeTests = $service->getActiveTests();
            
            if (!empty($activeTests)) {
                $output->writeln($this->formatInfo("📋 Tests interactifs:"));
                
                foreach ($activeTests as $testName => $test) {
                    $output->write("  • {$testName} ... ");
                    
                    try {
                        $result = $service->runTest($testName);
                        if ($result['success']) {
                            $output->writeln($this->formatSuccess("✅"));
                        } else {
                            $output->writeln($this->formatError("❌"));
                        }
                    } catch (\Exception $e) {
                        $output->writeln($this->formatError("💥"));
                    }
                }
                $output->writeln("");
            }
            
            // Optionnel: Exécuter aussi les tests du projet
            if (file_exists('vendor/bin/phpunit')) {
                $output->writeln($this->formatInfo("📋 Tests du projet:"));
                
                $command = 'vendor/bin/phpunit --stop-on-failure --no-coverage';
                $process = proc_open($command, [
                    1 => ['pipe', 'w'],
                    2 => ['pipe', 'w']
                ], $pipes, getcwd());
                
                if (is_resource($process)) {
                    $stdout = stream_get_contents($pipes[1]);
                    $stderr = stream_get_contents($pipes[2]);
                    fclose($pipes[1]);
                    fclose($pipes[2]);
                    $exitCode = proc_close($process);
                    
                    if ($exitCode === 0) {
                        $output->writeln($this->formatSuccess("  ✅ Tests du projet réussis"));
                    } else {
                        $output->writeln($this->formatError("  ❌ Tests du projet échoués"));
                    }
                } else {
                    $output->writeln($this->formatError("  💥 Impossible d'exécuter PHPUnit"));
                }
            }
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("💥 Erreur: " . $e->getMessage()));
        }
        
        $output->writeln("");
        $output->writeln($this->formatInfo("👁️ En attente de changements..."));
    }
}
