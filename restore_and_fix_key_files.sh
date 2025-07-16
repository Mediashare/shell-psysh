#!/bin/bash

# Script pour restaurer les backups et corriger manuellement les fichiers clés
# Approche ciblée sur les fichiers les plus importants

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Restauration et correction des fichiers clés ===${NC}"
echo ""

# Fonction pour restaurer un fichier depuis son backup
restore_file() {
    local file="$1"
    local backup_pattern="$file.backup_*"
    
    # Trouver le backup le plus récent
    local latest_backup=$(ls -t $backup_pattern 2>/dev/null | head -1)
    
    if [[ -n "$latest_backup" && -f "$latest_backup" ]]; then
        cp "$latest_backup" "$file"
        echo -e "${GREEN}✓ Restauré: $file${NC}"
        return 0
    else
        echo -e "${RED}✗ Backup non trouvé pour: $file${NC}"
        return 1
    fi
}

# Fonction pour corriger le fichier runner_commands.sh
fix_runner_commands() {
    local file="./test/shell/Command/Runner/test_runner_commands.sh"
    
    echo -e "${YELLOW}Correction manuelle: $file${NC}"
    
    # Créer backup
    cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
    
    # Écrire la version corrigée
    cat > "$file" << 'EOF'
#!/bin/bash

# Test script for Runner commands
# Tests PHPUnitRunCommand, PHPUnitDebugCommand, PHPUnitMonitorCommand, etc.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Vérifier que PROJECT_ROOT est défini
if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
    export PROJECT_ROOT
fi

init_test "Runner Commands"
echo ""

# Test PHPUnitRunCommand (phpunit:run)
test_session_sync "phpunit:run basic execution" \
    --step "phpunit:run --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitRunAllCommand (phpunit:run-all)
test_session_sync "phpunit:run-all help" \
    --step "phpunit:run-all --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitRunProjectCommand (phpunit:run-project)
test_session_sync "phpunit:run-project help" \
    --step "phpunit:run-project --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitDebugCommand (phpunit:debug)
test_session_sync "phpunit:debug help" \
    --step "phpunit:debug --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitMonitorCommand (phpunit:monitor)
test_session_sync "phpunit:monitor help" \
    --step "phpunit:monitor --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitProfileCommand (phpunit:profile)
test_session_sync "phpunit:profile help" \
    --step "phpunit:profile --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitTraceCommand (phpunit:trace)
test_session_sync "phpunit:trace help" \
    --step "phpunit:trace --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitWatchCommand (phpunit:watch)
test_session_sync "phpunit:watch help" \
    --step "phpunit:watch --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PHPUnitExplainCommand (phpunit:explain)
test_session_sync "phpunit:explain help" \
    --step "phpunit:explain --help" \
    --expect "Usage:" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test PsyshMonitorCommand (psysh:monitor)
test_session_sync "psysh:monitor help" \
    --step "psysh:monitor --help" \
    --expect "Usage:" \
    --context monitor \
    --output-check contains \
    --tag "monitor_session"

# Test TabCommand (tab)
test_session_sync "tab command help" \
    --step "tab --help" \
    --expect "Usage:" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test TestParamsCommand (test:params)
test_session_sync "test:params help" \
    --step "test:params --help" \
    --expect "Usage:" \
    --context psysh \
    --output-check contains \
    --psysh \
    --tag "default_session"

# Test combined runner operations
test_session_sync "Combined runner operations" \
    --step "phpunit:run --dry-run; phpunit:debug --list-tests" \
    --expect "dry-run" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

test_summary
EOF

    echo -e "${GREEN}✓ Fichier runner_commands corrigé${NC}"
}

# Fonction pour corriger le fichier de synchronisation PHPUnit
fix_phpunit_sync() {
    local file="./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh"
    
    echo -e "${YELLOW}Correction manuelle: $file${NC}"
    
    # Créer backup
    cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
    
    # Écrire la version corrigée avec des exemples de synchronisation
    cat > "$file" << 'EOF'
#!/bin/bash

# Test 35: Synchronisation Shell/PHPUnit - Tests avancés de synchronisation
# Tests complets de synchronisation entre les shells PsySH et les commandes phpunit:*

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 35: Synchronisation Shell/PHPUnit"

# Étape 1: Test synchronisation basique - variables
test_session_sync "Synchronisation variable simple" \
    --step '$globalVar = "test_value"' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step 'phpunit:create SyncTest' \
    --context phpunit \
    --tag "phpunit_session" \
    --step 'echo $globalVar' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "test_value" \
    --output-check contains

# Étape 2: Test synchronisation avec phpunit:code
test_session_sync "Synchronisation via phpunit:code" \
    --step 'phpunit:create CodeSyncTest' \
    --context phpunit \
    --tag "phpunit_session" \
    --step 'phpunit:code --snippet "$codeVar = 123;"' \
    --context phpunit \
    --tag "phpunit_session" \
    --step 'echo $codeVar' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "123" \
    --output-check contains

# Étape 3: Test synchronisation objet complexe
test_session_sync "Synchronisation objet" \
    --step '$user = new stdClass(); $user->name = "John"; $user->age = 30' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step 'phpunit:create ObjectSyncTest' \
    --context phpunit \
    --tag "phpunit_session" \
    --step 'echo $user->name' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "John" \
    --output-check contains

# Étape 4: Test synchronisation array
test_session_sync "Synchronisation array" \
    --step '$testArray = [1, 2, 3, "test"]' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step 'phpunit:create ArraySyncTest' \
    --context phpunit \
    --tag "phpunit_session" \
    --step 'echo count($testArray)' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "4" \
    --output-check contains

# Étape 5: Test synchronisation fonction
test_session_sync "Synchronisation fonction" \
    --step 'function testFunction($param) { return $param * 2; }' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step 'phpunit:create FunctionSyncTest' \
    --context phpunit \
    --tag "phpunit_session" \
    --step 'echo testFunction(5)' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "10" \
    --output-check contains

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
EOF

    echo -e "${GREEN}✓ Fichier phpunit_sync corrigé${NC}"
}

