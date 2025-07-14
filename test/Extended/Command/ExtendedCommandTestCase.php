<?php

/*
 * This file is part of Psy Shell Extended.
 *
 * Test suite for Extended Commands
 */

namespace Psy\Test\Extended\Command;

use Psy\Configuration;
use Psy\Context;
use Psy\Extended\Service\ServiceManager;
use Psy\Shell;
use Psy\Test\TestCase;
use Symfony\Component\Console\Tester\CommandTester;

/**
 * Base test case for Extended Commands
 */
abstract class ExtendedCommandTestCase extends TestCase
{
    protected Shell $shell;
    protected Context $context;
    protected ServiceManager $serviceManager;
    
    protected function setUp(): void
    {
        parent::setUp();
        
        // Reset service manager singleton
        ServiceManager::reset();
        
        // Create shell and context
        $config = new Configuration();
        $this->shell = new Shell($config);
        $this->context = new Context();
        
        // Get service manager instance
        $this->serviceManager = ServiceManager::getInstance();
        $this->serviceManager->setShell($this->shell);
    }
    
    protected function tearDown(): void
    {
        parent::tearDown();
        ServiceManager::reset();
    }
    
    /**
     * Create a command tester with context
     */
    protected function createCommandTester($command): CommandTester
    {
        if (method_exists($command, 'setContext')) {
            $command->setContext($this->context);
        }
        
        // NOTE: We don't add the command to shell because it resets the context
        // $this->shell->add($command);
        
        return new CommandTester($command);
    }
    
    /**
     * Set shell variables for testing
     */
    protected function setShellVariables(array $vars): void
    {
        $this->context->setAll($vars);
    }
    
    /**
     * Get shell variable
     */
    protected function getShellVariable(string $name)
    {
        return $this->context->get($name);
    }
    
    /**
     * Assert command output contains text
     */
    protected function assertOutputContains(CommandTester $tester, string $text): void
    {
        $this->assertStringContainsString($text, $tester->getDisplay());
    }
    
    /**
     * Assert command output matches regex
     */
    protected function assertOutputMatches(CommandTester $tester, string $pattern): void
    {
        $this->assertMatchesRegularExpression($pattern, $tester->getDisplay());
    }
    
    /**
     * Assert command succeeded
     */
    protected function assertCommandSuccess(CommandTester $tester): void
    {
        $this->assertEquals(0, $tester->getStatusCode());
    }
    
    /**
     * Assert command failed
     */
    protected function assertCommandFailure(CommandTester $tester): void
    {
        $this->assertNotEquals(0, $tester->getStatusCode());
    }
    
    /**
     * Initialize command with context and service manager
     */
    protected function initCommand($command): void
    {
        if (method_exists($command, 'setContext')) {
            $command->setContext($this->context);
        }
        
        if (method_exists($command, 'setServiceManager')) {
            $command->setServiceManager($this->serviceManager);
        }
    }
}
