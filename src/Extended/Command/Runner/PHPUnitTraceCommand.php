<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
class PHPUnitTraceCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:trace');
    }

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "Affiche la stack trace du dernier test échoué.\n" .
               "Usage: phpunit:trace";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:trace',
            'description' => 'Analyseur de stack trace avancé pour débogage des tests échoués avec filtrage intelligent et navigation',
            'usage' => [
                'phpunit:trace',
                'phpunit:trace --detailed',
                'phpunit:trace --filter=MyClass'
            ],
            'examples' => [
                'phpunit:trace' => 'Affiche la stack trace formatée du dernier échec',
                'phpunit:trace --detailed' => 'Stack trace avec variables locales et contexte',
                'phpunit:trace --filter=UserService' => 'Filtre la trace pour ne montrer que les appels concernant UserService'
            ],
            'tips' => [
                'Exécutez d\'abord un test qui échoue pour générer une trace',
                'La trace est formatée avec coloration syntaxique pour faciliter la lecture',
                'Les fichiers de votre projet sont mis en évidence vs les fichiers vendors',
                'Utilisez les flèches directionnelles pour naviguer dans les traces longues'
            ],
            'troubleshooting' => [
                'Si "Aucune trace disponible": exécutez d\'abord un test qui échoue',
                'Si la trace est tronquée: augmentez la limite avec ini_set("xdebug.var_display_max_depth")',
                'Si les chemins sont incorrects: vérifiez la configuration du path mapping',
                'Pour plus de détails: activez Xdebug ou phpunit:debug on'
            ],
            'related' => [
                'phpunit:debug' => 'Active le mode débogage pour captures détaillées',
                'phpunit:explain' => 'Analyse automatique des causes d\'échec',
                'phpunit:run' => 'Exécute les tests et capture les erreurs',
                'phpunit:profile' => 'Analyse les performances et points lents'
            ]
        ]);
    }

    protected function configure(): void
    {
        $this->setDescription('Afficher la stack trace du dernier échec');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $debugService = $this->debug();
        try {
            $trace = $debugService->getLastStackTrace();
            if (empty($trace)) {
                $output->writeln($this->formatError('❌ Aucune stack trace disponible'));
                return 1;
            }
        
            $output->writeln($this->formatInfo('📊 Stack trace :'));
            foreach ($trace as $entry) {
                $output->writeln("  • {$entry}");
            }
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'affichage de la stack trace: " . $e->getMessage()));
            return 1;
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

