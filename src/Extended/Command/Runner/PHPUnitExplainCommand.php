<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
class PHPUnitExplainCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:explain');
    }

    protected function configure(): void
    {
        $this->setDescription('Expliquer un échec de test récent');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $debugService = $this->debug();
        try {
            $explanation = $debugService->analyzeLastFailure();
            if (!$explanation) {
                $output->writeln($this->formatError('❌ Aucun échec récent à expliquer'));
                return 1;
            }

            $output->writeln($this->formatInfo('💡 Analyse de l\'échec :'));
            $output->writeln('  - ' . $explanation['summary']);

            $output->writeln("Causes possibles :");
            foreach ($explanation['possible_causes'] as $cause) {
                $output->writeln('  • ' . $cause);
            }

            $output->writeln("Suggestions :");
            foreach ($explanation['suggestions'] as $suggestion) {
                $output->writeln('  • ' . $suggestion);
            }

            return 0;

        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'analyse de l'échec: " . $e->getMessage()));
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

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}

