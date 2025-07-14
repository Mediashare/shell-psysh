<?php

namespace Psy\Extended\Service;

class PHPUnitProjectService
{
    private static $instance = null;

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function scanTestFiles(string $basePath, ?string $filter = null, ?string $type = null): array
    {
        if (!is_dir($basePath)) {
            throw new \InvalidArgumentException("Le répertoire {$basePath} n'existe pas");
        }

        $testFiles = [];
        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($basePath, \RecursiveDirectoryIterator::SKIP_DOTS)
        );

        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === 'php') {
                $fileName = $file->getFilename();
                
                // Filtrer par nom si spécifié
                if ($filter && strpos($fileName, $filter) === false) {
                    continue;
                }

                // Vérifier si c'est un fichier de test
                if (strpos($fileName, 'Test.php') !== false) {
                    $fileInfo = $this->analyzeTestFile($file->getPathname());
                    
                    // Filtrer par type si spécifié
                    if ($type && $fileInfo['type'] !== $type) {
                        continue;
                    }
                    
                    $fileInfo['relative_path'] = str_replace(getcwd() . '/', '', $file->getPathname());
                    $fileInfo['size'] = $file->getSize();
                    
                    $testFiles[] = $fileInfo;
                }
            }
        }

        // Trier par chemin
        usort($testFiles, fn($a, $b) => strcmp($a['relative_path'], $b['relative_path']));

        return $testFiles;
    }

    public function analyzeTestFile(string $filePath): array
    {
        $content = file_get_contents($filePath);
        $testMethods = [];
        $testCount = 0;

        // Extraire les méthodes de test
        if (preg_match_all('/public function (test\w+)\s*\(/i', $content, $matches)) {
            $testMethods = $matches[1];
            $testCount = count($testMethods);
        }

        // Déterminer le type de test basé sur le chemin
        $type = $this->determineTestType($filePath);

        return [
            'file_path' => $filePath,
            'test_methods' => $testMethods,
            'test_count' => $testCount,
            'type' => $type,
            'class_name' => $this->extractClassName($content),
            'namespace' => $this->extractNamespace($content)
        ];
    }

    private function determineTestType(string $filePath): string
    {
        $path = strtolower($filePath);
        
        if (strpos($path, '/unit/') !== false || strpos($path, '\\unit\\') !== false) {
            return 'Unit';
        } elseif (strpos($path, '/integration/') !== false || strpos($path, '\\integration\\') !== false) {
            return 'Integration';
        } elseif (strpos($path, '/functional/') !== false || strpos($path, '\\functional\\') !== false) {
            return 'Functional';
        } elseif (strpos($path, '/feature/') !== false || strpos($path, '\\feature\\') !== false) {
            return 'Feature';
        } else {
            return 'Unit'; // Défaut
        }
    }

    private function extractClassName(string $content): ?string
    {
        if (preg_match('/class\s+(\w+)/i', $content, $matches)) {
            return $matches[1];
        }
        return null;
    }

    private function extractNamespace(string $content): ?string
    {
        if (preg_match('/namespace\s+([^;]+);/i', $content, $matches)) {
            return $matches[1];
        }
        return null;
    }

    public function runSpecificTest(string $testPath, ?string $method = null): array
    {
        $command = 'vendor/bin/phpunit';
        
        if ($method) {
            $command .= " {$testPath}::{$method}";
        } else {
            $command .= " {$testPath}";
        }
        
        $command .= ' --verbose 2>&1';
        
        $startTime = microtime(true);
        $output = shell_exec($command);
        $executionTime = microtime(true) - $startTime;
        
        // Analyser la sortie pour déterminer le succès
        $success = strpos($output, 'FAILURES!') === false && strpos($output, 'ERRORS!') === false;
        
        return [
            'success' => $success,
            'output' => $output,
            'execution_time' => $executionTime,
            'command' => $command
        ];
    }

public function createTestFile(string $filePath, ?string $className = null): bool
    {
        // Créer le répertoire si nécessaire
        $directory = dirname($filePath);
        if (!is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        // Extraire le nom de classe du chemin si non fourni
        if (!$className) {
            $fileName = basename($filePath, '.php');
            $className = $fileName;
        }

        // Déterminer le namespace basé sur le chemin
        $namespace = $this->generateNamespaceFromPath($filePath);
        
        // Générer le contenu du fichier
        $content = $this->generateTestFileTemplate($className, $namespace);
        
        return file_put_contents($filePath, $content) !== false;
    }

    private function generateNamespaceFromPath(string $filePath): string
    {
        // Convertir le chemin en namespace PSR-4
        $relativePath = str_replace(getcwd() . '/', '', dirname($filePath));
        $namespace = str_replace(['/', '\\'], '\\', $relativePath);
        $namespace = str_replace('tests', 'Tests', $namespace);
        
        return 'Tests\\' . ltrim($namespace, '\\');
    }

    private function generateTestFileTemplate(string $className, string $namespace): string
    {
        $baseClassName = str_replace('Test', '', $className);
        
        return "<?php

namespace {$namespace};

use PHPUnit\\Framework\\TestCase;

class {$className} extends TestCase
{
    protected function setUp(): void
    {
        // Configuration avant chaque test
    }

    protected function tearDown(): void
    {
        // Nettoyage après chaque test
    }

    public function test{$baseClassName}Example(): void
    {
        // TODO: Implémenter le test
        \$this->assertTrue(true);
    }

    /**
     * @dataProvider provideTestData
     */
    public function test{$baseClassName}WithDataProvider(\$input, \$expected): void
    {
        // TODO: Test avec data provider
        \$this->assertEquals(\$expected, \$input);
    }

    public function provideTestData(): array
    {
        return [
            'case 1' => ['input' => 'test', 'expected' => 'test'],
            'case 2' => ['input' => 123, 'expected' => 123],
        ];
    }
}
";
    }

    public function importTestToSession(string $testPath, string $method): array
    {
        $fileInfo = $this->analyzeTestFile($testPath);
        
        if (!in_array($method, $fileInfo['test_methods'])) {
            throw new \InvalidArgumentException("La méthode {$method} n'existe pas dans {$testPath}");
        }

        // Lire le contenu de la méthode
        $content = file_get_contents($testPath);
        $methodContent = $this->extractMethodContent($content, $method);

        return [
            'class_name' => $fileInfo['class_name'],
            'method_name' => $method,
            'method_content' => $methodContent,
            'file_path' => $testPath,
            'namespace' => $fileInfo['namespace']
        ];
    }

    private function extractMethodContent(string $content, string $methodName): string
    {
        $pattern = '/public function ' . preg_quote($methodName) . '\s*\([^)]*\)[^{]*\{(.*?)\n\s*\}/s';
        
        if (preg_match($pattern, $content, $matches)) {
            return trim($matches[1]);
        }
        
        return '';
    }
}
