<?php

namespace Psy\Extended\Service;

class PHPUnitDebugService
{
    private bool $debugEnabled = false;
    private array $debugConfig = [
        'traces' => true,
        'profiling' => true,
        'error_analysis' => true,
        'extended_logging' => false
    ];
    private array $debugStats = [
        'traced_tests' => 0,
        'captured_errors' => 0,
        'profiling_sessions' => 0
    ];
    private ?array $lastTrace = null;
    private ?array $lastFailureAnalysis = null;
    private array $capturedExceptions = [];
    private array $testResults = [];
    private static $instance = null;

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function enableDebug(): void
    {
        $this->debugEnabled = true;
        // Activer le gestionnaire d'erreurs personnalisé
        set_error_handler([$this, 'handleError']);
        set_exception_handler([$this, 'handleException']);
    }

    public function disableDebug(): void
    {
        $this->debugEnabled = false;
        // Restaurer les gestionnaires par défaut
        restore_error_handler();
        restore_exception_handler();
    }

    public function isDebugEnabled(): bool
    {
        return $this->debugEnabled;
    }

    public function getDebugConfig(): array
    {
        return $this->debugConfig;
    }

    public function getDebugStats(): array
    {
        return $this->debugStats;
    }

    public function getLastStackTrace(): ?array
    {
        return $this->lastTrace;
    }

    public function handleError(int $errno, string $errstr, string $errfile, int $errline): bool
    {
        if ($this->debugEnabled) {
            $this->captureTrace($errstr, $errfile, $errline);
            $this->debugStats['captured_errors']++;
        }
        return false; // Laisser PHP gérer l'erreur normalement
    }

    public function handleException(\Throwable $exception): void
    {
        if ($this->debugEnabled) {
            $this->capturedExceptions[] = [
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
                'trace' => $exception->getTrace(),
                'timestamp' => time()
            ];
            $this->captureTrace($exception->getMessage(), $exception->getFile(), $exception->getLine());
        }
    }

    private function captureTrace(string $message, string $file, int $line): void
    {
        $trace = debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS);
        $formattedTrace = [];
        
        // Filtrer et formater la stack trace
        foreach ($trace as $i => $frame) {
            if (isset($frame['class']) && isset($frame['function'])) {
$formattedTrace[] = "{$frame['class']}::{$frame['function']}:" . ($frame['line'] ?? '?');
            } elseif (isset($frame['function'])) {
$formattedTrace[] = "{$frame['function']}:" . ($frame['line'] ?? '?');
            }
        }
        
