<?php

namespace Psy\Extended\Service\Monitoring;

/**
 * Service pour gérer les timers en temps réel avec PCNTL
 * Fournit une abstraction pour l'affichage périodique des métriques
 */
class PcntlTimerService
{
    private bool $isAvailable = false;
    private bool $isActive = false;
    private ?OutputCaptureService $outputCaptureService = null;
    private float $intervalSeconds = 0.01; // 10ms par défaut pour maximum de fluidité
    private float $lastSignalTime = 0;
    private $previousAlarmHandler = null;
    
    public function __construct()
    {
        $this->checkAvailability();
    }
    
    /**
     * Vérifie si PCNTL est disponible et fonctionnel
     */
    private function checkAvailability(): void
    {
        $this->isAvailable = extension_loaded('pcntl') && 
                            function_exists('pcntl_signal') && 
                            function_exists('pcntl_alarm') &&
                            function_exists('pcntl_signal_dispatch');
        
        // Activer les signaux asynchrones si disponible (PHP 7.1+)
        if ($this->isAvailable && function_exists('pcntl_async_signals')) {
            pcntl_async_signals(true);
        }
    }
    
    /**
     * Retourne si PCNTL est disponible
     */
    public function isAvailable(): bool
    {
        return $this->isAvailable;
    }
    
    /**
     * Configure le service de capture pour l'affichage
     */
    public function setOutputCaptureService(OutputCaptureService $outputCaptureService): void
    {
        $this->outputCaptureService = $outputCaptureService;
    }
    
    /**
     * Configure l'intervalle du timer (en secondes, accepte les décimales)
     */
    public function setInterval(float $seconds): void
    {
        $this->intervalSeconds = max(0.01, $seconds); // Minimum 10ms
    }
    
    /**
     * Démarre le timer pour l'affichage périodique
     */
    public function start(): bool
    {
        if (!$this->isAvailable || $this->isActive || !$this->outputCaptureService) {
            return false;
        }
        
        // Sauvegarder le contexte pour le gestionnaire de signal
        $GLOBALS['__psysh_monitor_pcntl'] = [
            'service' => $this,
            'outputService' => $this->outputCaptureService
        ];
        
        // Sauvegarder le gestionnaire précédent
        $this->previousAlarmHandler = pcntl_signal_get_handler(SIGALRM);
        
        // Installer le gestionnaire de signal
        $handler = function($signal) {
            $this->handleSignal($signal);
        };
        
        pcntl_signal(SIGALRM, $handler);
        
        // Utiliser setitimer si disponible pour plus de précision
        if (function_exists('pcntl_setitimer') && defined('ITIMER_REAL')) {
            $seconds = (int)floor($this->intervalSeconds);
            $microseconds = (int)(($this->intervalSeconds - $seconds) * 1000000);
            // setitimer(which, sec, usec, interval_sec, interval_usec)
            pcntl_setitimer(ITIMER_REAL, $seconds, $microseconds, $seconds, $microseconds);
        } else {
            // Fallback sur pcntl_alarm (précision en secondes entières seulement)
            pcntl_alarm(max(1, (int)ceil($this->intervalSeconds)));
        }
        
        $this->isActive = true;
        $this->lastSignalTime = microtime(true);
        
        // Log temporaire
        file_put_contents('/tmp/pcntl_debug.log', sprintf("[%.4fs] PCNTL Timer started with interval %.2fs\n", microtime(true), $this->intervalSeconds), FILE_APPEND);
        
        return true;
    }
    
    /**
     * Arrête le timer
     */
    public function stop(): void
    {
        if (!$this->isAvailable || !$this->isActive) {
            return;
        }
        
        // Arrêter l'alarme
        pcntl_alarm(0);
        $this->isActive = false;
        
        // Restaurer le gestionnaire précédent
        if ($this->previousAlarmHandler !== null) {
            pcntl_signal(SIGALRM, $this->previousAlarmHandler);
        } else {
            pcntl_signal(SIGALRM, SIG_DFL);
        }
        
        // Nettoyer le contexte global
        if (isset($GLOBALS['__psysh_monitor_pcntl'])) {
            unset($GLOBALS['__psysh_monitor_pcntl']);
        }
    }
    
    /**
     * Gestionnaire de signal
     */
    private function handleSignal(int $signal): void
    {
        if ($signal !== SIGALRM || !$this->isActive) {
            return;
        }
        
        // Éviter les appels trop rapprochés (minimum 5ms)
        $currentTime = microtime(true);
        if ($currentTime - $this->lastSignalTime < 0.005) {
            return;
        }
        $this->lastSignalTime = $currentTime;
        
        // Log temporaire
        static $signalCount = 0;
        if ($signalCount++ < 10) {
            file_put_contents('/tmp/pcntl_debug.log', sprintf("[%.4fs] SIGALRM signal received (#%d)\n", $currentTime, $signalCount), FILE_APPEND);
        }
        
        // Afficher les métriques via le service de capture
        if ($this->outputCaptureService) {
            $this->outputCaptureService->displayRealtimeMetrics();
        }
        
        // Réarmer l'alarme (pas nécessaire avec setitimer car il se répète automatiquement)
        if ($this->isActive && !function_exists('pcntl_setitimer')) {
            pcntl_alarm(max(1, (int)ceil($this->intervalSeconds)));
        }
    }
    
    /**
     * Traite les signaux en attente (pour les systèmes sans async signals)
     */
    public function dispatchSignals(): void
    {
        if ($this->isAvailable && !function_exists('pcntl_async_signals')) {
            pcntl_signal_dispatch();
        }
    }
    
    /**
     * Retourne le statut du timer
     */
    public function isActive(): bool
    {
        return $this->isActive;
    }
    
    /**
     * Méthode statique pour obtenir des infos sur PCNTL
     */
    public static function getPcntlInfo(): array
    {
        $info = [
            'available' => extension_loaded('pcntl'),
            'functions' => [],
            'async_signals' => false,
            'setitimer' => false
        ];
        
        if ($info['available']) {
            $requiredFunctions = [
                'pcntl_signal',
                'pcntl_alarm', 
                'pcntl_signal_dispatch',
                'pcntl_signal_get_handler',
                'pcntl_sigprocmask'
            ];
            
            foreach ($requiredFunctions as $func) {
                $info['functions'][$func] = function_exists($func);
            }
            
            $info['async_signals'] = function_exists('pcntl_async_signals');
            $info['setitimer'] = function_exists('pcntl_setitimer');
        }
        
        return $info;
    }
}
