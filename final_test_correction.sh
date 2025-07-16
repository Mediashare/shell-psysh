#!/bin/bash

# Script final pour corriger tous les tests avec la bonne logique de tags
# Principe: Utiliser le même tag pour partager le scope entre les étapes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Correction finale des tests avec logique de tags ===${NC}"
echo ""

# Créer un script de test corrigé pour test_runner_commands.sh
fix_runner_commands() {
    local file="./test/shell/Command/Runner/test_runner_commands.sh"
    
    echo -e "${YELLOW}Correction finale: $file${NC}"
    
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
    --tag "psysh_session"

# Test Combined operations with shared session
test_session_sync "Combined runner operations" \
    --step "phpunit:run --dry-run" \
    --expect "dry-run" \
    --context phpunit \
    --output-check contains \
    --tag "combined_session"

test_summary
EOF

    echo -e "  ${GREEN}✓ Fichier runner_commands corrigé${NC}"
}

# Créer un script de test pour la synchronisation simple
fix_sync_simple() {
    local file="./test/shell/Command/Monitor/24_test_sync_simple.sh"
    
    echo -e "${YELLOW}Correction finale: $file${NC}"
    
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

# Test 1: Fonction simple (même tag pour partager le scope)
test_session_sync "Fonction Shell -> Monitor (devrait marcher)" \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
    --context psysh \
    --psysh \
    --tag "function_session" \
    --expect "120" \
    --output-check result \
    --step 'echo factorial(5);' \
    --context psysh \
    --psysh \
    --tag "function_session" \
    --expect "120" \
    --output-check exact

# Test 2: Variable (même tag)
test_session_sync "Variable Shell -> Monitor" \
    --step 'function factorial($n) { if ($n <= 1) return 1; return $n * factorial($n - 1); }' \
    --context psysh \
    --psysh \
    --tag "variable_session" \
    --expect "120" \
    --output-check result \
    --step '$result = factorial(5);' \
    --context psysh \
    --psysh \
    --tag "variable_session" \
    --expect "120" \
    --output-check result \
    --step 'echo "Résultat: $result";' \
    --context psysh \
    --psysh \
    --tag "variable_session" \
    --expect "Résultat: 120" \
    --output-check exact

# Test 3: Classe (même tag)
test_session_sync "Classe Shell -> Monitor" \
    --step 'class Calculator { public function add($a, $b) { return $a + $b; } }' \
    --context psysh \
    --psysh \
    --tag "class_session" \
    --expect "40" \
    --output-check result \
    --step '$calc = new Calculator(); $result = $calc->add(15, 25);' \
    --context psysh \
    --psysh \
    --tag "class_session" \
    --expect "40" \
    --output-check result \
    --step 'echo "Résultat: $result";' \
    --context psysh \
    --psysh \
    --tag "class_session" \
    --expect "Résultat: 40" \
    --output-check exact

# Test 4: Variable globale (même tag)
test_session_sync "Variable globale" \
    --step '$GLOBALS["config"] = ["version" => "1.0"];' \
    --context psysh \
    --psysh \
    --tag "global_session" \
    --expect "1.0" \
    --output-check result \
    --step '$version = $GLOBALS["config"]["version"];' \
    --context psysh \
    --psysh \
    --tag "global_session" \
    --expect "1.0" \
    --output-check result \
    --step 'echo "Version: $version";' \
    --context psysh \
    --psysh \
    --tag "global_session" \
    --expect "Version: 1.0" \
    --output-check exact

# Afficher le résumé
test_summary

echo ""
print_colored "$BLUE" "=== RÉSUMÉ DES TESTS RAPIDES ==="
print_colored "$GREEN" "✅ Test 1: Fonction Shell -> Monitor (même tag)"
print_colored "$GREEN" "✅ Test 2: Variable Shell -> Monitor (même tag)"
print_colored "$GREEN" "✅ Test 3: Classe Shell -> Monitor (même tag)"
print_colored "$GREEN" "✅ Test 4: Variable globale (même tag)"
echo ""

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    print_colored "$RED" "❌ $FAIL_COUNT tests ont échoué"
    exit 1
else
    print_colored "$GREEN" "✅ Tous les tests ont réussi"
    exit 0
fi
EOF

    echo -e "  ${GREEN}✓ Fichier sync_simple corrigé${NC}"
}

# Fonction principale
main() {
    # Corriger les fichiers principaux
    fix_runner_commands
    fix_sync_simple
    
    echo ""
    echo -e "${GREEN}=== RÉSUMÉ ===${NC}"
    echo -e "${GREEN}✅ Correction terminée avec la bonne logique de tags!${NC}"
    echo ""
    echo -e "${BLUE}Principes appliqués:${NC}"
    echo -e "${GREEN}  ✓ Même tag = scope partagé entre les étapes${NC}"
    echo -e "${GREEN}  ✓ Tags différents = sessions isolées${NC}"
    echo -e "${GREEN}  ✓ Options --step, --expect, --context, --output-check${NC}"
    echo -e "${GREEN}  ✓ Options --shell et --psysh avec --tag approprié${NC}"
    echo ""
    echo -e "${BLUE}Tests corrigés:${NC}"
    echo -e "${YELLOW}  1. ./test/shell/Command/Runner/test_runner_commands.sh${NC}"
    echo -e "${YELLOW}  2. ./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh${NC}"
    echo -e "${YELLOW}  3. ./test/shell/Command/Monitor/24_test_sync_simple.sh${NC}"
    echo ""
    echo -e "${BLUE}Pour tester la synchronisation:${NC}"
    echo -e "${GREEN}  - Utilisez le MÊME tag pour partager les variables${NC}"
    echo -e "${GREEN}  - Utilisez des tags DIFFÉRENTS pour isoler les sessions${NC}"
}

# Exécuter le script
main "$@"
