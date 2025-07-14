<?php

namespace Psy\Extended\Trait;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Psy\Command\Command;

/**
 * Trait pour standardiser l'exécution des commandes avec gestion d'erreurs
 */
trait CommandExecutionTrait
{
    /**
     * Exécute une commande avec gestion d'erreurs standardisée
     */
    protected function executeWithErrorHandling(InputInterface $input, OutputInterface $output, callable $handler): int
    {
        try {
            $result = $handler($input, $output);
            return is_int($result) ? $result : Command::SUCCESS;
        } catch (\InvalidArgumentException $e) {
            $output->writeln($this->formatError("Argument invalide: " . $e->getMessage()));
            $this->displayUsageHint($output);
            return Command::INVALID;
        } catch (\RuntimeException $e) {
            $output->writeln($this->formatError("Erreur d'exécution: " . $e->getMessage()));
            if ($this->isDebugMode()) {
                $output->writeln($this->formatDebug("Stack trace: " . $e->getTraceAsString()));
            }
            return Command::FAILURE;
        } catch (\Exception $e) {
            $output->writeln($this->formatError("Erreur inattendue: " . $e->getMessage()));
            if ($this->isDebugMode()) {
                $output->writeln($this->formatDebug("Stack trace: " . $e->getTraceAsString()));
            }
            return Command::FAILURE;
        }
    }

    /**
     * Valide les arguments requis d'une commande
     */
    protected function validateRequiredArguments(InputInterface $input, array $requiredArgs): bool
    {
        foreach ($requiredArgs as $arg) {
            if (empty($input->getArgument($arg))) {
                return false;
            }
        }
        return true;
    }

    /**
     * Affiche un hint d'usage si la commande échoue
     */
    protected function displayUsageHint(OutputInterface $output): void
    {
        $commandName = $this->getName();
        $output->writeln($this->formatInfo("💡 Aide: help {$commandName} ou {$commandName}:help"));
    }

    /**
     * Exécute une opération avec confirmation utilisateur
     */
    protected function executeWithConfirmation(
        OutputInterface $output, 
        string $message, 
        callable $operation,
        bool $defaultYes = false
    ): int {
        $helper = $this->getHelper('question');
        $question = new \Symfony\Component\Console\Question\ConfirmationQuestion(
            $message . ($defaultYes ? ' [Y/n] ' : ' [y/N] '), 
            $defaultYes
        );

        if ($helper->ask($input ?? new \Symfony\Component\Console\Input\ArrayInput([]), $output, $question)) {
            return $operation();
        }

        $output->writeln($this->formatInfo("Opération annulée"));
        return Command::SUCCESS;
    }

    /**
     * Affiche un indicateur de progression pour les opérations longues
     */
    protected function executeWithProgress(
        OutputInterface $output, 
        array $items, 
        callable $processor,
        string $label = "Traitement"
    ): array {
        $progressBar = new \Symfony\Component\Console\Helper\ProgressBar($output, count($items));
        $progressBar->setFormat(" {$label}: %current%/%max% [%bar%] %percent:3s%% %elapsed:6s%/%estimated:-6s% %memory:6s%");
        $progressBar->start();

        $results = [];
        foreach ($items as $index => $item) {
            $results[$index] = $processor($item, $index);
            $progressBar->advance();
        }

        $progressBar->finish();
        $output->writeln(""); // Nouvelle ligne après la barre de progression
        return $results;
    }

    /**
     * Collecte plusieurs valeurs via des prompts
     */
    protected function collectInputs(InputInterface $input, OutputInterface $output, array $prompts): array
    {
        $helper = $this->getHelper('question');
        $values = [];

        foreach ($prompts as $key => $config) {
            // Vérifier si la valeur est déjà fournie en argument/option
            if (isset($config['argument']) && $input->hasArgument($config['argument'])) {
                $value = $input->getArgument($config['argument']);
                if (!empty($value)) {
                    $values[$key] = $value;
                    continue;
                }
            }

            if (isset($config['option']) && $input->hasOption($config['option'])) {
                $value = $input->getOption($config['option']);
                if (!empty($value)) {
                    $values[$key] = $value;
                    continue;
                }
            }

            // Créer la question appropriée
            $question = $this->createQuestion($config);
            $values[$key] = $helper->ask($input, $output, $question);
        }

        return $values;
    }

    /**
     * Crée une question Symfony Console selon la configuration
     */
    private function createQuestion(array $config): \Symfony\Component\Console\Question\Question
    {
        $message = $config['message'] ?? 'Valeur';
        $default = $config['default'] ?? null;

        if (isset($config['choices'])) {
            return new \Symfony\Component\Console\Question\ChoiceQuestion($message, $config['choices'], $default);
        }

        if (isset($config['hidden']) && $config['hidden']) {
            $question = new \Symfony\Component\Console\Question\Question($message, $default);
            $question->setHidden(true);
            return $question;
        }

        if (isset($config['confirm']) && $config['confirm']) {
            return new \Symfony\Component\Console\Question\ConfirmationQuestion($message, $default ?? false);
        }

        $question = new \Symfony\Component\Console\Question\Question($message, $default);

        if (isset($config['validator'])) {
            $question->setValidator($config['validator']);
        }

        return $question;
    }

    /**
     * Affiche un résumé d'exécution
     */
    protected function displayExecutionSummary(
        OutputInterface $output, 
        array $results, 
        float $startTime,
        string $operation = "Opération"
    ): void {
        $endTime = microtime(true);
        $duration = round($endTime - $startTime, 3);
        
        $successCount = count(array_filter($results, fn($r) => $r === true || (is_array($r) && ($r['success'] ?? false))));
        $totalCount = count($results);
        $errorCount = $totalCount - $successCount;

        $output->writeln("\n" . str_repeat("═", 60));
        $output->writeln($this->formatInfo("📊 RÉSUMÉ DE L'EXÉCUTION - {$operation}"));
        $output->writeln(str_repeat("═", 60));
        $output->writeln("⏱️  Durée: {$duration}s");
        $output->writeln("✅ Succès: {$successCount}/{$totalCount}");
        
        if ($errorCount > 0) {
            $output->writeln("❌ Erreurs: {$errorCount}");
        }
        
        $output->writeln(str_repeat("═", 60));
    }
}
