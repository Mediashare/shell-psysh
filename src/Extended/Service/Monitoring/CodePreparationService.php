<?php

namespace Psy\Extended\Service\Monitoring;

use Psy\Shell;

/**
 * Service pour préparer et transformer le code PHP
 * Gère l'injection de contexte et la préparation du code pour l'exécution
 */
class CodePreparationService
{
    private ?Shell $shell = null;
    private bool $debug = false;
    
    public function __construct(?Shell $shell = null)
    {
        $this->shell = $shell;
    }
    
    /**
     * Configure le shell PsySH
     */
    public function setShell(Shell $shell): void
    {
        $this->shell = $shell;
    }
    
    /**
     * Active/désactive le mode debug
     */
    public function setDebug(bool $debug): void
    {
        $this->debug = $debug;
    }
    
    /**
     * Prépare le code avec le contexte des variables
     */
    public function prepareCode(string $code): string
    {
        // Stocker les variables du scope dans une propriété statique temporaire
        if ($this->shell) {
            $scopeVars = $this->shell->getScopeVariables();
            // Stocker dans une variable globale temporaire
            $GLOBALS['__psysh_monitor_scope'] = $scopeVars;
            if ($this->debug) {
                error_log("DEBUG: Shell available, scope vars: " . implode(", ", array_keys($scopeVars)));
            }
        } else {
            if ($this->debug) {
                error_log("DEBUG: No shell available!");
            }
        }
        
        // Construire le code final
        $finalCode = '';
        
        // Ajouter la fonction helper pour les sleep interruptibles
        $finalCode .= $this->getSleepHelperFunction() . PHP_EOL;
        
        // Importer les variables depuis le tableau global
        // IMPORTANT: Les closures et objets sont passés par référence dans $GLOBALS
        $finalCode .= 'if (isset($GLOBALS["__psysh_monitor_scope"])) {' . PHP_EOL;
        if ($this->debug) {
            $finalCode .= '    error_log("DEBUG: __psysh_monitor_scope keys: " . implode(", ", array_keys($GLOBALS["__psysh_monitor_scope"])));' . PHP_EOL;
            $finalCode .= '    error_log("DEBUG: All GLOBALS keys: " . implode(", ", array_keys($GLOBALS)));' . PHP_EOL;
            $finalCode .= '    error_log("DEBUG: get_defined_vars keys: " . implode(", ", array_keys(get_defined_vars())));' . PHP_EOL;
        }
        $finalCode .= '    foreach ($GLOBALS["__psysh_monitor_scope"] as $__var_name => $__var_value) {' . PHP_EOL;
        $finalCode .= '        if (!in_array($__var_name, ["_", "__out", "__psysh__", "__psysh_out__", "__file", "__line", "__dir", "this", "__psysh_monitor_scope"])) {' . PHP_EOL;
        if ($this->debug) {
            $finalCode .= '            error_log("DEBUG: Importing variable: $__var_name = " . gettype($__var_value));' . PHP_EOL;
        }
        $finalCode .= '            ${$__var_name} = $__var_value;' . PHP_EOL;
        $finalCode .= '        }' . PHP_EOL;
        $finalCode .= '    }' . PHP_EOL;
        $finalCode .= '} else {' . PHP_EOL;
        if ($this->debug) {
            $finalCode .= '    error_log("DEBUG: __psysh_monitor_scope NOT SET!");' . PHP_EOL;
        }
        $finalCode .= '}' . PHP_EOL;
        
        // Ajouter un marqueur pour capturer les variables initiales
        $finalCode .= '$__psysh_monitor_initial_vars = array_keys(get_defined_vars());' . PHP_EOL;
        
        // Ajouter le code utilisateur
        $trimmedCode = trim($code);
        
        // Détecter si le code contient des structures de langage (class, function, etc.)
        $hasLanguageConstruct = preg_match('/^\s*(class|interface|trait|function|namespace|use)\s+/im', $trimmedCode);
        
        // Cas 1: Return explicite
        if (preg_match('/^\s*return\s+/i', $trimmedCode)) {
            if ($this->debug) {
                error_log("DEBUG: Using case 1: Return explicite");
            }
            $finalCode .= $code . ';';
            return $finalCode;
        }
        
        // Cas 2: Code avec structures de langage ou multi-lignes
        if ($hasLanguageConstruct || strpos($code, "\n") !== false) {
            if ($this->debug) {
                error_log("DEBUG: Using case 2: Multi-lignes ou structures de langage");
            }
            return $this->handleMultiLineCodeSimple($finalCode, $code);
        }
        
        // Cas 3: Expressions multiples sur une ligne (séparées par ;)
        // Détecter s'il y a au moins une instruction suivie d'un point-virgule et d'une autre expression
        if (substr_count($trimmedCode, ';') >= 1 && !preg_match('/[{}]/', $trimmedCode) && preg_match('/.*;\s*\S/', $trimmedCode)) {
            if ($this->debug) {
                error_log("DEBUG: Using case 3: Expressions multiples, semicolon count=" . substr_count($trimmedCode, ';'));
            }
            // Diviser par ; et prendre la dernière expression non vide
            $parts = explode(';', $trimmedCode);
            $lastExpression = '';
            $codeBeforeLastExpression = [];
            
            for ($i = count($parts) - 1; $i >= 0; $i--) {
                $part = trim($parts[$i]);
                if (!empty($part)) {
                    $lastExpression = $part;
                    $codeBeforeLastExpression = array_slice($parts, 0, $i);
                    break;
                }
            }
            
            // Ajouter le code avant la dernière expression
            if (!empty($codeBeforeLastExpression)) {
                $beforeCode = implode(';', $codeBeforeLastExpression);
                if (!empty(trim($beforeCode))) {
                    $finalCode .= $beforeCode . ';' . PHP_EOL;
                }
            }
            
            // Retourner la dernière expression
            if (!empty($lastExpression)) {
                // Vérifier si c'est une variable simple
                if (preg_match('/^\s*\$([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)\s*$/', $lastExpression, $matches)) {
                    $finalCode .= $this->generateVariableExportCode();
                    $finalCode .= 'return $' . $matches[1] . ';';
                    return $finalCode;
                }
                // Sinon, traiter comme une expression
                $finalCode .= '$__psysh_monitor_result = (' . $lastExpression . ');' . PHP_EOL;
                $finalCode .= $this->generateVariableExportCode();
                $finalCode .= 'return $__psysh_monitor_result;';
                return $finalCode;
            }
        }
        
        // Cas 4: Assignation simple (sans point-virgule interne)
        if (preg_match('/^\s*\$([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)\s*=\s*([^;]+?);?\s*$/', $trimmedCode, $matches)) {
            if ($this->debug) {
                error_log("DEBUG: Using case 4: Assignation simple, varName=" . $matches[1]);
            }
            $varName = $matches[1];
            $finalCode .= $code;
            if (!preg_match('/;\s*$/', $code)) {
                $finalCode .= ';';
            }
            $finalCode .= PHP_EOL;
            $finalCode .= $this->generateVariableExportCode();
            $finalCode .= 'return $' . $varName . ';';
            return $finalCode;
        }
        
        // Cas 5: Variable simple
        if (preg_match('/^\s*\$([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)\s*;?\s*$/', $trimmedCode, $matches)) {
            if ($this->debug) {
                error_log("DEBUG: Using case 5: Variable simple, varName=" . $matches[1]);
            }
            $varName = $matches[1];
            $finalCode .= $this->generateVariableExportCode();
            $finalCode .= 'return $' . $varName . ';';
            return $finalCode;
        }
        
        // Cas 6: Expression simple (avec ou sans point-virgule)
        if (!preg_match('/[{}]/', $trimmedCode)) {
            if ($this->debug) {
                error_log("DEBUG: Using case 6: Expression simple");
            }
            // Retirer le point-virgule final s'il existe pour l'encapsuler
            $cleanCode = preg_replace('/;\s*$/', '', $trimmedCode);
            
            // Vérifier si c'est une expression qui peut retourner une valeur
            // (pas juste une instruction comme echo, print, etc.)
            if (!preg_match('/^\s*(echo|print|var_dump|print_r|printf|exit|die)\s+/i', $cleanCode)) {
                $finalCode .= '$__psysh_monitor_result = (' . $cleanCode . ');' . PHP_EOL;
                $finalCode .= $this->generateVariableExportCode();
                $finalCode .= 'return $__psysh_monitor_result;';
                return $finalCode;
            }
        }
        
        
        // Cas par défaut
        $finalCode .= $code;
        if (!preg_match('/;\s*$/', $code)) {
            $finalCode .= ';';
        }
        $finalCode .= PHP_EOL;
        $finalCode .= $this->generateVariableExportCode();
        $finalCode .= 'return null;';
        
        return $finalCode;
    }
    
