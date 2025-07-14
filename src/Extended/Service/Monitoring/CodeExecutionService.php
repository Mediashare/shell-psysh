<?php

namespace Psy\Extended\Service\Monitoring;

use Psy\Shell;
use Symfony\Component\Console\Output\OutputInterface;

/**
 * Service principal pour l'exécution de code avec monitoring
 * Orchestre les différents services de monitoring
 */
class CodeExecutionService
{
    private MonitoringMetricsService $metricsService;
    private OutputCaptureService $outputCaptureService;
    private CodePreparationService $codePreparationService;
    private VariableSyncService $variableSyncService;
    private MonitoringDisplayService $displayService;
    private DebugTrackingService $debugTrackingService;
    private ?Shell $shell = null;
    private bool $stopMonitoring = false;
    private array $codeLines = [];
    private int $currentLine = 0;
    private bool $debug = false;
    private ?OutputInterface $output = null;
    private int $outputCount = 0;
    private int $contextLinesCount = 0;
    private ?PcntlTimerService $pcntlTimerService = null;
    private $psyShell = null; // Le shell PsySH pour la synchronisation
    
    public function __construct(
        MonitoringMetricsService $metricsService,
        OutputCaptureService $outputCaptureService,
        CodePreparationService $codePreparationService,
        VariableSyncService $variableSyncService,
        MonitoringDisplayService $displayService
    ) {
        $this->metricsService = $metricsService;
        $this->outputCaptureService = $outputCaptureService;
        $this->codePreparationService = $codePreparationService;
        $this->variableSyncService = $variableSyncService;
        $this->displayService = $displayService;
        $this->debugTrackingService = new DebugTrackingService();
        
        // Initialiser le service PCNTL
        $this->pcntlTimerService = new PcntlTimerService();
        $this->pcntlTimerService->setOutputCaptureService($outputCaptureService);
    }
    
    /**
     * Configure le shell pour tous les services
     */
    public function setShell(Shell $shell): void
    {
        $this->codePreparationService->setShell($shell);
        $this->variableSyncService->setShell($shell);
    }
    
    /**
     * Configure le shell PsySH pour la synchronisation des variables
     */
    public function setPsyShell($psyShell): void
    {
        $this->psyShell = $psyShell;
    }
    
    /**
     * Configure le mode debug
     */
    public function setDebug(bool $debug, OutputInterface $output): void
    {
        $this->debug = $debug;
        $this->codePreparationService->setDebug($debug);
        $this->variableSyncService->configure($debug, $output);
        $this->debugTrackingService->setDebugMode($debug);
        $this->displayService->setDebug($debug);
    }
    
