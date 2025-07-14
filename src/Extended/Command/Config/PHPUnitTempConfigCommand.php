<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
class PHPUnitTempConfigCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:temp-config');
    }

    protected function configure(): void
    {
        $this->setDescription('Créer une configuration temporaire pour cette session');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        try {
            $configService = $this->config();
            $configService->createTempConfig();
            
            $output->writeln($this->formatSuccess("✅ Configuration temporaire créée pour cette session"));
            $output->writeln($this->formatInfo("📋 Vous pouvez maintenant modifier la configuration sans affecter le projet"));
            
            return 0;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de la création de la configuration temporaire: " . $e->getMessage()));
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
