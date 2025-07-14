<?php

namespace Psy\Extended\Service;

use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;

class PHPUnitMockService
{
    protected $testCase;
    
    public function __construct(?TestCase $testCase = null)
    {
        $this->testCase = $testCase;
    }
    
    /**
     * Create a mock object and return info
     */
    public function createMock(string $className, string $variableName, array $methods = [], bool $partial = false): array
    {
        $options = [
            'methods' => $methods,
            'no_constructor' => true,
            'partial' => $partial
        ];
        
        // Generate mock code
        $code = $this->generateMockCode($className, $variableName, $options);
        
        // Get available methods
        $availableMethods = $this->getAvailableMethods($className);
        
        return [
            'code' => $code,
            'available_methods' => $availableMethods,
            'variable_name' => $variableName,
            'class_name' => $className
        ];
    }
    
    /**
     * Generate mock creation code
     */
    public function generateMockCode(string $className, string $variableName, array $options = []): string
    {
        $isInterface = interface_exists($className);
        
        // Pour les tests PHPUnit en mode test
        if (defined('PHPUNIT_TESTSUITE')) {
            // Code simple pour le mode test
            $code = "\${$variableName} = new class()";
            if ($isInterface) {
                $code .= " implements \\{$className}";
            } else {
                $code .= " extends \\{$className}";
            }
            $code .= " {";
            
            // Ajouter un constructeur vide si demandé
            if (!empty($options['no_constructor']) && !$isInterface) {
                $code .= " public function __construct() {} ";
            }
            
            // Si c'est une interface, on doit implémenter toutes les méthodes
            if ($isInterface) {
                $reflection = new \ReflectionClass($className);
                foreach ($reflection->getMethods() as $method) {
                    $code .= $this->generateMethodStub($method);
                }
            }
            
            $code .= "};"; // Point-virgule important!
        } else {
            // En production, utiliser Mockery
            $code = "\${$variableName} = \\Mockery::mock('{$className}');";
        }
        
        return $code;
    }
    
    /**
     * Generate a method stub for interfaces
     */
    private function generateMethodStub(\ReflectionMethod $method): string
    {
        $stub = " public function {$method->getName()}(";
        
        // Ajouter les paramètres
        $params = [];
        foreach ($method->getParameters() as $param) {
            $paramStr = '';
            if ($param->hasType()) {
                $type = $param->getType();
                if ($type instanceof \ReflectionNamedType) {
                    if ($type->allowsNull()) {
                        $paramStr .= '?';
                    }
                    $paramStr .= $type->getName() . ' ';
                }
            }
            $paramStr .= '$' . $param->getName();
            if ($param->isDefaultValueAvailable()) {
                $paramStr .= ' = ' . var_export($param->getDefaultValue(), true);
            }
            $params[] = $paramStr;
        }
        $stub .= implode(', ', $params) . ')';
        
        // Type de retour
        if ($method->hasReturnType()) {
            $returnType = $method->getReturnType();
            if ($returnType instanceof \ReflectionNamedType) {
                $stub .= ': ';
                if ($returnType->allowsNull()) {
                    $stub .= '?';
                }
                $stub .= $returnType->getName();
            }
        }
        
        $stub .= " { ";
        
        // Corps de la méthode (retour par défaut)
        if ($method->hasReturnType()) {
            $returnType = $method->getReturnType();
            if ($returnType instanceof \ReflectionNamedType && !$returnType->allowsNull()) {
                switch ($returnType->getName()) {
                    case 'void':
                        // Pas de return
                        break;
                    case 'int':
                        $stub .= "return 0; ";
                        break;
                    case 'string':
                        $stub .= "return ''; ";
                        break;
                    case 'bool':
                        $stub .= "return false; ";
                        break;
                    case 'array':
                        $stub .= "return []; ";
                        break;
                    case 'float':
                        $stub .= "return 0.0; ";
                        break;
                    default:
                        $stub .= "return null; ";
                }
            } else {
                $stub .= "return null; ";
            }
        }
        
        $stub .= "} ";
        return $stub;
    }
    
    /**
     * Get available methods for a class
     */
    public function getAvailableMethods(string $className): array
    {
        if (!class_exists($className) && !interface_exists($className)) {
            return [];
        }
        
        $reflection = new \ReflectionClass($className);
        $methods = [];
        
        foreach ($reflection->getMethods(\ReflectionMethod::IS_PUBLIC) as $method) {
            if (!$method->isConstructor() && !$method->isDestructor() && !$method->isStatic()) {
                $methods[] = $method->getName();
            }
        }
        
        return $methods;
    }
}