    /**
     * Exécute le code avec monitoring
     */
    public function executeWithMonitoring(string $code, OutputInterface $output): array
    {
        // Afficher l'en-tête
        $this->displayService->displayHeader($output, $code);
        
        // Initialiser les métriques et les variables
        $this->metricsService->initialize();
        $this->outputCount = 0;
        $this->stopMonitoring = false;
        
        // Parser le code
        $this->codeLines = $this->codePreparationService->parseCodeLines($code);
        
        // Récupérer le nombre de lignes de contexte dynamiquement
        $this->contextLinesCount = $this->codePreparationService->getContextLinesCount();
        
        // Debug: vérifier que codeLines est bien rempli
        if ($output->isVerbose()) {
            $output->writeln(sprintf('<comment>Debug: %d lignes de code parsées, %d lignes de contexte</comment>', count($this->codeLines), $this->contextLinesCount));
        }
        
        // Configurer le debug tracking avec les lignes de code
        $this->debugTrackingService->setCodeLines($this->codeLines);
        $this->debugTrackingService->reset();
        
        // Préparer le code
        $preparedCode = $this->codePreparationService->prepareCode($code);
        
        // Afficher le code généré en debug
        if ($output->isVerbose()) {
            $output->writeln('<comment>Code généré :</comment>');
            $output->writeln('<info>' . str_replace(PHP_EOL, '\\n', $preparedCode) . '</info>');
            $output->writeln('<comment>---</comment>');
        }
        
        // Configurer le service de capture avec output et metrics
        $this->outputCaptureService->setOutput($output);
        $this->outputCaptureService->setMetricsService($this->metricsService);
        $this->outputCaptureService->setCodeLines($this->codeLines);
        
        // Réduire l'intervalle de rafraîchissement à 1ms pour maximum de fluidité
        $this->outputCaptureService->setMetricsRefreshInterval(0.001);
        
        // Capturer la sortie
        $this->outputCaptureService->startCapture(
            $this->metricsService->getTotalTime(),
            $this->metricsService->getTotalMemoryUsage()
        );
        
        // Démarrer le timer PCNTL si disponible
        $pcntlStarted = false;
        $usePcntl = true; // Réactivé avec meilleure gestion
        if ($usePcntl && $this->pcntlTimerService && $this->pcntlTimerService->isAvailable()) {
            // Configurer un intervalle d'une seconde pour PCNTL (pcntl_alarm ne supporte que les secondes)
            $this->pcntlTimerService->setInterval(1);
            $pcntlStarted = $this->pcntlTimerService->start();
            if ($pcntlStarted && $output->isVerbose()) {
                $output->writeln('<comment>PCNTL timer activé pour l\'affichage en temps réel (10ms)</comment>');
            }
        }
        
        // Créer le tick handler
        $tickHandler = function() use ($output) {
            if (!$this->stopMonitoring) {
                $this->tickHandler($output);
            }
        };
        
        // Enregistrer le tick handler
        register_tick_function($tickHandler);
        
        $result = null;
        $error = null;
        
        try {
            // Exécuter le code avec monitoring
            declare(ticks=1) {
                // Exécuter le code
                $result = eval($preparedCode);
                
                // Récupérer les nouvelles variables exportées
                if ($this->debug) {
                    error_log("DEBUG: Checking for __psysh_monitor_new_vars: " . (isset($GLOBALS['__psysh_monitor_new_vars']) ? "EXISTS" : "NOT EXISTS"));
                    if (isset($GLOBALS['__psysh_monitor_new_vars'])) {
                        error_log("DEBUG: __psysh_monitor_new_vars content: " . print_r($GLOBALS['__psysh_monitor_new_vars'], true));
                    }
                }
                
                if (isset($GLOBALS['__psysh_monitor_new_vars'])) {
                    $newVars = $GLOBALS['__psysh_monitor_new_vars'];
                    unset($GLOBALS['__psysh_monitor_new_vars']);
                    
                    // Synchroniser via ré-exécution dans le shell PsySH
                    if (!empty($newVars)) {
                        if ($this->debug) {
                            error_log("DEBUG: Attempting shell synchronization with: " . print_r($newVars, true));
                        }
                        $this->syncVariablesViaShellExecution($code, $output);
                    }
                } else {
                    if ($this->debug) {
                        error_log("DEBUG: No new variables to synchronize");
                    }
                }
            }
        } catch (\Throwable $e) {
            $error = $e;
        } finally {
            // Arrêter le monitoring
            $this->stopMonitoring = true;
            unregister_tick_function($tickHandler);
            
            // Arrêter le timer PCNTL si actif
            if ($pcntlStarted && $this->pcntlTimerService) {
                $this->pcntlTimerService->stop();
            }
            
            // Afficher les outputs résiduels avant d'arrêter la capture
            $this->displayResidualOutputs($output);
            
            // Effacer la dernière métrique "Exécution en cours..."
            $output->write("\r" . str_repeat(' ', 100) . "\r");
            fwrite(STDERR, "\r" . str_repeat(' ', 100) . "\r");
            
            // Afficher le message de fin d'exécution
            $finalMetrics = sprintf(
                "[⏱  %.1fs | 💾 %s | ✅ Fin d'exécution]",
                $this->metricsService->getTotalTime(),
                $this->metricsService->formatBytes($this->metricsService->getTotalMemoryUsage())
            );
            $output->writeln($finalMetrics);
            
            // Arrêter la capture
            $this->outputCaptureService->stopCapture();
            
            // Nettoyer la variable globale temporaire
            if (isset($GLOBALS['__psysh_monitor_scope'])) {
                unset($GLOBALS['__psysh_monitor_scope']);
            }
        }
        
        // Retourner les résultats
        return [
            'result' => $result,
            'error' => $error,
            'output' => $this->outputCaptureService->getCapturedOutput(),
            'metrics' => $this->metricsService->getSummary(),
            'debug_stats' => $this->debugTrackingService->getFullStats(),
            'debug_service' => $this->debugTrackingService,
            'context_lines_count' => $this->contextLinesCount
        ];
    }
    
