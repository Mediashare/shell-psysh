<?php

namespace Psy\Extended\Service\Monitoring;

use Symfony\Component\Console\Helper\Table;
use Symfony\Component\Console\Output\OutputInterface;

/**
 * Service pour gérer l'affichage des résultats de monitoring
 * Gère le formatage et l'affichage des métriques
 */
class MonitoringDisplayService
{
    private MonitoringMetricsService $metricsService;
    private bool $debug = false;
    
    public function __construct(MonitoringMetricsService $metricsService)
    {
        $this->metricsService = $metricsService;
    }
    
    /**
     * Configure le mode debug
     */
    public function setDebug(bool $debug): void
    {
        $this->debug = $debug;
    }
    
    /**
     * Affiche l'en-tête du monitoring
     */
    public function displayHeader(OutputInterface $output, string $code): void
    {
        $output->writeln('<info>╔══════════════════════════════════════════════════════════════════╗</info>');
        $output->writeln('<info>║                    MONITORING EN TEMPS RÉEL                      ║</info>');
        $output->writeln('<info>╚══════════════════════════════════════════════════════════════════╝</info>');
        $output->writeln('<comment>Code:</comment>');
        
        // Afficher le code avec numéros de ligne seulement en mode debug
        if ($this->debug) {
            $lines = explode("\n", $code);
            foreach ($lines as $index => $line) {
                $lineNumber = $index + 1;
                $output->writeln(sprintf('<comment>%3d.</comment> %s', $lineNumber, $line));
            }
        } else {
            // En mode normal, afficher le code sans numéros
            $output->writeln($code);
        }
        
        $output->writeln(str_repeat('─', 70));
    }
    
    /**
     * Affiche le monitoring en temps réel
     */
    public function displayRealTimeMetrics(OutputInterface $output, float $currentTime, int $currentMemory, int $tickCount): void
    {
        $output->write(sprintf(
            "\r<info>⏱ %.4fs | 💾 %s | 🔄 %d ticks</info>",
            $currentTime,
            $this->metricsService->formatBytes($currentMemory),
            $tickCount
        ));
    }
    
    /**
     * Affiche les métriques finales
     */
    public function displayFinalMetrics(OutputInterface $output, $result, array $debugStats = []): void
    {
        $summary = $this->metricsService->getSummary();
        
        $output->writeln('');
        $output->writeln('');
        $output->writeln('<info>╭──────────────────────────────────────────────────────────────────╮</info>');
        $output->writeln('<info>│                     ✅ MONITORING TERMINÉ                        │</info>');
        $output->writeln('<info>╰──────────────────────────────────────────────────────────────────╯</info>');
        
        // Affichage du résultat
        $this->displayResult($output, $result);
        
        // Affichage du tableau des métriques
        $this->displayMetricsTable($output, $summary, $result);
        
        // Afficher les statistiques de debug si disponibles
        if (!empty($debugStats)) {
            $this->displayDebugStatistics($output, $debugStats);
        }
        
        // Alertes de performance
        $this->displayPerformanceAlerts($output, $summary);
    }
    
    /**
     * Affiche le résultat de l'exécution
     */
    private function displayResult(OutputInterface $output, $result): void
    {
        if ($result !== null) {
            $output->writeln('');
            $output->writeln('<comment>Résultat:</comment>');
            $output->writeln($this->formatResult($result));
        }
    }
    
    /**
     * Affiche le tableau des métriques
     */
    private function displayMetricsTable(OutputInterface $output, array $summary, $result): void
    {
        $table = new Table($output);
        $table->setHeaders(['📊RÉSUMÉ DES MÉTRIQUES', 'Valeur']);
        $table->setStyle('box');
        
        $table->addRows([
            ['⏱  Temps d\'exécution total', sprintf('%.4f secondes', $summary['total_time'])],
            ['💾 Mémoire', $this->metricsService->formatBytes($summary['total_memory'])],
            ['📈 Pic de mémoire', $this->metricsService->formatBytes($summary['peak_memory'])],
            ['🔄 Nombre de ticks', number_format($summary['total_ticks'])],
            ['📦 Type de résultat', $this->getResultType($result)],
            ['⚡ Ticks par seconde', number_format($summary['ticks_per_second'], 2)],
        ]);
        
        $table->render();
    }
    
    /**
     * Affiche le graphique de mémoire
     */
    private function displayMemoryGraph(OutputInterface $output): void
    {
        $metrics = $this->metricsService->getMetrics();
        
        if (empty($metrics)) {
            return;
        }
        
        $output->writeln('');
        $output->writeln('<info>📈 Évolution de la mémoire:</info>');
        
        // Trouver la valeur max pour l'échelle
        $maxMemory = max(array_column($metrics, 'memory'));
        
        // Afficher un graphique simple
        $graphHeight = 8;
        $graphWidth = min(count($metrics), 50);
        
        // Échantillonnage si trop de points
        $step = max(1, intval(count($metrics) / $graphWidth));
        
        for ($y = $graphHeight; $y >= 0; $y--) {
            $line = '';
            $threshold = ($y / $graphHeight) * $maxMemory;
            
            for ($x = 0; $x < count($metrics); $x += $step) {
                if (isset($metrics[$x]) && $metrics[$x]['memory'] >= $threshold) {
                    $line .= '█';
                } else {
                    $line .= ' ';
                }
            }
            
            if ($y === $graphHeight) {
                $output->writeln(sprintf(
                    '<comment>%-10s</comment> <info>%s</info>',
                    $this->metricsService->formatBytes((int)$maxMemory),
                    $line
                ));
            } elseif ($y === 0) {
                $output->writeln(sprintf('<comment>%-10s</comment> <info>%s</info>', '0 B', $line));
            } else {
                $output->writeln(sprintf('%-10s <info>%s</info>', '', $line));
            }
        }
        
        $output->writeln(str_repeat(' ', 11) . '<comment>' . str_repeat('─', min(count($metrics), 50)) . '</comment>');
        $output->writeln(sprintf('%-10s <comment>%s</comment>', '', 'Temps →'));
    }
    
