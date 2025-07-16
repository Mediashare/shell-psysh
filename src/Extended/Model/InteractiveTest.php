<?php

/*
 * This file is part of Psy Shell Enhanced.
 */

namespace Psy\Extended\Model;

/**
 * Model representing an interactive PHPUnit test
 */
class InteractiveTest
{
    private string $testName;
    private string $targetClass;
    private array $methods = [];
    private string $currentMethod = '';
    
    public function __construct(string $testName, string $targetClass)
    {
        $this->testName = $testName;
        $this->targetClass = $targetClass;
    }
    
    /**
     * Add a test method
     */
    public function addMethod(string $methodName): void
    {
        $this->methods[$methodName] = [
            'code' => [],
            'assertions' => [],
        ];
        $this->currentMethod = $methodName;
    }
    
    /**
     * Add code line to current method
     */
    public function addCodeLine(string $code): void
    {
        if (empty($this->currentMethod)) {
            throw new \RuntimeException('No method selected. Use addMethod() first.');
        }
        
        $this->methods[$this->currentMethod]['code'][] = $code;
    }
    
    /**
     * Add multiple code lines
     */
    public function addCodeLines(array $lines): void
    {
        foreach ($lines as $line) {
            $this->addCodeLine($line);
        }
    }
    
    /**
     * Add assertion to current method
     */
    public function addAssertion(string $assertion): void
    {
        if (empty($this->currentMethod)) {
            throw new \RuntimeException('No method selected. Use addMethod() first.');
        }
        
        // Ensure assertion starts with $this->
        if (!str_starts_with($assertion, '$this->')) {
            $assertion = '$this->' . $assertion;
        }
        
        // Ensure assertion ends with semicolon
        if (!str_ends_with($assertion, ';')) {
            $assertion .= ';';
        }
        
        $this->methods[$this->currentMethod]['assertions'][] = $assertion;
    }
    
    /**
     * Get test name
     */
    public function getTestName(): string
    {
        return $this->testName;
    }
    
    /**
     * Get test class name (without Test suffix)
     */
    public function getTestClassName(): string
    {
        return $this->testName;
    }
    
    /**
     * Get target class
     */
    public function getTargetClass(): string
    {
        return $this->targetClass;
    }
    
    /**
     * Set target class
     */
    public function setTargetClass(string $targetClass): void
    {
        $this->targetClass = $targetClass;
    }
    
    /**
     * Get all methods
     */
    public function getMethods(): array
    {
        return $this->methods;
    }
    
    /**
     * Get current method data
     */
    public function getCurrentMethodData(): ?array
    {
        if (empty($this->currentMethod)) {
            return null;
        }
        return $this->methods[$this->currentMethod] ?? null;
    }
    
    /**
     * Get code lines for current method
     */
    public function getCodeLines(): array
    {
        $data = $this->getCurrentMethodData();
        return $data['code'] ?? [];
    }
    
    /**
     * Get assertions for current method
     */
    public function getAssertions(): array
    {
        $data = $this->getCurrentMethodData();
        return $data['assertions'] ?? [];
    }
    
    /**
     * Get current method name
     */
    public function getCurrentMethod(): string
    {
        return $this->currentMethod;
    }
    
    /**
     * Set current method
     */
    public function setCurrentMethod(string $methodName): void
    {
        if (!isset($this->methods[$methodName])) {
            throw new \RuntimeException("Method '{$methodName}' does not exist");
        }
        $this->currentMethod = $methodName;
    }
    
    /**
     * Check if has methods
     */
    public function hasMethods(): bool
    {
        return !empty($this->methods);
    }
    
    /**
     * Get code line count for current method
     */
    public function getCodeLineCount(): int
    {
        $data = $this->getCurrentMethodData();
        return count($data['code'] ?? []);
    }
    
    /**
     * Get statistics
     */
    public function getStats(): array
    {
        $totalCode = 0;
        $totalAssertions = 0;
        
        foreach ($this->methods as $method) {
            $totalCode += count($method['code']);
            $totalAssertions += count($method['assertions']);
        }
        
        return [
            'methods' => count($this->methods),
            'code_lines' => $totalCode,
            'assertions' => $totalAssertions,
        ];
    }
}
