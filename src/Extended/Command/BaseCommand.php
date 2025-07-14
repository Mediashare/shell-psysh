<?php

namespace Psy\Extended\Command;


use Psy\Command\Command;
use Psy\Context;
use Psy\Shell;
use Symfony\Component\Console\Input\InputInterface;

abstract class BaseCommand extends Command
{
    use \Psy\Extended\Trait\PHPUnitCommandTrait;
    use \Psy\Extended\Trait\CommandHelpTrait;
    use \Psy\Extended\Trait\ServiceAwareTrait;
    use \Psy\Extended\Trait\OutputFormatterTrait {
        \Psy\Extended\Trait\CommandHelpTrait::formatComplexHelp insteadof \Psy\Extended\Trait\OutputFormatterTrait;
    }
    protected $context;
    protected $shell;
    
    public function setContext(Context $context)
    {
        $this->context = $context;
        return $this;
    }
    
    protected function getContext(): Context
    {
        if (!$this->context) {
            $this->context = new Context();
        }
        return $this->context;
    }
    
    protected function setContextVariable(string $name, $value): void
    {
        $context = $this->getContext();
        $variables = $context->getAll();
        $variables[$name] = $value;
        $context->setAll($variables);
    }
    
    protected function getContextVariable(string $name, $default = null)
    {
        $context = $this->getContext();
        $variables = $context->getAll();
        return $variables[$name] ?? $default;
    }
    
    public function getShell(): Shell
    {
        if (!$this->shell) {
            // Create a dummy shell for testing
            $this->shell = new class extends Shell {
                public function __construct() {
                    // Minimal constructor
                }
                
                public function addInput($input, bool $silent = false): string
                {
                    return '';
                }
                
                public function getVersion(): string
                {
                    return 'test-version';
                }
            };
        }
        return $this->shell;
    }
    
    protected function displayCommandHeader(\Symfony\Component\Console\Output\OutputInterface $output, string $title): void
    {
        $output->writeln('');
        $output->writeln('<info>' . str_repeat('=', 60) . '</info>');
        $output->writeln('<info>' . str_pad($title, 60, ' ', STR_PAD_BOTH) . '</info>');
        $output->writeln('<info>' . str_repeat('=', 60) . '</info>');
        $output->writeln('');
    }
    
    protected function addToCurrentTest(string $code): void
    {
        // Implementation for adding code to current test
        $currentTest = $this->getContextVariable('currentTest', []);
        $currentTest[] = $code;
        $this->setContextVariable('currentTest', $currentTest);
    }
}