    /**
     * Construit le contexte des variables depuis le shell
     */
    private function buildContextVariables(): string
    {
        $contextVars = '';
        
        if (!$this->shell) {
            return $contextVars;
        }
        
        $scopeVars = $this->shell->getScopeVariables();
        
        // Créer un tableau pour stocker les objets
        $contextVars .= '$__psysh_objects = [];' . PHP_EOL;
        
        foreach ($scopeVars as $varName => $varValue) {
            // Éviter les variables internes PsySH
            if ($this->shouldSkipVariable($varName)) {
                continue;
            }
            
            $varCode = $this->generateVariableCode($varName, $varValue);
            if ($varCode !== null) {
                $contextVars .= $varCode . PHP_EOL;
            }
        }
        
        return $contextVars;
    }
    
    /**
     * Détermine si une variable doit être ignorée
     */
    private function shouldSkipVariable(string $varName): bool
    {
        $skipVars = ['_', '__out', '__psysh__', '__psysh_out__', '__file', '__line', '__dir', 'this'];
        return in_array($varName, $skipVars);
    }
    
    /**
     * Génère le code pour une variable
     */
    private function generateVariableCode(string $varName, $varValue): ?string
    {
        if (is_scalar($varValue) || is_array($varValue) || is_null($varValue)) {
            return '$' . $varName . ' = ' . var_export($varValue, true) . ';';
        }
        
        if (is_object($varValue)) {
            return $this->generateObjectCode($varName, $varValue);
        }
        
        return null;
    }
    
