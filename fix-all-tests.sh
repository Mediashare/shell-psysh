#!/bin/bash

# Script pour corriger tous les tests restants

echo "🔧 Correction automatique de tous les tests..."

# 1. Ajouter les constantes de retour manquantes dans toutes les commandes
echo "1. Ajout des constantes de retour..."
find src/Extended/Command -name "*.php" -exec sed -i '' 's/self::SUCCESS/0/g' {} \;
find src/Extended/Command -name "*.php" -exec sed -i '' 's/self::FAILURE/1/g' {} \;
find src/Extended/Command -name "*.php" -exec sed -i '' 's/self::INVALID/2/g' {} \;
find src/Extended/Command -name "*.php" -exec sed -i '' 's/Command::SUCCESS/0/g' {} \;
find src/Extended/Command -name "*.php" -exec sed -i '' 's/Command::FAILURE/1/g' {} \;

# 2. Créer le service mock manquant s'il n'existe pas
if [ ! -f "src/Extended/Service/PHPUnitMockService.php" ]; then
echo "2. Création du service PHPUnitMockService..."
cat > src/Extended/Service/PHPUnitMockService.php << 'EOF'
<?php

namespace Psy\Extended\Service;

use PHPUnit\Framework\MockObject\MockObject;

class PHPUnitMockService
{
    private static $instance = null;
    private array $mocks = [];

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function createMock(string $className, string $variableName, array $methods = [], bool $partial = false): array
    {
        $mockCode = $this->generateMockCode($className, $variableName, $methods, $partial);
        
        return [
            'code' => $mockCode,
            'variable' => $variableName,
            'class' => $className,
            'available_methods' => $this->getAvailableMethods($className)
        ];
    }

    private function generateMockCode(string $className, string $variableName, array $methods, bool $partial): string
    {
        $code = "use PHPUnit\\Framework\\TestCase;\n";
        $code .= "\$testCase = new class extends TestCase {\n";
        $code .= "    public function __construct() {}\n";
        $code .= "};\n\n";

        if (empty($methods)) {
            $code .= "\${$variableName} = \$testCase->createMock('{$className}');";
        } else {
            $methodsStr = "'" . implode("', '", $methods) . "'";
            if ($partial) {
                $code .= "\${$variableName} = \$testCase->createPartialMock('{$className}', [{$methodsStr}]);";
            } else {
                $code .= "\${$variableName} = \$testCase->getMockBuilder('{$className}')\n";
                $code .= "    ->onlyMethods([{$methodsStr}])\n";
                $code .= "    ->getMock();";
            }
        }

        return $code;
    }

    private function getAvailableMethods(string $className): array
    {
        if (!class_exists($className) && !interface_exists($className)) {
            return [];
        }

        try {
            $reflection = new \ReflectionClass($className);
            $methods = [];
            foreach ($reflection->getMethods(\ReflectionMethod::IS_PUBLIC) as $method) {
                if (!$method->isConstructor() && !$method->isDestructor() && !$method->isStatic()) {
                    $methods[] = $method->getName();
                }
            }
            return $methods;
        } catch (\Exception $e) {
            return [];
        }
    }
}
EOF
fi

# 3. Corriger le problème de contexte dans les tests de monitoring
echo "3. Correction des services de monitoring..."
# Vérifier que MonitoringDisplayService affiche bien les bonnes sorties
sed -i '' 's/Temps écoulé/Temps/' src/Extended/Service/Monitoring/MonitoringDisplayService.php 2>/dev/null || true
sed -i '' 's/Mémoire utilisée/Mémoire/' src/Extended/Service/Monitoring/MonitoringDisplayService.php 2>/dev/null || true

echo "✅ Corrections appliquées!"
echo ""
echo "Relance des tests..."

# Relancer les tests
./run-extended-tests.sh
