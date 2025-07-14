<?php

/*
 * This file is part of Psy Shell Enhanced.
 */

namespace Psy\Extended\Command\PHPUnit;


use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

/**
 * Create a new PHPUnit test interactively
 */
class CreateCommand extends BaseCommand
{
    protected function configure()
    {
        $this
            ->setName('phpunit:create')
            ->setAliases(['test:create', 'tc'])
            ->setDescription('Create a new PHPUnit test interactively')
            ->setDefinition([
                new InputArgument('class', InputArgument::REQUIRED, 'The class to test (e.g., App\\Service\\UserService)'),
            ])
            ->setHelp(<<<'HELP'
The <info>phpunit:create</info> command creates a new PHPUnit test interactively:

  <info>>>> phpunit:create App\Service\UserService</info>

This will create a test for the UserService class and enter interactive mode
where you can add test methods and assertions.

After creating the test, use these commands:
  - <info>phpunit:add</info> to add test methods
  - <info>phpunit:code</info> to add code to the test
  - <info>phpunit:assert</info> to add assertions
  - <info>phpunit:run</info> to execute the test
  - <info>phpunit:export</info> to save the test to a file
HELP
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $className = $input->getArgument('class');
        
        // Validate class name
        if (!$this->isValidClassName($className)) {
            $this->writeError($output, "Invalid class name: {$className}");
            return 1;
        }
        
        try {
            // Create the test
            $test = $this->phpunit()->createTest($className);
            
            // Add default test method
            $test->addMethod('testExample');
            
            $this->writeSuccess($output, "Test created: {$test->getTestName()} (mode interactif)");
            $this->writeInfo($output, "Current test method: testExample");
            $output->writeln('');
            $this->writeInfo($output, "Next steps:");
            $output->writeln("  - Use <info>phpunit:code</info> to add code");
            $output->writeln("  - Use <info>phpunit:assert</info> to add assertions");
            $output->writeln("  - Use <info>phpunit:add</info> to add more test methods");
            $output->writeln("  - Use <info>phpunit:run</info> to execute the test");
            $output->writeln("  - Use <info>phpunit:export</info> to save to file");
            
            // Store in shell context
            $this->setShellVariable('currentTest', $test->getTestName());
            $this->setShellVariable('test', $test);
            
            return 0;
        } catch (\Exception $e) {
            $this->writeError($output, "Error creating test: " . $e->getMessage());
            return 1;
        }
    }
    
    /**
     * Validate class name format
     */
    private function isValidClassName(string $className): bool
    {
        // Simple validation: should contain backslashes or be a simple class name
        return preg_match('/^[A-Za-z_][A-Za-z0-9_\\\\]*$/', $className) === 1;
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