    /**
     * Génère le code pour un objet
     */
    private function generateObjectCode(string $varName, object $varValue): ?string
    {
        // Les closures ne peuvent pas être sérialisées
        if ($varValue instanceof \Closure) {
            return null;
        }
        
        // Pour les objets complexes comme les entités Doctrine, on va les passer par référence
        // via un tableau global temporaire
        $objectId = spl_object_id($varValue);
        
        // Stocker l'objet dans le tableau global du shell
        if ($this->shell) {
            $scopeVars = $this->shell->getScopeVariables();
            if (!isset($scopeVars['__psysh_monitor_objects'])) {
                $scopeVars['__psysh_monitor_objects'] = [];
            }
            $scopeVars['__psysh_monitor_objects'][$objectId] = $varValue;
            $this->shell->setScopeVariables($scopeVars);
            
            // Générer le code pour récupérer l'objet
            return '$' . $varName . ' = $this->getShell()->getScopeVariables()["__psysh_monitor_objects"][' . $objectId . '] ?? null;';
        }
        
        // Fallback: essayer de sérialiser
        try {
            $serialized = serialize($varValue);
            return '$' . $varName . ' = unserialize(' . var_export($serialized, true) . ');';
        } catch (\Exception $e) {
            // Pour les objets non sérialisables, on ne peut pas les transférer
            return '// Objet ' . $varName . ' non transférable (classe: ' . get_class($varValue) . ')';
        }
    }
    
