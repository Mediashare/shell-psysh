<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
class PHPUnitConfigCommand extends \Psy\Extended\Command\BaseCommand
{

    public function __construct()
    {
        parent::__construct('phpunit:config');
    }

    protected function configure(): void
    {
        $this
            ->setDescription('ConfigCommand command for PHPUnit testing')
            ->setHelp('This command provides config functionality for PHPUnit tests.');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $output->writeln('<info>🚧 ConfigCommand command is under development.</info>');
        $output->writeln('<comment>This command will be implemented with full functionality soon.</comment>');
        
        return 0;
    }

    /**
     * Aide standard pour PsySH shell
     */
    public function getStandardHelp(): string
    {
        return "ConfigCommand functionality for PHPUnit testing.\n" .
               "Usage: phpunit:config";
    }

    /**
     * Aide complexe pour commande help dédiée
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => 'phpunit:config',
            'description' => 'ConfigCommand functionality',
            'usage' => [
                'ConfigCommand command usage'
            ],
            'examples' => [
                'ConfigCommand example' => 'Basic usage of the command'
            ],
            'tips' => [
                'phpunit:config: Use this command for config operations'
            ],
            'related' => [
                'help phpunit' => 'Quick help',
                'phpunit:help' => 'General PHPUnit help'
            ]
        ]);
    }
}
