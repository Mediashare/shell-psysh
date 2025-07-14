<?php

namespace Psy\Extended\Command\Config;


use Psy\Command\HelpCommand as BaseHelpCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Application;

/**
 * Custom Help Command qui utilise getComplexHelp() pour les commandes PHPUnit
 */
class CustomHelpCommand extends BaseHelpCommand
{
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $commandName = $input->getArgument('command_name');
        
        // Si c'est une commande phpunit:*, essayer d'utiliser getComplexHelp()
        if ($commandName && str_starts_with($commandName, 'phpunit:')) {
            $application = $this->getApplication();
            
            if ($application && $application->has($commandName)) {
                $command = $application->get($commandName);
                
                // Vérifier si la commande a getComplexHelp()
                if (method_exists($command, 'getComplexHelp')) {
                    $output->writeln($command->getComplexHelp());
                    return 0;
                }
            }
        }
        
        // Sinon, utiliser l'aide standard de PsySH
        return parent::execute($input, $output);
    }
}
