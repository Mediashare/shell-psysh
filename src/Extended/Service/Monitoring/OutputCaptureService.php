<?php

namespace Psy\Extended\Service\Monitoring;

/**
 * Service pour capturer et gérer les outputs
 * Gère la capture en temps réel des sorties du code exécuté
 */
class OutputCaptureService
{
    private array $outputBuffer = [];
    private $oldStdout = null;
    private float $startTime;
    private int $startMemory;
    private ?\Symfony\Component\Console\Output\OutputInterface $output = null;
    private ?\Mediashare\Psysh\Service\Monitoring\MonitoringMetricsService $metricsService = null;
    private array $codeLines = [];
    private int $outputCount = 0;
    private float $lastDisplayTime = 0;
    private int $lastEstimatedLine = 1;
    private bool $keepMetricsHistory = false; // Changé pour effacer les métriques
    private float $metricsRefreshInterval = 0.001; // 1ms pour maximum de fluidité
    private bool $hasActiveMetrics = false; // Pour savoir si on a une métrique active
    private bool $traceMode = false; // Mode trace pour debug
    
    /**
     * Démarre la capture de sortie
     */
    public function startCapture(float $startTime, int $startMemory): void
    {
        $this->startTime = $startTime;
        $this->startMemory = $startMemory;
        $this->outputBuffer = [];
        
        // Sauvegarder le stdout actuel
        $this->oldStdout = fopen('php://stdout', 'w');
        
        // Démarrer la capture avec un callback
        ob_start([$this, 'outputHandler'], 1);
    }
    
    /**
     * Arrête la capture de sortie
     */
    public function stopCapture(): void
    {
        ob_end_flush();
        if ($this->oldStdout) {
            fclose($this->oldStdout);
            $this->oldStdout = null;
        }
    }
    
    /**
     * Handler pour capturer la sortie en temps réel
     */
    public function outputHandler(string $buffer): string
    {
        if (!empty($buffer) && $this->output && $this->metricsService) {
            // Effacer la métrique en temps réel si elle existe
            if ($this->hasActiveMetrics) {
                // Effacer sur stdout
                $this->output->write("\r" . str_repeat(' ', 100) . "\r");
                // Effacer aussi sur stderr
                fwrite(STDERR, "\r" . str_repeat(' ', 100) . "\r");
                $this->hasActiveMetrics = false;
            }
            
            // Déterminer le numéro de ligne basé sur la sortie
            $lineInfo = "";
            if (!empty($this->codeLines)) {
                $this->outputCount++;
                // Essayer de trouver la ligne qui contient un echo/print
                $estimatedLine = $this->findOutputLine($buffer);
                if ($estimatedLine === 0) {
                    // Fallback sur l'estimation par compteur
                    $estimatedLine = min($this->outputCount, count($this->codeLines));
                }
                $lineInfo = sprintf("📍 %d | ", $estimatedLine);
            }
            
            // Afficher immédiatement avec les métriques
            $metrics = sprintf(
                "[%s⏱  %.4fs | 💾 %s]: %s",
                $lineInfo,
                $this->metricsService->getTotalTime(),
                $this->metricsService->formatBytes($this->metricsService->getTotalMemoryUsage()),
                rtrim($buffer)
            );
            $this->output->writeln($metrics);
            
            // Réinitialiser le temps du dernier affichage
            $this->lastDisplayTime = $this->metricsService->getTotalTime();
            
            // Ne pas stocker dans le buffer puisqu'on affiche immédiatement
            return '';
        }
        
        // Si pas d'output ou de service, stocker dans le buffer
        if (!empty($buffer)) {
            $this->outputBuffer[] = [
                'time' => microtime(true) - $this->startTime,
                'memory' => memory_get_usage(true) - $this->startMemory,
                'output' => $buffer
            ];
        }
        
        return $buffer;
    }
    
    /**
     * Retourne le buffer de sortie capturé
     */
    public function getOutputBuffer(): array
    {
        return $this->outputBuffer;
    }
    
    /**
     * Retourne la sortie capturée sous forme de string
     */
    public function getCapturedOutput(): string
    {
        $output = '';
        foreach ($this->outputBuffer as $entry) {
            $output .= $entry['output'];
        }
        return $output;
    }
    
    /**
     * Vide le buffer de sortie
     */
    public function clearBuffer(): void
    {
        $this->outputBuffer = [];
    }
    
    /**
     * Définit l'interface de sortie pour affichage immédiat
     */
    public function setOutput(\Symfony\Component\Console\Output\OutputInterface $output): void
    {
        $this->output = $output;
    }
    
    /**
     * Définit le service de métriques
     */
    public function setMetricsService(\Mediashare\Psysh\Service\Monitoring\MonitoringMetricsService $metricsService): void
    {
        $this->metricsService = $metricsService;
    }
    
    /**
     * Définit les lignes de code pour le tracking
     */
    public function setCodeLines(array $codeLines): void
    {
        $this->codeLines = $codeLines;
        $this->outputCount = 0;
    }
    
