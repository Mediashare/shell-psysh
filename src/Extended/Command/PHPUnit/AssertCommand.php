<?php

/*
 * This file is part of Psy Shell Enhanced.
 */

namespace Psy\Extended\Command\PHPUnit;


use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

/**
 * Add assertions to PHPUnit tests without quotes
 */
class AssertCommand extends BaseCommand
{
    protected function configure()
    {
        $this
            ->setName('phpunit:assert')
            ->setAliases(['assert', 'test:assert'])
            ->setDescription('Add an assertion to the current test (supports expressions without quotes)')
            ->setDefinition([
                new InputArgument('assertion', InputArgument::IS_ARRAY | InputArgument::REQUIRED, 'The assertion expression'),
            ])
            ->setHelp(<<<'HELP'
The <info>phpunit:assert</info> command adds assertions to the current test method.

You can write assertions WITHOUT quotes, making it more natural:

  <info>>>> phpunit:assert $result === 42</info>
  <info>>>> phpunit:assert $user->getName() == "John"</info>
  <info>>>> phpunit:assert count($items) > 0</info>
  <info>>>> phpunit:assert $obj instanceof User</info>

The command automatically converts your expression into proper PHPUnit assertions.

Examples:
  - Equality: <info>$a == $b</info> becomes <info>$this->assertEquals($b, $a)</info>
  - Identity: <info>$a === $b</info> becomes <info>$this->assertSame($b, $a)</info>
  - Instance: <info>$obj instanceof Class</info> becomes <info>$this->assertInstanceOf(Class::class, $obj)</info>
  - Boolean: <info>$value</info> becomes <info>$this->assertTrue($value)</info>
  - Null: <info>$value === null</info> becomes <info>$this->assertNull($value)</info>
HELP
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // Get the raw assertion expression
        $assertionParts = $input->getArgument('assertion');
        $assertion = implode(' ', $assertionParts);
        
        if (empty($assertion)) {
            $this->writeError($output, 'Please provide an assertion expression');
            return 1;
        }
        
        try {
            // Get current test
            $currentTest = $this->phpunit()->getCurrentTest();
            if (!$currentTest) {
                $this->writeError($output, 'No test currently active. Use phpunit:create first.');
                return 1;
            }
            
            // Convert expression to PHPUnit assertion
            $phpunitAssertion = $this->convertToPhpUnitAssertion($assertion);
            
            // Add assertion to test
            $currentTest->addAssertion($phpunitAssertion);
            
            $this->writeSuccess($output, "Assertion added: {$assertion}");
            $this->writeInfo($output, "PHPUnit: {$phpunitAssertion}");
            
            return 0;
        } catch (\Exception $e) {
            $this->writeError($output, 'Error adding assertion: ' . $e->getMessage());
            return 1;
        }
    }
    
    /**
     * Convert raw expression to PHPUnit assertion
     */
    private function convertToPhpUnitAssertion(string $expr): string
    {
        // Trim whitespace
        $expr = trim($expr);
        
        // Check for instanceof
        if (preg_match('/^(.+?)\s+instanceof\s+(.+)$/i', $expr, $matches)) {
            $object = trim($matches[1]);
            $class = trim($matches[2]);
            return "assertInstanceOf({$class}::class, {$object})";
        }
        
        // Check for === (identity)
        if (preg_match('/^(.+?)\s*===\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            
            // Special case for null
            if ($right === 'null') {
                return "assertNull({$left})";
            }
            if ($left === 'null') {
                return "assertNull({$right})";
            }
            
            // Special case for true/false
            if ($right === 'true') {
                return "assertTrue({$left})";
            }
            if ($right === 'false') {
                return "assertFalse({$left})";
            }
            
            return "assertSame({$right}, {$left})";
        }
        
        // Check for == (equality)
        if (preg_match('/^(.+?)\s*==\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertEquals({$right}, {$left})";
        }
        
        // Check for != or !==
        if (preg_match('/^(.+?)\s*!==?\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertNotEquals({$right}, {$left})";
        }
        
        // Check for > or <
        if (preg_match('/^(.+?)\s*>\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertGreaterThan({$right}, {$left})";
        }
        
        if (preg_match('/^(.+?)\s*<\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertLessThan({$right}, {$left})";
        }
        
        // Check for >= or <=
        if (preg_match('/^(.+?)\s*>=\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertGreaterThanOrEqual({$right}, {$left})";
        }
        
        if (preg_match('/^(.+?)\s*<=\s*(.+)$/', $expr, $matches)) {
            $left = trim($matches[1]);
            $right = trim($matches[2]);
            return "assertLessThanOrEqual({$right}, {$left})";
        }
        
        // Check for negation
        if (preg_match('/^!(.+)$/', $expr, $matches)) {
            $inner = trim($matches[1]);
            return "assertFalse({$inner})";
        }
        
        // Default: treat as boolean assertion
        return "assertTrue({$expr})";
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
