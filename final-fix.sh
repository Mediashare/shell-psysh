#!/bin/bash

echo "🔧 Correction finale des tests PsySH Extended..."

# 1. Ajouter validateArguments dans PHPUnitCommandTrait
echo "1. Ajout de validateArguments dans PHPUnitCommandTrait..."
cat >> src/Extended/Trait/PHPUnitCommandTrait.php << 'EOF'

    /**
     * Validate required arguments
     */
    protected function validateArguments(\Symfony\Component\Console\Input\InputInterface $input, \Symfony\Component\Console\Output\OutputInterface $output): bool
    {
        if (!method_exists($this, 'getRequiredArguments')) {
            return true;
        }
        
        $requiredArgs = $this->getRequiredArguments();
        foreach ($requiredArgs as $arg) {
            if (!$input->getArgument($arg)) {
                $output->writeln($this->formatError("Argument requis manquant: {$arg}"));
                return false;
            }
        }
        return true;
    }

    /**
     * Get required arguments for the command
     */
    protected function getRequiredArguments(): array
    {
        return [];
    }
EOF

# 2. Ajouter formatList dans OutputFormatterTrait
echo "2. Ajout de formatList dans OutputFormatterTrait..."
sed -i '' '/protected function displayList/i\
    protected function formatList(array $items): string\
    {\
        $output = "";\
        foreach ($items as $item) {\
            $output .= "  • " . $item . "\\n";\
        }\
        return $output;\
    }\
' src/Extended/Trait/OutputFormatterTrait.php

# 3. Corriger le problème de Context dans Snapshot
echo "3. Correction des appels Context dans PHPUnitSnapshotCommand..."
sed -i '' 's/$context->set(/$context->setAll([/g' src/Extended/Command/Snapshot/PHPUnitSnapshotCommand.php
sed -i '' 's/->set(\(.*\), \(.*\));/->setAll(array_merge($context->getAll(), [\1 => \2]));/g' src/Extended/Command/Snapshot/PHPUnitSnapshotCommand.php

# 4. Créer un PHPUnitSnapshotService minimal si absent
echo "4. Création de PHPUnitSnapshotService..."
if [ ! -f src/Extended/Service/PHPUnitSnapshotService.php ]; then
cat > src/Extended/Service/PHPUnitSnapshotService.php << 'EOF'
<?php

namespace Psy\Extended\Service;

class PHPUnitSnapshotService
{
    private array $snapshots = [];
    
    /**
     * Create a snapshot of a value
     */
    public function createSnapshot($value, string $name = null, string $description = null): array
    {
        $name = $name ?: 'snapshot_' . count($this->snapshots);
        
        $snapshot = [
            'name' => $name,
            'value' => $value,
            'description' => $description,
            'created_at' => date('Y-m-d H:i:s'),
            'type' => gettype($value),
            'assertion' => $this->generateAssertion($value, $name)
        ];
        
        $this->snapshots[$name] = $snapshot;
        
        return $snapshot;
    }
    
    /**
     * Generate PHPUnit assertion for the value
     */
    private function generateAssertion($value, string $varName): string
    {
        if (is_null($value)) {
            return "\$this->assertNull(\${$varName});";
        }
        
        if (is_bool($value)) {
            return $value ? "\$this->assertTrue(\${$varName});" : "\$this->assertFalse(\${$varName});";
        }
        
        if (is_numeric($value)) {
            return "\$this->assertEquals({$value}, \${$varName});";
        }
        
        if (is_string($value)) {
            $escaped = var_export($value, true);
            return "\$this->assertEquals({$escaped}, \${$varName});";
        }
        
        if (is_array($value)) {
            $export = var_export($value, true);
            return "\$this->assertEquals({$export}, \${$varName});";
        }
        
        return "\$this->assertNotNull(\${$varName});";
    }
    
    /**
     * Get all snapshots
     */
    public function getSnapshots(): array
    {
        return $this->snapshots;
    }
    
    /**
     * Get a specific snapshot
     */
    public function getSnapshot(string $name): ?array
    {
        return $this->snapshots[$name] ?? null;
    }
}
EOF
fi

# 5. Ajouter la méthode getComplexHelp si manquante
echo "5. Ajout de getComplexHelp dans les commandes..."
for file in src/Extended/Command/*/*.php; do
    if grep -q "class.*Command" "$file" && ! grep -q "getComplexHelp" "$file"; then
        # Ajouter avant la dernière accolade
        sed -i '' '/^}$/i\
\
    public function getComplexHelp(): array\
    {\
        return [\
            "description" => $this->getDescription(),\
            "usage" => [$this->getName()],\
            "examples" => []\
        ];\
    }' "$file"
    fi
done

# 6. Créer MonitoringDisplayService si absent
echo "6. Création de MonitoringDisplayService..."
if [ ! -f src/Extended/Service/MonitoringDisplayService.php ]; then
cat > src/Extended/Service/MonitoringDisplayService.php << 'EOF'
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
EOF
fi

# 7. Créer PHPUnitMonitoringService si absent
echo "7. Création de PHPUnitMonitoringService..."
if [ ! -f src/Extended/Service/PHPUnitMonitoringService.php ]; then
cat > src/Extended/Service/PHPUnitMonitoringService.php << 'EOF'
<?php

namespace Psy\Extended\Service;

class PHPUnitMonitoringService
{
    private array $metrics = [];
    
    /**
     * Start monitoring
     */
    public function startMonitoring(): array
    {
        return [
            'start_time' => microtime(true),
            'start_memory' => memory_get_usage(true),
            'initial_vars' => get_defined_vars()
        ];
    }
    
    /**
     * Stop monitoring and calculate metrics
     */
    public function stopMonitoring(array $startData): array
    {
        $endTime = microtime(true);
        $endMemory = memory_get_usage(true);
        $finalVars = get_defined_vars();
        
        return [
            'time' => ($endTime - $startData['start_time']) * 1000,
            'memory' => $endMemory - $startData['start_memory'],
            'variables' => array_diff_key($finalVars, $startData['initial_vars'])
        ];
    }
}
EOF
fi

# 8. Fix imports in files
echo "8. Ajout des imports manquants..."
find src/Extended/Command -name "*.php" -exec sed -i '' '
/^namespace/a\
\
use Symfony\\Component\\Console\\Output\\OutputInterface;
' {} \; 2>/dev/null || true

echo "✅ Corrections finales appliquées!"
echo ""
echo "Relance des tests..."

# Exécuter les tests
vendor/bin/phpunit test/Extended/Command/ --no-coverage 2>&1 | tail -50