    /**
     * Construit le code final avec gestion du return
     */
    private function buildFinalCode(string $code, string $contextVars): string
    {
        $finalCode = '$__psysh_initial_vars = get_defined_vars();' . PHP_EOL;
        $finalCode .= $contextVars;
        
        $trimmedCode = trim($code);
        
        // Cas 1: Return explicite
        if (preg_match('/^\s*return\s+/i', $trimmedCode)) {
            $finalCode .= $code . ';';
            return $finalCode;
        }
        
        // Cas 2: Code multi-lignes
        if (strpos($code, "\n") !== false) {
            return $this->handleMultiLineCode($finalCode, $code);
        }
        
        // Cas 3: Assignation simple
        if (preg_match('/^\s*\$([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)\s*=\s*(.+?);?\s*$/s', $trimmedCode, $matches)) {
            $varName = $matches[1];
            $finalCode .= $code;
            if (!preg_match('/;\s*$/', $code)) {
                $finalCode .= ';';
            }
            $finalCode .= PHP_EOL . 'return $' . $varName . ';';
            return $finalCode;
        }
        
        // Cas 4: Variable simple
        if (preg_match('/^\s*\$([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)\s*;?\s*$/', $trimmedCode, $matches)) {
            $varName = $matches[1];
            $finalCode .= 'return $' . $varName . ';';
            return $finalCode;
        }
        
        // Cas 5: Expression simple
        if (!preg_match('/[;{}]/', $trimmedCode)) {
            $finalCode .= 'return (' . $code . ');';
            return $finalCode;
        }
        
        // Cas par défaut
        // Cas spécial pour les instructions d'affichage: capturer la sortie
        if (preg_match('/^\s*(echo|print)\s+/i', $trimmedCode)) {
            if ($this->debug) {
                error_log("DEBUG: Using output capture for echo/print instruction");
            }
            $finalCode .= 'ob_start();' . PHP_EOL;
            $finalCode .= $code;
            if (!preg_match('/;\s*$/', $code)) {
                $finalCode .= ';';
            }
            $finalCode .= PHP_EOL . '$__psysh_monitor_result = ob_get_clean();' . PHP_EOL;
            $finalCode .= $this->generateVariableExportCode();
            $finalCode .= 'return $__psysh_monitor_result;';
            return $finalCode;
        }
        
        $finalCode .= $code;
        if (!preg_match('/;\s*$/', $code)) {
            $finalCode .= ';';
        }
        $finalCode .= PHP_EOL . 'return null;';
        
        return $finalCode;
    }
    
    /**
     * Gère le code multi-lignes
     */
    private function handleMultiLineCode(string $finalCode, string $code): string
    {
        $lines = explode("\n", $code);
        $lastNonEmptyLine = '';
        $lastLineIndex = -1;
        
        // Trouver la dernière ligne non vide
        for ($i = count($lines) - 1; $i >= 0; $i--) {
            $line = trim($lines[$i]);
            if (!empty($line) && $line !== '}') {
                $lastNonEmptyLine = $line;
                $lastLineIndex = $i;
                break;
            }
        }
        
        // Si la dernière ligne est un appel de fonction
        if (preg_match('/^\$[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*\s*\([^)]*\)\s*;?$/', $lastNonEmptyLine)) {
            $codeBeforeLastLine = implode("\n", array_slice($lines, 0, $lastLineIndex));
            $lastLineWithoutSemi = rtrim($lastNonEmptyLine, ';');
            
            if (!empty(trim($codeBeforeLastLine))) {
                $finalCode .= $codeBeforeLastLine;
                if (!preg_match('/;\s*$/', trim($codeBeforeLastLine))) {
                    $finalCode .= ';';
                }
                $finalCode .= PHP_EOL;
            }
            
            $finalCode .= 'return ' . $lastLineWithoutSemi . ';';
            return $finalCode;
        }
        
        // Code multi-lignes standard
        $finalCode .= $code;
        if (!preg_match('/;\s*$/', $code)) {
            $finalCode .= ';';
        }
        $finalCode .= PHP_EOL . 'return null;';
        
        return $finalCode;
    }
    
    /**
     * Gère le code multi-lignes de manière simplifiée
     */
    private function handleMultiLineCodeSimple(string $finalCode, string $code): string
    {
        // Transformer les sleep pour qu'ils soient résistants aux interruptions
        $code = $this->makeSleepInterruptSafe($code);
        
        $lines = explode("\n", $code);
        $lastNonEmptyLine = '';
        $lastLineIndex = -1;
        
        // Trouver la dernière ligne non vide
        for ($i = count($lines) - 1; $i >= 0; $i--) {
            $line = trim($lines[$i]);
            if (!empty($line) && $line !== '}') {
                $lastNonEmptyLine = $line;
                $lastLineIndex = $i;
                break;
            }
        }
        
        // Si la dernière ligne est un appel de fonction
        if (preg_match('/^\$[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*\s*\([^)]*\)\s*;?$/', $lastNonEmptyLine)) {
            $codeBeforeLastLine = implode("\n", array_slice($lines, 0, $lastLineIndex));
            $lastLineWithoutSemi = rtrim($lastNonEmptyLine, ';');
            
            if (!empty(trim($codeBeforeLastLine))) {
                $finalCode .= $codeBeforeLastLine;
                if (!preg_match('/;\s*$/', trim($codeBeforeLastLine))) {
                    $finalCode .= ';';
                }
                $finalCode .= PHP_EOL;
            }
            
            $finalCode .= '$__psysh_monitor_result = ' . $lastLineWithoutSemi . ';' . PHP_EOL;
            $finalCode .= $this->generateVariableExportCode();
            $finalCode .= 'return $__psysh_monitor_result;';
            return $finalCode;
        }
        
        // Code multi-lignes standard
        $finalCode .= $code;
        if (!preg_match('/;\s*$/', $code)) {
            $finalCode .= ';';
        }
        $finalCode .= PHP_EOL;
        $finalCode .= $this->generateVariableExportCode();
        $finalCode .= 'return null;';
        
        return $finalCode;
    }
    
