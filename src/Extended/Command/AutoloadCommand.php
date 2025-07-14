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

        // Get the shell instance to set scope variables
        $shell = $this->getApplication();
        if ($shell instanceof \Psy\Shell) {
            // Initialize the shell sync service
            $syncService = \Psy\Extended\Service\ShellSyncService::getInstance();
            $syncService->setMainShell($shell);
            $GLOBALS['psysh_shell_sync_service'] = $syncService;
            
            // Get current scope variables
            $currentVars = $shell->getScopeVariables();
            
            // Merge with new variables from context
            $updatedVars = array_merge($currentVars, $context['variables']);
            
            // Set all variables in shell scope
            $shell->setScopeVariables($updatedVars);
            
            // Sync to all contexts
            $syncService->syncFromMainShell();
        }

        // Write welcome message
        $output->writeln($this->formatInfo($context['welcome_message']));

        // Success message
        $output->writeln($this->formatSuccess('Project autoloaded successfully'));
        return 0;
    }
}

