<?php

namespace Psy\Extended\Trait;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Psy\Input\ShellInput;

/**
 * Trait pour capturer les expressions brutes sans guillemets
 */
trait RawExpressionTrait
{
    /**
     * Capture l'expression brute à partir de l'input
     */
    protected function captureRawExpression(InputInterface $input, string $commandName): string
    {
        // Méthode 1: Utiliser ShellInput si disponible
        if ($input instanceof ShellInput) {
            return $this->extractFromShellInput($input, $commandName);
        }
        
        // Méthode 2: Utiliser __toString() pour récupérer l'input brut
        $rawInput = $input->__toString();
        if ($rawInput) {
            return $this->extractFromRawInput($rawInput, $commandName);
        }
        
        // Méthode 3: Fallback sur les arguments classiques
        return $this->extractFromArguments($input);
    }
    
    /**
     * Extrait l'expression depuis ShellInput
     */
    private function extractFromShellInput(ShellInput $input, string $commandName): string
    {
        try {
            // Récupérer les tokens via réflexion
            $reflection = new \ReflectionClass($input);
            
            if ($reflection->hasProperty('tokens')) {
                $tokensProperty = $reflection->getProperty('tokens');
                $tokensProperty->setAccessible(true);
                $tokens = $tokensProperty->getValue($input);
                
                // Supprimer le premier token (nom de la commande)
                if (!empty($tokens) && $tokens[0] === $commandName) {
                    array_shift($tokens);
                }
                
                return implode(' ', $tokens);
            }
        } catch (\Exception $e) {
            // Ignorer les erreurs et passer à la méthode suivante
        }
        
        return '';
    }
    
    /**
     * Extrait l'expression depuis l'input brut
     */
    private function extractFromRawInput(string $rawInput, string $commandName): string
    {
        // Pattern pour extraire tout après le nom de la commande
        $pattern = '/^' . preg_quote($commandName, '/') . '\s+(.*)$/';
        
        if (preg_match($pattern, trim($rawInput), $matches)) {
            return trim($matches[1]);
        }
        
        return '';
    }
    
    /**
     * Extrait l'expression depuis les arguments (fallback)
     */
    private function extractFromArguments(InputInterface $input): string
    {
        $args = $input->getArguments();
        
        // Chercher un argument qui pourrait contenir l'expression
        foreach (['expression', 'assertion', 'code', 'text'] as $argName) {
            if (isset($args[$argName])) {
                $value = $args[$argName];
                if (is_array($value)) {
                    return implode(' ', $value);
                }
                return (string) $value;
            }
        }
        
        return '';
    }
    
    /**
     * Surcharge la méthode run pour capturer l'input brut
     */
    public function run(InputInterface $input, OutputInterface $output): int
    {
        // Capturer l'expression brute
        $rawExpression = $this->captureRawExpression($input, $this->getName());
        
        // Stocker l'expression pour l'utiliser dans execute()
        $this->setRawExpression($rawExpression);
        
        // Appeler la méthode parent
        return parent::run($input, $output);
    }
    
    /**
     * Stocke l'expression brute
     */
    protected function setRawExpression(string $expression): void
    {
        $this->rawExpression = $expression;
    }
    
    /**
     * Récupère l'expression brute
     */
    protected function getRawExpression(): string
    {
        return $this->rawExpression ?? '';
    }
    
    /**
     * Propriété pour stocker l'expression brute
     */
    protected ?string $rawExpression = null;
}
