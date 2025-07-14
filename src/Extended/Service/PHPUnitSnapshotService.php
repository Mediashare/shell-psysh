<?php

namespace Psy\Extended\Service;

class PHPUnitSnapshotService
{
    private array $snapshots = [];
    private static $instance = null;

    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function createSnapshot(string $name, $data): array
    {
        $snapshot = [
            'name' => $name,
            'data' => $data,
            'created_at' => date('Y-m-d H:i:s'),
            'assertion' => $this->generateAssertion($data)
        ];
        
        $this->snapshots[$name] = $snapshot;
        return $snapshot;
    }

    public function hasSnapshot(string $name): bool
    {
        return isset($this->snapshots[$name]);
    }

    public function getSnapshot(string $name): ?array
    {
        return $this->snapshots[$name] ?? null;
    }

    public function compareWithSnapshot(string $name, $newData): array
    {
        if (!$this->hasSnapshot($name)) {
            throw new \InvalidArgumentException("Snapshot '{$name}' does not exist");
        }

        $snapshot = $this->snapshots[$name];
        $oldData = $snapshot['data'];
        
        $comparison = [
            'identical' => $this->deepEquals($oldData, $newData),
            'differences' => []
        ];

        if (!$comparison['identical']) {
            $comparison['differences'] = $this->findDifferences($oldData, $newData);
        }

        return $comparison;
    }

    public function saveSnapshotToFile(string $name, string $basePath): string
    {
        if (!$this->hasSnapshot($name)) {
            throw new \InvalidArgumentException("Snapshot '{$name}' does not exist");
        }

        $snapshot = $this->snapshots[$name];
        $fileName = $name . '.php';
        $filePath = rtrim($basePath, '/') . '/' . $fileName;

        $content = $this->generateSnapshotFile($snapshot);
        file_put_contents($filePath, $content);

        return $filePath;
    }

    private function generateAssertion($data): string
    {
        if (is_array($data)) {
            return '$this->assertEquals(' . $this->varExportFormatted($data) . ', $actualResult);';
        } elseif (is_object($data)) {
            return '$this->assertInstanceOf(' . get_class($data) . '::class, $actualResult);';
        } elseif (is_bool($data)) {
            return '$this->assert' . ($data ? 'True' : 'False') . '($actualResult);';
        } elseif (is_null($data)) {
            return '$this->assertNull($actualResult);';
        } elseif (is_string($data)) {
            return '$this->assertEquals(' . var_export($data, true) . ', $actualResult);';
        } elseif (is_numeric($data)) {
            return '$this->assertEquals(' . $data . ', $actualResult);';
        } else {
            return '$this->assertEquals(' . var_export($data, true) . ', $actualResult);';
        }
    }

    private function varExportFormatted($data, int $indent = 0): string
    {
        if (is_array($data)) {
            if (empty($data)) {
                return '[]';
            }

            $spaces = str_repeat('    ', $indent);
            $innerSpaces = str_repeat('    ', $indent + 1);
            $result = "[\n";

            foreach ($data as $key => $value) {
                $keyStr = is_string($key) ? var_export($key, true) : $key;
                $valueStr = $this->varExportFormatted($value, $indent + 1);
                $result .= "{$innerSpaces}{$keyStr} => {$valueStr},\n";
            }

            $result .= "{$spaces}]";
            return $result;
        } else {
            return var_export($data, true);
        }
    }

    private function deepEquals($a, $b): bool
    {
        if (gettype($a) !== gettype($b)) {
            return false;
        }

        if (is_array($a)) {
            if (count($a) !== count($b)) {
                return false;
            }
            foreach ($a as $key => $value) {
                if (!array_key_exists($key, $b) || !$this->deepEquals($value, $b[$key])) {
                    return false;
                }
            }
            return true;
        } elseif (is_object($a)) {
            return $a == $b; // Use PHP's object comparison
        } else {
            return $a === $b;
        }
    }

    private function findDifferences($old, $new, string $path = ''): array
    {
        $differences = [];

        if (gettype($old) !== gettype($new)) {
            $differences[] = [
                'path' => $path,
                'expected' => $this->formatValue($old),
                'actual' => $this->formatValue($new)
            ];
            return $differences;
        }

        if (is_array($old)) {
            $allKeys = array_unique(array_merge(array_keys($old), array_keys($new)));
            foreach ($allKeys as $key) {
                $currentPath = $path ? "{$path}[{$key}]" : "[{$key}]";
                
                if (!array_key_exists($key, $old)) {
                    $differences[] = [
                        'path' => $currentPath,
                        'expected' => '(missing)',
                        'actual' => $this->formatValue($new[$key])
                    ];
                } elseif (!array_key_exists($key, $new)) {
                    $differences[] = [
                        'path' => $currentPath,
                        'expected' => $this->formatValue($old[$key]),
                        'actual' => '(missing)'
                    ];
                } elseif (!$this->deepEquals($old[$key], $new[$key])) {
                    $differences = array_merge($differences, $this->findDifferences($old[$key], $new[$key], $currentPath));
                }
            }
        } elseif ($old !== $new) {
            $differences[] = [
                'path' => $path ?: 'root',
                'expected' => $this->formatValue($old),
                'actual' => $this->formatValue($new)
            ];
        }

        return $differences;
    }

    private function formatValue($value): string
    {
        if (is_null($value)) {
            return 'null';
        } elseif (is_bool($value)) {
            return $value ? 'true' : 'false';
        } elseif (is_string($value)) {
            return "'" . $value . "'";
        } elseif (is_array($value)) {
            return 'array(' . count($value) . ' items)';
        } elseif (is_object($value)) {
            return get_class($value) . ' object';
        } else {
            return (string) $value;
        }
    }

    private function generateSnapshotFile(array $snapshot): string
    {
        $className = ucfirst($snapshot['name']) . 'Snapshot';
        $data = $this->varExportFormatted($snapshot['data']);
        
        return "<?php

/**
 * Snapshot: {$snapshot['name']}
 * Created: {$snapshot['created_at']}
 */

namespace Tests\\Snapshots;

class {$className}
{
    public static function getData()
    {
        return {$data};
    }
    
    public static function getAssertion(): string
    {
        return '{$snapshot['assertion']}';
    }
}
";
    }

    public function getAllSnapshots(): array
    {
        return $this->snapshots;
    }

    public function clearSnapshots(): void
    {
        $this->snapshots = [];
    }

    public function removeSnapshot(string $name): bool
    {
        if (!$this->hasSnapshot($name)) {
            return false;
        }
        unset($this->snapshots[$name]);
        return true;
    }
}