    /**
     * Affiche les alertes de performance
     */
    private function displayPerformanceAlerts(OutputInterface $output, array $summary): void
    {
        $alerts = [];
        
        // Alerte si l'exécution est lente
        if ($summary['total_time'] > 1.0) {
            $alerts[] = '<comment>⚠️  Exécution lente détectée (> 1 seconde)</comment>';
        }
        
        // Alerte si utilisation mémoire élevée
        $memoryLimitBytes = $this->metricsService->parseBytes(ini_get('memory_limit'));
        if ($memoryLimitBytes > 0 && $summary['peak_memory'] > $memoryLimitBytes * 0.8) {
            $alerts[] = '<comment>⚠️  Utilisation mémoire élevée (> 80% de la limite)</comment>';
        }
        
        if (!empty($alerts)) {
            $output->writeln('');
            $output->writeln('<info>🚨 Alertes de performance:</info>');
            foreach ($alerts as $alert) {
                $output->writeln('  ' . $alert);
            }
        }
    }
    
    /**
     * Formate le résultat pour l'affichage
     */
    private function formatResult($result): string
    {
        // Pour les valeurs simples
        if (is_null($result)) {
            return 'null';
        }
        
        if (is_bool($result)) {
            return $result ? 'true' : 'false';
        }
        
        if (is_int($result) || is_float($result)) {
            return (string) $result;
        }
        
        if (is_string($result)) {
            // Les chaînes sont affichées entre guillemets comme PsySH
            return '"' . addslashes($result) . '"';
        }
        
        if (is_array($result)) {
            // Pour les tableaux, utiliser var_export pour un affichage complet
            return var_export($result, true);
        }
        
        if (is_object($result)) {
            // Pour les objets, afficher le nom de la classe et l'identifiant si possible
            $class = get_class($result);
            if (method_exists($result, '__toString')) {
                return $class . ' {' . (string) $result . '}';
            }
            return $class . ' {#' . spl_object_id($result) . '}';
        }
        
        // Par défaut, utiliser var_export
        return var_export($result, true);
    }
    
    /**
     * Obtient le type du résultat
     */
    private function getResultType($result): string
    {
        if (is_null($result)) {
            return 'NULL';
        }
        
        if (is_bool($result)) {
            return 'boolean';
        }
        
        if (is_int($result)) {
            return 'integer';
        }
        
        if (is_float($result)) {
            return 'float';
        }
        
        if (is_string($result)) {
            return 'string';
        }
        
        if (is_array($result)) {
            return 'array(' . count($result) . ')';
        }
        
        if (is_object($result)) {
            return get_class($result);
        }
        
        return gettype($result);
    }
    
    /**
     * Affiche les statistiques de debug
     */
    private function displayDebugStatistics(OutputInterface $output, array $debugStats): void
    {
        if (empty($debugStats)) {
            return;
        }
        
        $output->writeln('');
        $output->writeln('<info>🔧 STATISTIQUES DE DEBUG</info>');
        $output->writeln(str_repeat('─', 70));
        
        // Statistiques par ligne
        if (!empty($debugStats['line_stats'])) {
            $output->writeln('');
            $output->writeln('<comment>📋 Statistiques par ligne:</comment>');
            
            $table = new Table($output);
            $table->setHeaders(['Ligne', 'Code', 'Exécutions', 'Temps total', 'Temps moy.', 'Mém. moy.']);
            
            foreach ($debugStats['line_stats'] as $line => $stats) {
                $table->addRow([
                    $line,
                    substr($stats['code'], 0, 30) . (strlen($stats['code']) > 30 ? '...' : ''),
                    $stats['executions'],
                    $stats['total_time'] . 's',
                    $stats['avg_time'] . 's',
                    $stats['avg_memory']
                ]);
            }
            
            $table->render();
        }
        
        // Analyse des boucles
        if (!empty($debugStats['loop_analysis'])) {
            $output->writeln('');
            $output->writeln('<comment>🔁 Analyse des boucles:</comment>');
            foreach ($debugStats['loop_analysis'] as $loop) {
                $output->writeln(sprintf(
                    '  <info>Ligne %d</info>: %d itérations - <comment>%s</comment>',
                    $loop['line'],
                    $loop['iterations'],
                    $loop['code']
                ));
            }
        }
        
        // Changements de variables
        if (!empty($debugStats['variable_changes'])) {
            $output->writeln('');
            $output->writeln('<comment>🔄 Changements de variables:</comment>');
            $changes = array_slice($debugStats['variable_changes'], -5); // Derniers 5 changements
            foreach ($changes as $change) {
                $output->writeln(sprintf(
                    '  <info>$%s</info> (L%d): %s → %s',
                    $change['variable'],
                    $change['line'],
                    $change['old_value'],
                    $change['new_value']
                ));
            }
        }
    }
}