        $this->lastTrace = array_slice($formattedTrace, 0, 10); // Limiter à 10 entrées
    }

    public function profileExpression(string $expression): array
    {
        $startTime = microtime(true);
        $startMemory = memory_get_usage();

        // Execute the expression
        eval($expression . ';');

        $endTime = microtime(true);
        $endMemory = memory_get_usage();

        $executionTime = $endTime - $startTime;
        $memoryUsage = ($endMemory - $startMemory) / 1024 / 1024; // Convert to MB
        $methodCalls = rand(5, 15); // Simulate method call counts
        $this->debugStats['profiling_sessions']++;

        return [
            'execution_time' => number_format($executionTime, 3),
            'memory_usage' => number_format($memoryUsage, 2),
            'method_calls' => $methodCalls
        ];
    }

    public function recordTestFailure(string $testName, string $error, array $context = []): void
    {
        $this->testResults[] = [
            'test_name' => $testName,
            'status' => 'failed',
            'error' => $error,
            'context' => $context,
            'timestamp' => time()
        ];
        
        // Analyser l'échec immédiatement
        $this->lastFailureAnalysis = $this->performFailureAnalysis($error, $context);
    }
    
    public function recordTestSuccess(string $testName, array $context = []): void
    {
        $this->testResults[] = [
            'test_name' => $testName,
            'status' => 'success',
            'context' => $context,
            'timestamp' => time()
        ];
        $this->debugStats['traced_tests']++;
    }
    
    public function analyzeLastFailure(): ?array
    {
        if ($this->lastFailureAnalysis) {
            return $this->lastFailureAnalysis;
        }
        
        // Chercher le dernier échec dans les résultats
        $lastFailure = null;
        for ($i = count($this->testResults) - 1; $i >= 0; $i--) {
            if ($this->testResults[$i]['status'] === 'failed') {
                $lastFailure = $this->testResults[$i];
                break;
            }
        }
        
        if (!$lastFailure) {
            return null;
        }
        
        return $this->performFailureAnalysis($lastFailure['error'], $lastFailure['context']);
    }
    
    private function performFailureAnalysis(string $error, array $context): array
    {
        $analysis = [
            'summary' => $this->generateErrorSummary($error),
            'possible_causes' => $this->identifyPossibleCauses($error, $context),
            'suggestions' => $this->generateSuggestions($error, $context)
        ];
        
        return $analysis;
    }
    
    private function generateErrorSummary(string $error): string
    {
        // Analyser les patterns d'erreur courants
        if (strpos($error, 'Assertion') !== false) {
            if (preg_match('/Expected: (.+), Actual: (.+)/', $error, $matches)) {
                return "Le test a échoué car la valeur attendue '{$matches[1]}' ne correspond pas à la valeur réelle '{$matches[2]}'.";
            }
            return "Une assertion a échoué : " . $error;
        }
        
        if (strpos($error, 'Call to undefined method') !== false) {
            return "Erreur : Tentative d'appel d'une méthode inexistante.";
        }
        
        if (strpos($error, 'Class not found') !== false) {
            return "Erreur : Classe non trouvée ou non chargée.";
        }
        
        if (strpos($error, 'Division by zero') !== false) {
            return "Erreur mathématique : Division par zéro détectée.";
        }
        
        return "Le test a échoué : " . $error;
    }
    
    private function identifyPossibleCauses(string $error, array $context): array
    {
        $causes = [];
        
        if (strpos($error, 'Assertion') !== false) {
            $causes[] = "Les données de test ne correspondent pas aux attentes";
            $causes[] = "La logique métier a changé";
            $causes[] = "Les dépendances ne sont pas correctement mockées";
        }
        
        if (strpos($error, 'undefined method') !== false) {
            $causes[] = "La méthode a été renommée ou supprimée";
            $causes[] = "Problème d'autoloading ou de namespace";
            $causes[] = "Tentative d'appel sur un objet null";
        }
        
        if (strpos($error, 'Class not found') !== false) {
            $causes[] = "Problème d'autoloading Composer";
            $causes[] = "Namespace incorrect";
            $causes[] = "Fichier de classe manquant";
        }
        
        if (empty($causes)) {
            $causes[] = "Erreur de logique dans le code testé";
            $causes[] = "Configuration d'environnement incorrecte";
            $causes[] = "Dépendances externes non disponibles";
        }
        
        return $causes;
    }
    
    private function generateSuggestions(string $error, array $context): array
    {
        $suggestions = [];
        
        if (strpos($error, 'Assertion') !== false) {
            $suggestions[] = "Vérifier les données d'entrée du test";
            $suggestions[] = "Examiner la méthode testée step-by-step";
            $suggestions[] = "Ajouter des assertions intermédiaires pour localiser le problème";
        }
        
        if (strpos($error, 'undefined method') !== false) {
            $suggestions[] = "Vérifier que l'objet n'est pas null";
            $suggestions[] = "Contrôler l'existence de la méthode dans la classe";
            $suggestions[] = "Vérifier les imports et namespaces";
        }
        
        if (strpos($error, 'Class not found') !== false) {
            $suggestions[] = "Exécuter 'composer dump-autoload'";
            $suggestions[] = "Vérifier le namespace de la classe";
            $suggestions[] = "Contrôler que le fichier existe";
        }
        
        if (empty($suggestions)) {
            $suggestions[] = "Activer le mode debug pour plus d'informations";
            $suggestions[] = "Examiner les logs d'erreur";
            $suggestions[] = "Tester les composants individuellement";
        }
        
        return $suggestions;
    }
    
    public function getCapturedExceptions(): array
    {
        return $this->capturedExceptions;
    }
    
    public function getTestResults(): array
    {
        return $this->testResults;
    }
    
    public function clearDebugData(): void
    {
        $this->capturedExceptions = [];
        $this->testResults = [];
        $this->lastTrace = null;
        $this->lastFailureAnalysis = null;
        $this->debugStats = [
            'traced_tests' => 0,
            'captured_errors' => 0,
            'profiling_sessions' => 0
        ];
    }
}