    /**
     * Affiche les métriques en temps réel (appelé depuis tickHandler)
     */
    public function displayRealtimeMetrics(): void
    {
        if (!$this->output || !$this->metricsService) {
            return;
        }
        
        $currentTime = $this->metricsService->getTotalTime();
        
        // Debug: afficher quand cette méthode est appelée
        static $debugCount = 0;
        if ($debugCount++ < 5) { // Limiter le debug aux 5 premiers appels
            // $this->output->writeln(sprintf("\n[DEBUG] Metrics called at %.4fs", $currentTime));
        }
        
        // Afficher seulement si assez de temps s'écoule depuis le dernier affichage
        if ($currentTime - $this->lastDisplayTime > $this->metricsRefreshInterval) {
            
            // Log temporaire pour debug
            static $logCount = 0;
            if ($logCount++ < 20) {
                file_put_contents('/tmp/metrics_debug.log', sprintf("[%.4fs] Metrics display called\n", $currentTime), FILE_APPEND);
            }
            
            // Calculer le temps écoulé en secondes entières pour rendre plus visible
            $seconds = floor($currentTime);
            $fraction = $currentTime - $seconds;
            
            // Afficher les métriques en temps réel avec animation
            $spinners = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
            $spinnerIndex = ((int)($currentTime * 10)) % count($spinners);
            
            $metrics = sprintf(
                "\r%s [⏱  %.1fs | 💾 %s | %s Exécution en cours...] ",
                str_repeat(' ', 5), // Espaces pour nettoyer le début
                $currentTime,
                $this->metricsService->formatBytes($this->metricsService->getTotalMemoryUsage()),
                $spinners[$spinnerIndex]
            );
            
            // Toujours écraser la ligne précédente pour les métriques temps réel
            if ($this->traceMode) {
                // En mode trace, afficher sur une nouvelle ligne
                $this->output->writeln($metrics);
            } else {
                // Nettoyer la ligne entière avant d'afficher
                $this->output->write("\r" . str_repeat(' ', 100) . "\r");
                
                // Afficher les métriques
                $this->output->write($metrics);
                
                // Marquer qu'on a une métrique active
                $this->hasActiveMetrics = true;
                
                // Alternative : écrire aussi sur stderr pour être sûr que ça s'affiche
                fwrite(STDERR, $metrics);
                
                // Forcer le flush pour s'assurer que ça s'affiche
                if ($this->output instanceof ConsoleOutput) {
                    $stream = $this->output->getStream();
                    if (is_resource($stream)) {
                        fflush($stream);
                    }
                } else {
                    // Fallback si ce n'est pas ConsoleOutput
                    @ob_flush();
                    @flush();
                }
                
                // Flush stderr aussi
                fflush(STDERR);
            }
            
            $this->lastDisplayTime = $currentTime;
        }
    }
    
    /**
     * Configure si on garde l'historique des métriques
     */
    public function setKeepMetricsHistory(bool $keep): void
    {
        $this->keepMetricsHistory = $keep;
    }
    
    /**
     * Configure l'intervalle de rafraîchissement des métriques (en secondes)
     */
    public function setMetricsRefreshInterval(float $interval): void
    {
        $this->metricsRefreshInterval = max(0.001, $interval); // Minimum 1ms
    }
    
    /**
     * Essaie de trouver la ligne qui a généré la sortie
     */
    private function findOutputLine(string $output): int
    {
        $output = trim($output);
        if (empty($output) || empty($this->codeLines)) {
            return 0;
        }
        
        // Recherche générique dans le code
        foreach ($this->codeLines as $lineNum => $codeLine) {
            // Chercher echo, print, printf, var_dump, etc.
            if (preg_match('/\b(echo|print|printf|var_dump|dump)\s*[\(\s]/', $codeLine)) {
                // Extraire les chaînes de la ligne de code
                preg_match_all('/["\']([^"\']*)["\']/', $codeLine, $matches);
                if (!empty($matches[1])) {
                    foreach ($matches[1] as $quoted) {
                        // Nettoyer les caractères d'échappement
                        $cleanQuoted = str_replace(['\\n', '\\t', '\\r'], ['', '', ''], $quoted);
                        $cleanOutput = str_replace(["\n", "\t", "\r"], ['', '', ''], $output);
                        
                        // Vérifier si le texte correspond
                        if (!empty($cleanQuoted) && strpos($cleanOutput, $cleanQuoted) !== false) {
                            return $lineNum + 1; // Les lignes sont indexées à partir de 1
                        }
                    }
                }
                
                // Vérification spéciale pour les expressions concaténées comme "texte" . $variable
                if (preg_match('/echo\s+["\'](.+?)["\']\s*\./', $codeLine, $matches)) {
                    $staticPart = $matches[1];
                    if (strpos($output, $staticPart) !== false) {
                        return $lineNum + 1;
                    }
                }
            }
        }
        
        return 0;
    }
    
    /**
     * Obtient la ligne actuellement en cours d'exécution (estimation)
     */
    private function getCurrentExecutingLine(): int
    {
        if (empty($this->codeLines)) {
            return 0;
        }
        
        // Utiliser le nombre de ticks ou autre métrique pour estimer
        $totalTicks = $this->metricsService->getTotalTicks();
        if ($totalTicks > 0) {
            // Estimation simple basée sur la progression
            return min($totalTicks, count($this->codeLines));
        }
        
        return 1;
    }
}
