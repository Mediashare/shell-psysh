<?php

/*
 * Autoload command for PsySH to initialize project context
 */

namespace Psy\Extended\Command;


use Psy\Extended\Command\BaseCommand;
use Psy\Extended\Service\EnvironmentService;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
class AutoloadCommand extends BaseCommand
{
    protected function configure()
    {
        $this
            ->setName('autoload')
            ->setDescription('Autoload the project and provide useful context variables')
            ->setHelp('Automatically loads the project and provides useful context variables and enhanced autocompletion.');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $envService = new EnvironmentService();
        $context = $envService->loadProjectContext();

        // Set scope variables in shell context
        foreach ($context['variables'] as $name => $value) {
            $this->setShellVariable($name, $value);
        }

        // Write welcome message
        $this->writeInfo($output, $context['welcome_message']);

        // Success message
        $this->writeSuccess($output, 'Project autoloaded successfully');
        return 0;
    }
}

