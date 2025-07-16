<?php

namespace Psy\Extended\Command\Assert;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
abstract class BaseAssertCommand extends \Psy\Extended\Command\BaseCommand
{

    protected string $assertType;
    protected string $assertMethod;

    /**
     * Exécute l'assertion et affiche le résultat
     */
    protected function executeAssertion(InputInterface $input, OutputInterface $output, $expected = null, $actual = null, string $message = ''): int
    {
        try {
            $result = $this->performAssertion($expected, $actual, $message);
            
            if ($result['success']) {
                $output->writeln($this->formatSuccess("✅ Assertion réussie" . ($message ? ": $message" : '')));
                
                if (isset($result['details'])) {
                    $output->writeln($this->formatInfo("Details: " . $result['details']));
                }
            } else {
                $output->writeln($this->formatError("❌ Assertion échouée" . ($message ? ": $message" : '')));
                
                if (isset($result['expected'])) {
                    $output->writeln($this->formatError("Expected: " . $this->formatValue($result['expected'])));
                }
                
                if (isset($result['actual'])) {
                    $output->writeln($this->formatError("Actual: " . $this->formatValue($result['actual'])));
                }
                
                if (isset($result['error'])) {
                    $output->writeln($this->formatError("Error: " . $result['error']));
                }
            }
            
            // Ajouter l'assertion au test actuel si disponible
            $this->addAssertionToCurrentTest($expected, $actual, $message, $result['success']);
            
            return $result['success'] ? 0 : 1;
            
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur lors de l'assertion: " . $e->getMessage()));
            return 1;
        }
    }

    /**
     * Méthode abstraite pour effectuer l'assertion spécifique
     */
    abstract protected function performAssertion($expected = null, $actual = null, string $message = ''): array;

    /**
     * Formate une valeur pour l'affichage
     */
    protected function formatValue($value): string
    {
        if (is_null($value)) {
            return 'null';
        } elseif (is_bool($value)) {
            return $value ? 'true' : 'false';
        } elseif (is_string($value)) {
            return "'" . addslashes($value) . "'";
        } elseif (is_array($value)) {
            return 'Array(' . count($value) . ')';
        } elseif (is_object($value)) {
            return get_class($value) . ' Object';
        } else {
            return (string) $value;
        }
    }

    /**
     * Ajoute l'assertion au test actuel
     */
    protected function addAssertionToCurrentTest($expected, $actual, string $message, bool $success): void
    {
        $service = $this->phpunit();
        $currentTest = $service->getCurrentTest()?->getTestClassName();
        if (!$currentTest) {
            return;
        }

        $assertionCode = $this->generateAssertionCode($expected, $actual, $message);
        
        $service->addCodeToTest($currentTest, $assertionCode);
    }

    /**
     * Génère le code PHP pour l'assertion
     */
    protected function generateAssertionCode($expected, $actual, string $message): string
    {
        $code = '$this->' . $this->assertMethod . '(';
        
        $params = [];
        
        if ($expected !== null) {
            $params[] = var_export($expected, true);
        }
        
        if ($actual !== null) {
            $params[] = var_export($actual, true);
        }
        
        if (!empty($message)) {
            $params[] = var_export($message, true);
        }
        
        $code .= implode(', ', $params) . ');';
        
        return $code;
    }

    /**
     * Aide complexe par défaut pour les assertions
     */
    public function getComplexHelp(): string
    {
        return $this->formatComplexHelp([
            'name' => $this->getName(),
            'description' => "Assertion {$this->assertType} pour vérifier des conditions dans les tests PHPUnit",
            'usage' => [
                $this->getName() . ' <valeur>',
                $this->getName() . ' <attendu> <obtenu>',
                $this->getName() . ' <attendu> <obtenu> "<message>"'
            ],
            'examples' => [
                $this->getName() . ' true $result' => 'Vérifie que $result est true',
                $this->getName() . ' "expected" $actual "Custom message"' => 'Compare avec un message personnalisé'
            ],
            'tips' => [
                'L\'assertion est automatiquement ajoutée au test actuel',
                'Utilisez des messages descriptifs pour identifier les échecs',
                'Les types sont automatiquement détectés et comparés'
            ],
            'related' => [
                'phpunit:create' => 'Créer un nouveau test',
                'phpunit:run' => 'Exécuter le test avec les assertions',
                'phpunit:list' => 'Voir tous les tests avec assertions'
            ]
        ]);
    }
}
