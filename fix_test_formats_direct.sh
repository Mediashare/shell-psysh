#!/bin/bash

# Script direct pour corriger les formats test_session_sync
# Approche simple et directe avec patterns spécifiques

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Correction directe des formats test_session_sync ===${NC}"

# Fonction pour corriger un fichier spécifique
fix_file() {
    local file="$1"
    local backup_file="$file.backup_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${YELLOW}Correction: $file${NC}"
    
    # Créer backup
    cp "$file" "$backup_file"
    
    # Corrections spécifiques avec sed
    sed -i '' '
        # Corriger les appels test_session_sync avec step imbriqué
        s/test_session_sync "\([^"]*\)" \\\\/test_session_sync "\1" \\\\/g
        
        # Remplacer les appels test_session_sync imbriqués par des options propres
        s/"test_session_sync \\"Test command\\" --step \\\\\\"\\([^\\]*\\)\\\\\\""/--step "\1" --context phpunit --output-check contains --tag "phpunit_session"/g
        
        # Nettoyer les lignes vides générées
        /^[[:space:]]*$/d
        
        # Reconstruire les appels test_session_sync corrects
        /test_session_sync/ {
            # Si la ligne contient déjà --step, la garder telle quelle
            /--step/! {
                # Sinon, traiter comme un ancien format
                s/test_session_sync "\([^"]*\)" \\\\/test_session_sync "\1" \\\\/
                # Ajouter une ligne temporaire pour marquer le début
                a\
__TEMP_START__
            }
        }
        
        # Traiter les lignes après test_session_sync
        /__TEMP_START__/ {
            n
            # Si cest une ligne avec des guillemets, cest probablement un step
            /^[[:space:]]*"[^"]*"[[:space:]]*\\\\/ {
                s/"\\([^"]*\\)"/    --step "\1" \\\\/
                a\
    --context phpunit \\\\
                a\
    --output-check contains \\\\
                a\
    --tag "phpunit_session"
            }
            # Supprimer la ligne temporaire
            s/__TEMP_START__//
        }
    ' "$file"
    
    echo -e "  ${GREEN}✓ Corrigé${NC}"
}

# Fonction pour corriger manuellement les fichiers problématiques
fix_runner_commands() {
    local file="./test/shell/Command/Runner/test_runner_commands.sh"
    local backup_file="$file.backup_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${YELLOW}Correction spéciale: $file${NC}"
    
    # Créer backup
    cp "$file" "$backup_file"
    
    # Réécrire le fichier avec les bons formats
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

    echo -e "  ${GREEN}✓ Fichier runner_commands corrigé manuellement${NC}"
}

# Fonction pour corriger les tests de synchronisation
fix_sync_files() {
    local file="$1"
    local backup_file="$file.backup_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${YELLOW}Correction synchronisation: $file${NC}"
    
    # Créer backup
    cp "$file" "$backup_file"
    
    # Corrections spécifiques pour les fichiers de sync
    if [[ "$file" =~ phpunit_sync ]]; then
        # Traiter les appels de synchronisation PHP/PHPUnit
        sed -i '' '
            # Corriger les appels test_session_sync multi-lignes
            /test_session_sync.*Synchronisation/ {
                # Lire les 5 lignes suivantes
                N;N;N;N;N
                # Convertir le format
                s/test_session_sync "\([^"]*\)" \\\\\n\x27\$\([^']*\)\x27 \\\\\n\x27phpunit:\([^']*\)\x27 \\\\\n\x27echo \([^']*\)\x27 \\\\\n\x27\([^']*\)\x27 \\\\\n\x27\([^']*\)\x27/test_session_sync "\1" \\\\\n    --step "$\2" --context psysh --psysh --tag "sync_session" \\\\\n    --step "phpunit:\3" --context phpunit --tag "phpunit_session" \\\\\n    --step "echo \4" --context shell --shell --tag "shell_session" \\\\\n    --expect "\5" --output-check contains/
            }
        ' "$file"
    fi
    
    if [[ "$file" =~ sync_simple ]]; then
        # Traiter les appels de synchronisation simples
        sed -i '' '
            # Corriger les appels test_session_sync simples
            /test_session_sync.*Shell.*Monitor/ {
                N;N;N;N;N
                s/test_session_sync "\([^"]*\)" \\\\\n\x27\([^']*\)\x27 \\\\\n\x27\([^']*\)\x27 \\\\\n\x27\x27 \\\\\n\x27\([^']*\)\x27 \\\\\n\x27\([^']*\)\x27/test_session_sync "\1" \\\\\n    --step "\2" --context psysh --psysh --tag "sync_session" \\\\\n    --step "\3" --context shell --shell --tag "shell_session" \\\\\n    --expect "\4" --output-check contains/
            }
        ' "$file"
    fi
    
    echo -e "  ${GREEN}✓ Fichier sync corrigé${NC}"
}

# Fonction principale
main() {
    echo ""
    
    # Corriger des fichiers spécifiques d'abord
    fix_runner_commands
    
    # Corriger les fichiers de synchronisation
    fix_sync_files "./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh"
    fix_sync_files "./test/shell/Command/Monitor/24_test_sync_simple.sh"
    
    # Traiter les autres fichiers
    echo -e "${BLUE}Traitement des autres fichiers...${NC}"
    
    local count=0
    while IFS= read -r -d '' file; do
        # Ignorer les fichiers déjà traités
        if [[ "$file" != "./test/shell/Command/Runner/test_runner_commands.sh" ]] && 
           [[ "$file" != "./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh" ]] && 
           [[ "$file" != "./test/shell/Command/Monitor/24_test_sync_simple.sh" ]]; then
            fix_file "$file"
            ((count++))
        fi
    done < <(find "./test/shell/Command" -name "*.sh" -print0)
    
    echo ""
    echo -e "${GREEN}=== RÉSUMÉ ===${NC}"
    echo -e "${BLUE}Fichiers traités: $((count + 3))${NC}"
    echo -e "${GREEN}✅ Correction terminée!${NC}"
    echo ""
    echo -e "${BLUE}Tests recommandés:${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Runner/test_runner_commands.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Monitor/24_test_sync_simple.sh${NC}"
}

# Exécuter le script
main "$@"
