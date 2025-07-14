<?php

namespace Psy\Extended\Service;

use Symfony\Component\Console\Output\OutputInterface;

class MonitoringDisplayService
{
    /**
     * Display monitoring results
     */
    public function displayResults(OutputInterface $output, array $metrics): void
    {
        if (!empty($metrics['time'])) {
            $output->writeln(sprintf('<comment>⏱️  Temps:</comment> %.2f ms', $metrics['time']));
        }
        
        if (!empty($metrics['memory'])) {
            $output->writeln(sprintf('<comment>💾 Mémoire:</comment> %s', $this->formatBytes($metrics['memory'])));
        }
        
        if (!empty($metrics['variables'])) {
            $output->writeln('<comment>📝 Variables modifiées:</comment>');
            foreach ($metrics['variables'] as $name => $value) {
                $output->writeln(sprintf('   $%s = %s', $name, var_export($value, true)));
            }
        }
    }
    
    /**
     * Format bytes to human readable
     */
    private function formatBytes($bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);
        return round($bytes, 2) . ' ' . $units[$pow];
    }
}