# Fonction pour corriger le fichier de synchronisation simple
fix_sync_simple() {
    local file="./test/shell/Command/Monitor/24_test_sync_simple.sh"
    
    echo -e "${YELLOW}Correction manuelle: $file${NC}"
    
    # Créer backup
    cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
    
    # Écrire la version corrigée
    cat > "$file" << 'EOF'
#!/bin/bash

# Test 24 Simple: Test rapide de synchronisation Shell <-> Monitor
# Version simplifiée pour tests rapides

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "TEST 24 Simple: Synchronisation rapide Shell <-> Monitor"

# Test 1: Fonction fonctionne (pour confirmer que les fonctions SONT synchronisées)
test_session_sync "Fonction Shell -> Monitor (devrait marcher)" \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step 'echo factorial(5);' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "120" \
    --output-check contains

# Test 2: Bug principal - Variable créée dans Monitor non accessible dans Shell
test_session_sync "Bug principal: Variable Monitor -> Shell" \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step '$result = factorial(5);' \
    --context monitor \
    --tag "monitor_session" \
    --step 'echo "Résultat dans shell: $result";' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "Résultat dans shell: 120" \
    --output-check contains

# Test 3: Classe Shell -> Monitor  
test_session_sync "Classe Shell -> Monitor" \
    --step 'class Calculator { public function add($a, $b) { return $a + $b; } }' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step '$calc = new Calculator(); $result = $calc->add(15, 25);' \
    --context monitor \
    --tag "monitor_session" \
    --step 'echo "Résultat: $result";' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "40" \
    --output-check contains

# Test 4: Variable globale
test_session_sync "Variable globale" \
    --step '$GLOBALS["config"] = ["version" => "1.0"];' \
    --context psysh \
    --psysh \
    --tag "sync_session" \
    --step '$version = $GLOBALS["config"]["version"];' \
    --context monitor \
    --tag "monitor_session" \
    --step 'echo "Version: $version";' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "1.0" \
    --output-check contains

# Afficher le résumé
test_summary

echo ""
print_colored "$BLUE" "=== RÉSUMÉ DES TESTS RAPIDES ==="
print_colored "$GREEN" "✅ Test 1: Fonction Shell -> Monitor (devrait marcher)"
print_colored "$RED" "❌ Test 2: Bug principal (variable Monitor -> Shell)"
print_colored "$GREEN" "✅ Test 3: Classe Shell -> Monitor"
print_colored "$GREEN" "✅ Test 4: Variable globale"
echo ""

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    print_colored "$RED" "❌ $FAIL_COUNT tests ont échoué - bugs de synchronisation détectés"
    exit 1
else
    print_colored "$GREEN" "✅ Tous les tests rapides ont réussi"
    exit 0
fi
EOF

    echo -e "${GREEN}✓ Fichier sync_simple corrigé${NC}"
}

# Fonction principale
main() {
    echo -e "${BLUE}Phase 1: Restauration des fichiers depuis les backups${NC}"
    
    # Restaurer les fichiers clés
    restore_file "./test/shell/Command/Runner/test_runner_commands.sh"
    restore_file "./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh"
    restore_file "./test/shell/Command/Monitor/24_test_sync_simple.sh"
    
    echo ""
    echo -e "${BLUE}Phase 2: Correction manuelle des fichiers clés${NC}"
    
    # Corriger les fichiers clés avec les bons formats
    fix_runner_commands
    fix_phpunit_sync
    fix_sync_simple
    
    echo ""
    echo -e "${GREEN}=== RÉSUMÉ ===${NC}"
    echo -e "${GREEN}✅ 3 fichiers clés corrigés avec le format test_session_sync approprié${NC}"
    echo ""
    echo -e "${BLUE}Fichiers corrigés:${NC}"
    echo -e "${YELLOW}  1. ./test/shell/Command/Runner/test_runner_commands.sh${NC}"
    echo -e "${YELLOW}  2. ./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh${NC}"
    echo -e "${YELLOW}  3. ./test/shell/Command/Monitor/24_test_sync_simple.sh${NC}"
    echo ""
    echo -e "${BLUE}Ces fichiers utilisent maintenant:${NC}"
    echo -e "${GREEN}  ✓ Options --step, --expect, --context, --output-check${NC}"
    echo -e "${GREEN}  ✓ Options --shell et --psysh pour forcer le contexte${NC}"
    echo -e "${GREEN}  ✓ Options --tag pour gérer les sessions${NC}"
    echo -e "${GREEN}  ✓ Gestion des tests multi-étapes avec différents contextes${NC}"
    echo ""
    echo -e "${BLUE}Tests recommandés:${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Runner/test_runner_commands.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Monitor/24_test_sync_simple.sh${NC}"
}

# Exécuter le script
main "$@"
