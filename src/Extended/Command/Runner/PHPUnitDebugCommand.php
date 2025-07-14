<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;use Psy\Extended\Service\PHPUnitDebugService;

class PHPUnitDebugCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:debug');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Activer/désactiver le mode debug PHPUnit')
            ->addArgument('mode', InputArgument::OPTIONAL, 'Mode debug (on/off/status)', 'status');
    }

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Active/désactive le mode debug PHPUnit avec informations détaillées.\n" .
               "Usage: phpunit:debug [mode]\n" .
               "Modes: on, off, status";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:debug',
            'description' => 'Système de débogage avancé pour les tests PHPUnit',
            'usage' => [
                'phpunit:debug',
                'phpunit:debug on',
                'phpunit:debug off',
                'phpunit:debug status'
            ],
            'options' => [
                'on/enable' => 'Active le mode debug avec traces et profiling',
                'off/disable' => 'Désactive le mode debug',
                'status/info' => 'Affiche le statut actuel du debug'
            ],
            'examples' => [
                'phpunit:debug' => 'Affiche le statut actuel du mode debug',
                'phpunit:debug on' => 'Active le débogage avec toutes les fonctionnalités',
                'phpunit:debug off' => 'Désactive complètement le debug',
                'phpunit:debug status' => 'Informations détaillées sur la configuration'
            ],
            'tips' => [
                'Le mode debug ralentit l\'exécution mais fournit plus d\'informations',
                'Les statistiques sont conservées durant la session',
                'Utilisez \"phpunit:trace\" pour voir les détails des échecs'
            ],
            'advanced' => [
                'Capture automatique des traces d\'exécution',
                'Profiling des performances de tests',
                'Analyse des erreurs avec contexte',
                'Logging étendu pour diagnostic approfondi'
            ],
            'troubleshooting' => [
                'Si les performances sont lentes: désactivez le profiling',
                'Pour des logs plus détaillés: vérifiez les permissions d\'écriture',
                'Les données de debug sont conservées en mémoire uniquement'
            ]
        ]);
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $mode = $input->getArgument('mode');
        $debugService = $this->debug();
        
        try {
            switch (strtolower($mode)) {
                case 'on':
                case 'enable':
                case 'true':
                    $debugService->enableDebug();
                    $output->writeln($this->formatSuccess("✅ Mode debug activé"));
                    $this->showDebugInfo($output, $debugService);
                    break;
                    
                case 'off':
                case 'disable':
                case 'false':
                    $debugService->disableDebug();
                    $output->writeln($this->formatSuccess("✅ Mode debug désactivé"));
                    break;
                    
                case 'status':
                case 'info':
                default:
                    $this->showDebugStatus($output, $debugService);
                    break;
            }
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la gestion du debug: " . $e->getMessage()));
            return 1;
        }
    }
    
    private function showDebugStatus(OutputInterface $output, PHPUnitDebugService $debugService): void
    {
        $isEnabled = $debugService->isDebugEnabled();
        
        $output->writeln($this->formatInfo("📊 Statut du mode debug:"));
        $output->writeln("  • Mode debug: " . ($isEnabled ? $this->formatSuccess("ACTIVÉ") : $this->formatError("DÉSACTIVÉ")));
        
        if ($isEnabled) {
            $this->showDebugInfo($output, $debugService);
        } else {
            $output->writeln("");
            $output->writeln($this->formatInfo("💡 Pour activer: phpunit:debug on"));
        }
    }
    
    private function showDebugInfo(OutputInterface $output, PHPUnitDebugService $debugService): void
    {
        $config = $debugService->getDebugConfig();
        
        $output->writeln("");
        $output->writeln($this->formatInfo("🔧 Configuration debug:"));
        $output->writeln("  • Traces activées: " . ($config['traces'] ? '✅' : '❌'));
        $output->writeln("  • Profiling activé: " . ($config['profiling'] ? '✅' : '❌'));
        $output->writeln("  • Analyse d'erreurs: " . ($config['error_analysis'] ? '✅' : '❌'));
        $output->writeln("  • Logging étendu: " . ($config['extended_logging'] ? '✅' : '❌'));
        
        $stats = $debugService->getDebugStats();
        if (!empty($stats)) {
            $output->writeln("");
            $output->writeln($this->formatInfo("📈 Statistiques debug:"));
            $output->writeln("  • Tests tracés: " . $stats['traced_tests']);
            $output->writeln("  • Erreurs capturées: " . $stats['captured_errors']);
            $output->writeln("  • Sessions de profiling: " . $stats['profiling_sessions']);
        }
    }
    
    private function getDebugService(): PHPUnitDebugService
    {
        if (!isset($GLOBALS['phpunit_debug_service'])) {
            $GLOBALS['phpunit_debug_service'] = new PHPUnitDebugService();
        }
        return $GLOBALS['phpunit_debug_service'];
    }
}