    /**
     * Parse le code en lignes pour l'affichage
     */
    public function parseCodeLines(string $code): array
    {
        // Pour l'instant, on retourne simplement les lignes
        return explode("\n", $code);
    }
    
    /**
     * Retourne le nombre de lignes de contexte ajoutées avant le code utilisateur
     */
    public function getContextLinesCount(): int
    {
        // Compter les lignes de la fonction helper
        $helperLines = substr_count($this->getSleepHelperFunction(), PHP_EOL);
        
        // Générer le code de contexte pour compter les lignes
        $contextCode = 'if (isset($GLOBALS["__psysh_monitor_scope"])) {' . PHP_EOL;
        $contextCode .= '    foreach ($GLOBALS["__psysh_monitor_scope"] as $__var_name => $__var_value) {' . PHP_EOL;
        $contextCode .= '        if (!in_array($__var_name, ["_", "__out", "__psysh__", "__psysh_out__", "__file", "__line", "__dir", "this", "__psysh_monitor_scope"])) {' . PHP_EOL;
        $contextCode .= '            $$__var_name = $__var_value;' . PHP_EOL;
        $contextCode .= '        }' . PHP_EOL;
        $contextCode .= '    }' . PHP_EOL;
        $contextCode .= '}' . PHP_EOL;
        
        // Ajouter la ligne de $__psysh_monitor_initial_vars
        $initialVarsLine = 1;
        
        $total = $helperLines + substr_count($contextCode, PHP_EOL) + $initialVarsLine;
        
        return $total;
    }
    
    /**
     * Transforme les sleep() pour qu'ils soient résistants aux interruptions PCNTL
     */
    private function makeSleepInterruptSafe(string $code): string
    {
        // Remplacer sleep() par notre fonction qui gère les interruptions
        $code = preg_replace_callback(
            '/\bsleep\s*\(\s*(\d+)\s*\)\s*;?/',
            function($matches) {
                $seconds = $matches[1];
                return "__psysh_monitor_sleep({$seconds});";
            },
            $code
        );
        
        return $code;
    }
    
    /**
     * Génère le code pour exporter les nouvelles variables
     */
    private function generateVariableExportCode(): string
    {
        return '
// Exporter toutes les nouvelles variables vers le shell PsySH
$__psysh_monitor_new_vars = [];
foreach (get_defined_vars() as $__var_name => $__var_value) {
    // Ignorer les variables internes
    if (!in_array($__var_name, $__psysh_monitor_initial_vars) && 
        !in_array($__var_name, ["__psysh_monitor_initial_vars", "__psysh_monitor_new_vars", 
                              "__var_name", "__var_value", "__psysh_monitor_result"])) {
        $__psysh_monitor_new_vars[$__var_name] = $__var_value;
    }
}
// Stocker les nouvelles variables pour la synchronisation
$GLOBALS["__psysh_monitor_new_vars"] = $__psysh_monitor_new_vars;
';
    }
    
    /**
     * Retourne la fonction helper pour gérer les sleep interruptibles
     */
    private function getSleepHelperFunction(): string
    {
        return '
if (!function_exists("__psysh_monitor_sleep")) {
    function __psysh_monitor_sleep($seconds) {
        $end = microtime(true) + $seconds;
        while (microtime(true) < $end) {
            $remaining = $end - microtime(true);
            if ($remaining <= 0) break;
            
            $sleep_seconds = (int) $remaining;
            $sleep_nanoseconds = (int) (($remaining - $sleep_seconds) * 1e9);
            
            $result = @time_nanosleep($sleep_seconds, $sleep_nanoseconds);
            
            // Si time_nanosleep a été interrompu, on continue la boucle
            if ($result === false || (is_array($result) && ($result["seconds"] > 0 || $result["nanoseconds"] > 0))) {
                continue;
            }
        }
    }
}';
    }
    
}
