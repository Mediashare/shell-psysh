<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
class PHPUnitRestoreConfigCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:restore-config');
    }

    protected function configure(): void
    {
        $this->setDescription('Restaurer la configuration PHPUnit originale');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        try {
            $configService = $this->config();
            $restored = $configService->restoreOriginalConfig();
            
            if ($restored) {
                $output->writeln($this->formatSuccess("✅ Configuration restaurée"));
                $output->writeln($this->formatInfo("📋 Configuration originale du projet active"));
            } else {
                $output->writeln($this->formatInfo("📋 Aucune configuration temporaire à restaurer"));
            }
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la restauration: " . $e->getMessage()));
            return 1;
        }
    }
    
    protected function getConfigService(): PHPUnitConfigService
    {
        if (!isset($GLOBALS['phpunit_config_service'])) {
            $GLOBALS['phpunit_config_service'] = new PHPUnitConfigService();
        }
        return $GLOBALS['phpunit_config_service'];
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
