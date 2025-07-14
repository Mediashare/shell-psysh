<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Psy\Extended\Trait\PHPUnitCommandTrait;

class PHPUnitCodeCommand extends \Psy\Extended\Command\BaseCommand
{
    use PHPUnitCommandTrait;

    private ?bool $debug = false;

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "CodeCommand aide à gérer les fragments de code PHPUnit.\n" .
               "Usage: phpunit:code [options]";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'description' => 'Commande de gestion de code pour PHPUnit',
            'usage' => ['phpunit:code --generate', 'phpunit:code --list'],
            'examples' => [
                'phpunit:code --generate' => 'Génère un nouveau fragment de code PHPUnit',
                'phpunit:code --list' => 'Liste tous les fragments de code disponibles'
            ],
        ]);
    }

    public function __construct()
    {
        parent::__construct('phpunit:code');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Entrer en mode code interactif pour développer le test')
            ->addOption('debug', 'd', InputOption::VALUE_NONE, 'Activer le mode debug pour la synchronisation');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $service = $this->phpunit();
        $currentTest = $service->getCurrentTest()?->getTestClassName();
        $this->debug = $input->getOption('debug');
        
        if (!$currentTest) {
            $output->writeln($this->formatError('Aucun test actuel. Créez d\'abord un test avec phpunit:create'));
            return 1;
        }
        
        // Activer le mode debug si demandé
        if ($this->debug) {
            $unifiedSync = $GLOBALS['psysh_unified_sync_service'] ?? null;
            if ($unifiedSync && $unifiedSync instanceof \Psy\Extended\Service\UnifiedSyncService) {
                $unifiedSync->setDebug(true);
                $output->writeln($this->formatInfo("Mode debug activé pour la synchronisation"));
            }
            
            // Afficher les informations de debug
            $this->displayDebugInfo($currentTest);
        }
        
        $this->setCodeMode(true);
        $output->writeln($this->formatTest("Mode code activé pour le test: {$currentTest}"));
        $output->writeln($this->formatInfo("Variables disponibles: \$em (EntityManager), \$container (Container)"));
        $output->writeln($this->formatInfo("Utilisation du shell PsySH natif avec auto-complétion et historique."));
        
        // Démarrer le mode interactif utilisant un shell PsySH natif
        $this->startInteractiveCodeMode();
        
        $this->setCodeMode(false);
        $output->writeln($this->formatSuccess("Mode code terminé."));
        
        return 0;
    }
    
    /**
     * Display debug information
     */
    private function displayDebugInfo(string $testFile): void
    {
        echo "\n" . str_repeat('=', 80) . "\n";
        echo "🐛 MODE DEBUG - PHPUnit Code Command\n";
        echo str_repeat('=', 80) . "\n";
        
        // Informations sur le test
        echo "📄 Test actuel: $testFile\n";
        echo "📍 Mode code: " . ($this->isCodeMode() ? 'ACTIVÉ' : 'DÉSACTIVÉ') . "\n";
        
        // Informations sur les variables disponibles
        $mainShellContext = $this->getMainShellContext();
        $codeContext = $GLOBALS['phpunit_code_context'] ?? [];
        $shellVariables = $GLOBALS['psysh_shell_variables'] ?? [];
        
        echo "\n📊 CONTEXTE VARIABLES:\n";
        echo "   - Variables shell principal: " . count($mainShellContext) . "\n";
        echo "   - Variables contexte code: " . count($codeContext) . "\n";
        echo "   - Variables shell globales: " . count($shellVariables) . "\n";
        
        // Fusionner et afficher les variables
        $allVars = array_merge($shellVariables, $codeContext, $mainShellContext);
        
        if (!empty($allVars)) {
            echo "\n📋 VARIABLES DISPONIBLES DANS LE SHELL:\n";
            foreach ($allVars as $name => $value) {
                $type = gettype($value);
                $preview = $this->getVariablePreview($value);
                echo "   - \$$name ($type): $preview\n";
            }
        }
        
        // Informations sur les services
        echo "\n🔧 SERVICES DISPONIBLES:\n";
        $unifiedSync = $GLOBALS['psysh_unified_sync_service'] ?? null;
        echo "   - Service synchronisation unifié: " . ($unifiedSync ? 'DISPONIBLE' : 'INDISPONIBLE') . "\n";
        
        $syncService = $GLOBALS['psysh_shell_sync_service'] ?? null;
        echo "   - Service synchronisation shell: " . ($syncService ? 'DISPONIBLE' : 'INDISPONIBLE') . "\n";
        
        // Informations sur le test
        $phpunitService = $this->getPhpunitService();
        $test = $phpunitService->getTest($testFile);
        
        if ($test) {
            $codeLines = $test->getCodeLines();
            echo "\n🧪 INFORMATIONS SUR LE TEST:\n";
            echo "   - Lignes de code existantes: " . count($codeLines) . "\n";
            
            if (!empty($codeLines)) {
                echo "   - Aperçu du code existant:\n";
                foreach (array_slice($codeLines, 0, 5) as $i => $line) {
                    echo "     " . ($i + 1) . ": $line\n";
                }
                if (count($codeLines) > 5) {
                    echo "     ... (" . (count($codeLines) - 5) . " lignes supplémentaires)\n";
                }
            }
        }
        
        echo str_repeat('=', 80) . "\n\n";
    }
}