    /**
     * Handler appelé à chaque tick
     */
    private function tickHandler(OutputInterface $output): void
    {
        $this->metricsService->incrementTick();
        $this->currentLine++;
        
        // Dispatcher les signaux PCNTL si nécessaire
        if ($this->pcntlTimerService && $this->pcntlTimerService->isActive()) {
            $this->pcntlTimerService->dispatchSignals();
        }
        
        // Enregistrer dans le debug tracker
        if ($this->debug) {
            // Enregistrer chaque tick pour le debug
            $this->metricsService->recordMetric();
            
            // Pour le debug tracking, utiliser une estimation de la ligne basée sur les ticks
            $estimatedLine = (($this->metricsService->getTotalTicks() - 1) % count($this->codeLines)) + 1;
            if ($estimatedLine > 0 && $estimatedLine <= count($this->codeLines)) {
                $this->debugTrackingService->recordLineExecution(
                    $estimatedLine,
                    $this->metricsService->getTotalTime(),
                    $this->metricsService->getTotalMemoryUsage()
                );
            }
        } else {
            // Enregistrer une métrique toutes les 2 ticks en mode normal pour plus de fluidité
            if ($this->metricsService->getTotalTicks() % 2 === 0) {
                $this->metricsService->recordMetric();
            }
        }
        
        // Toujours afficher les métriques via les ticks pour plus de réactivité
        $this->outputCaptureService->displayRealtimeMetrics();
    }
    
    /**
     * Synchronise les variables en ré-exécutant le code dans le shell PsySH
     * 
     * TEMPORAIREMENT DÉSACTIVÉ car cela casse l'output du shell PsySH
     * Les variables créées dans monitor ne seront pas synchronisées avec le shell
     */
    private function syncVariablesViaShellExecution(string $code, OutputInterface $output): void
    {
        if ($this->debug && $output) {
            $output->writeln('<comment>DEBUG: Synchronisation désactivée pour éviter de casser le shell</comment>');
        }
        
        // Pas de synchronisation pour l'instant
        // TODO: Trouver une méthode qui ne casse pas l'output du shell
        return;
    }
    
    /**
     * Affiche les outputs résiduels qui n'ont pas été traités par le tick handler
     */
    private function displayResidualOutputs(OutputInterface $output): void
    {
        $outputBuffer = $this->outputCaptureService->getOutputBuffer();
        if (!empty($outputBuffer)) {
            foreach ($outputBuffer as $entry) {
                if (!empty($entry['output'])) {
                    // Afficher les métriques avec l'output
                    $metrics = sprintf(
                        "[⏱  %.4fs | 💾 %s]: %s",
                        $this->metricsService->getTotalTime(),
                        $this->metricsService->formatBytes($this->metricsService->getTotalMemoryUsage()),
                        rtrim($entry['output'])
                    );
                    $output->writeln($metrics);
                }
            }
            $this->outputCaptureService->clearBuffer();
        }
    }
}
