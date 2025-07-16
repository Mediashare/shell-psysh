<?php

/*
 * This file is part of Psy Shell Enhanced.
 */

namespace Psy\Extended\Service;

use Psy\Extended\Model\InteractiveTest;

/**
 * Service for managing PHPUnit tests in PsySH
 */
class PHPUnitService
{
    private static ?self $instance = null;
    private array $tests = [];
    private ?string $currentTest = null;
    private array $codeContext = [];
    
    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Create a new test
     */
    public function createTest(string $className): InteractiveTest
    {
        $testName = $this->generateTestName($className);
        $test = new InteractiveTest($testName, $className);
        $this->tests[$testName] = $test;
        $this->currentTest = $testName;
        return $test;
    }
    
    /**
     * Get a test by name
     */
    public function getTest(string $testName): ?InteractiveTest
    {
        return $this->tests[$testName] ?? null;
    }
    
    /**
     * Get the current test
     */
    public function getCurrentTest(): ?InteractiveTest
    {
        if ($this->currentTest === null) {
            return null;
        }
        return $this->getTest($this->currentTest);
    }
    
    /**
     * Set the current test
     */
    public function setCurrentTest(string $testName): void
    {
        if (isset($this->tests[$testName])) {
            $this->currentTest = $testName;
        }
    }

    public function addMethodToTest(string $testName, string $methodName): void 
    {
        $this->getTest($testName)->addMethod($methodName);
    }
    
    /**
     * List all tests
     */
    public function listTests(): array
    {
        return $this->tests;
    }
    
    /**
     * Get active tests (alias for listTests for backward compatibility)
     */
    public function getActiveTests(): array
    {
        return $this->tests;
    }
    
    /**
     * Run a test by name
     */
    public function runTest(string $testName): array
    {
        $test = $this->getTest($testName);
        if (!$test) {
            return [
                'success' => false,
                'errors' => ["Test '{$testName}' not found"]
            ];
        }
        
        $errors = [];
        $success = true;
        
        try {
            // Execute code lines
            foreach ($test->getCodeLines() as $line) {
                $result = eval($line);
                // Check if there were any errors
                if ($result === false && error_get_last()) {
                    $errors[] = "Error executing line: {$line}";
                    $success = false;
                }
            }
            
            // Execute assertions
            foreach ($test->getAssertions() as $assertion) {
                $result = eval("return {$assertion};");
                if (!$result) {
                    $errors[] = "Assertion failed: {$assertion}";
                    $success = false;
                }
            }
            
        } catch (\Throwable $e) {
            $errors[] = "Exception: " . $e->getMessage();
            $success = false;
        }
        
        return [
            'success' => $success,
            'errors' => $errors
        ];
    }
    
    /**
     * Export a test to a file
     */
    public function exportTest(string $testName, ?string $path = null): string
    {
        $test = $this->getTest($testName);
        if (!$test) {
            throw new \RuntimeException("Test '{$testName}' not found");
        }
        
        $code = $this->generateTestCode($test);
        
        if ($path === null) {
            $path = $this->getDefaultExportPath($testName);
        }
        
        $dir = dirname($path);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        
        file_put_contents($path, $code);
        return $path;
    }
    
    /**
     * Generate test code from InteractiveTest
     */
    private function generateTestCode(InteractiveTest $test): string
    {
        $className = $test->getTestClassName();
        $namespace = $this->extractNamespace($test->getTargetClass());
        
        $code = "<?php\n\n";
        
        if ($namespace) {
            $code .= "namespace {$namespace}\\Tests;\n\n";
        }
        
        $code .= "use PHPUnit\\Framework\\TestCase;\n";
        $code .= "use {$test->getTargetClass()};\n\n";
        
        $code .= "class {$className} extends TestCase\n{\n";
        
        foreach ($test->getMethods() as $methodName => $methodData) {
            $code .= "    public function {$methodName}(): void\n    {\n";
            
            // Add code lines
            foreach ($methodData['code'] as $line) {
                $code .= "        {$line}\n";
            }
            
            // Add assertions
            foreach ($methodData['assertions'] as $assertion) {
                $code .= "        {$assertion}\n";
            }
            
            $code .= "    }\n\n";
        }
        
        $code .= "}\n";
        
        return $code;
    }
    
    /**
     * Generate test name from class name
     */
    private function generateTestName(string $className): string
    {
        $parts = explode('\\', $className);
        $shortName = end($parts);
        // Capitalize the first letter to ensure proper class naming
        return ucfirst($shortName) . 'Test';
    }
    
    /**
     * Extract namespace from class name
     */
    private function extractNamespace(string $className): string
    {
        $parts = explode('\\', $className);
        array_pop($parts);
        return implode('\\', $parts);
    }
    
    /**
     * Get default export path
     */
    private function getDefaultExportPath(string $testName): string
    {
        $dir = getcwd() . '/tests/Generated';
        return $dir . '/' . $testName . '.php';
    }
    
    /**
     * Get or set code context
     */
    public function getCodeContext(): array
    {
        return $this->codeContext;
    }
    
    public function setCodeContext(array $context): void
    {
        $this->codeContext = $context;
    }
    
    public function mergeCodeContext(array $newContext): void
    {
        $this->codeContext = array_merge($this->codeContext, $newContext);
    }
    
    /**
     * Add assertion to existing test (flexible signature)
     */
    public function addAssertionToTest($testNameOrAssertion, ?string $assertion = null): bool
    {
        // Handle both signatures: (testName, assertion) or just (assertion)
        if ($assertion === null) {
            // Single parameter - use current test
            $assertion = $testNameOrAssertion;
            $test = $this->getCurrentTest();
        } else {
            // Two parameters - specific test
            $test = $this->getTest($testNameOrAssertion);
        }
        
        if ($test) {
            $test->addAssertion($assertion);
            return true;
        }
        return false;
    }
    
    /**
     * Add code to existing test (flexible signature)
     */
    public function addCodeToTest($testNameOrCode, ?string $code = null): bool
    {
        dump($testNameOrCode, $code);
        // Handle both signatures: (testName, code) or just (code)
        if ($code === null) {
            // Single parameter - use current test
            $code = $testNameOrCode;
            $test = $this->getCurrentTest();
        } else {
            // Two parameters - specific test
            $test = $this->getTest($testNameOrCode);
        }

        dump($test);
        
        if ($test) {
            $test->addCodeLine($code);
            return true;
        }
        return false;
    }
}
