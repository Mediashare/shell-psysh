#!/bin/bash

# Script simplifié pour corriger les patterns spécifiques test_session_sync
# Traite les patterns que vous avez mentionnés

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Correction des patterns test_session_sync ===${NC}"
echo ""

# Compteurs
TOTAL_FILES=0
MODIFIED_FILES=0

# Fonction pour corriger un fichier
fix_file() {
    local file="$1"
    local backup_file="$file.backup_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${YELLOW}Traitement: $file${NC}"
    
    # Créer backup
    cp "$file" "$backup_file"
    
    # Pattern 1: Corriger les appels avec "test_session_sync "Test command" --step"
    sed -i '' -E '
        # Corriger les lignes avec test_session_sync imbriqué
        s/"test_session_sync \"Test command\" --step \\\\"([^\\]+)\\\\""/--step "\1"/g
        
        # Supprimer les lignes vides ou cassées qui restent
        /^\s*""\s*\\\s*$/d
        /^\s*--step ""\s*\\\s*--context/d
        
        # Ajouter les options manquantes pour les appels simples
        /test_session_sync "[^"]*" \\$/{
            N
            /--step "[^"]*" \\$/{
                N
                /--expect "[^"]*" \\$/{
                    N
                    /--context [^\\]*/{
                        # Déjà bien formaté
                        b
                    }
                    # Ajouter context, output-check et tag
                    s/$/\
    --context phpunit \\\
    --output-check contains \\\
    --tag "phpunit_session"/
                }
            }
        }
    ' "$file"
    
    # Pattern 2: Corriger les tests avec arguments cassés
    python3 -c "
import re
import sys

def fix_broken_calls(content):
    # Pattern pour détecter les appels cassés
    pattern = r'test_session_sync \"([^\"]+)\" \\\\\\\\\n([^\\n]*--step[^\\n]*)\n([^\\n]*--context[^\\n]*)\n([^\\n]*--output-check[^\\n]*)\n([^\\n]*--tag[^\\n]*)\n([^\\n]*\"[^\"]*\"[^\\n]*)\n([^\\n]*check_contains[^\\n]*)'
    
    def fix_call(match):
        description = match.group(1)
        step_line = match.group(2)
        context_line = match.group(3)
        output_check_line = match.group(4)
        tag_line = match.group(5)
        expect_line = match.group(6)
        check_line = match.group(7)
        
        # Extraire les valeurs
        step = ''
        if '--step' in step_line:
            step_match = re.search(r'--step \"([^\"]+)\"', step_line)
            if step_match:
                step = step_match.group(1)
        
        context = 'phpunit'
        if '--context' in context_line:
            context_match = re.search(r'--context ([^\\s]+)', context_line)
            if context_match:
                context = context_match.group(1)
        
        tag = 'phpunit_session'
        if '--tag' in tag_line:
            tag_match = re.search(r'--tag \"([^\"]+)\"', tag_line)
            if tag_match:
                tag = tag_match.group(1)
        
        expect = 'Usage:'
        expect_match = re.search(r'\"([^\"]+)\"', expect_line)
        if expect_match:
            expect = expect_match.group(1)
        
        # Construire le nouvel appel
        new_call = f'test_session_sync \"{description}\" \\\\\\\\\\n'
        new_call += f'    --step \"{step}\" \\\\\\\\\\n'
        new_call += f'    --expect \"{expect}\" \\\\\\\\\\n'
        new_call += f'    --context {context} \\\\\\\\\\n'
        new_call += f'    --output-check contains \\\\\\\\\\n'
        new_call += f'    --tag \"{tag}\"'
        
        return new_call
    
    return re.sub(pattern, fix_call, content, flags=re.MULTILINE)

# Lire le fichier
with open('$file', 'r') as f:
    content = f.read()

# Appliquer les corrections
fixed_content = fix_broken_calls(content)

# Corrections supplémentaires avec regex
import re

# Corriger les appels test_session_sync avec guillemets simples (synchronisation)
sync_pattern = r'test_session_sync \"([^\"]+)\" \\\\\\\\\n\x27([^\x27]+)\x27 \\\\\\\\\n\x27([^\x27]+)\x27 \\\\\\\\\n\x27([^\x27]+)\x27 \\\\\\\\\n\x27([^\x27]+)\x27 \\\\\\\\\n\x27([^\x27]+)\x27'

def fix_sync_call(match):
    description = match.group(1)
    step1 = match.group(2)
    step2 = match.group(3)
    step3 = match.group(4)
    expect = match.group(5)
    tag = match.group(6)
    
    new_call = f'test_session_sync \"{description}\" \\\\\\\\\\n'
    
    # Première étape - généralement psysh
    if step1.startswith('\$'):
        new_call += f'    --step \'{step1}\' \\\\\\\\\\n'
        new_call += f'    --context psysh \\\\\\\\\\n'
        new_call += f'    --psysh \\\\\\\\\\n'
        new_call += f'    --tag \"sync_session\" \\\\\\\\\\n'
    
    # Deuxième étape - généralement phpunit
    if step2.startswith('phpunit:'):
        new_call += f'    --step \'{step2}\' \\\\\\\\\\n'
        new_call += f'    --context phpunit \\\\\\\\\\n'
        new_call += f'    --tag \"phpunit_session\" \\\\\\\\\\n'
        new_call += f'    --expect \"✅ Test créé :\" \\\\\\\\\\n'
        new_call += f'    --output-check contains \\\\\\\\\\n'
    
    # Troisième étape - généralement shell
    if step3.startswith('echo'):
        new_call += f'    --step \'{step3}\' \\\\\\\\\\n'
        new_call += f'    --context shell \\\\\\\\\\n'
        new_call += f'    --shell \\\\\\\\\\n'
        new_call += f'    --tag \"shell_session\" \\\\\\\\\\n'
    
    # Expectation finale
    new_call += f'    --expect \"{expect}\" \\\\\\\\\\n'
    new_call += f'    --output-check exact'
    
    return new_call

fixed_content = re.sub(sync_pattern, fix_sync_call, fixed_content, flags=re.MULTILINE)

# Écrire le fichier corrigé
with open('$file', 'w') as f:
    f.write(fixed_content)
"
    
    echo -e "  ${GREEN}✓ Corrigé${NC}"
    ((MODIFIED_FILES++))
}

# Fonction pour corriger spécifiquement les fichiers cassés
fix_broken_files() {
    # Corriger test_phpunit_create.sh
    local file="./test/shell/Command/PHPUnit/test_phpunit_create.sh"
    if [[ -f "$file" ]]; then
        echo -e "${YELLOW}Correction spéciale: $file${NC}"
        
        # Créer backup
        cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
        
        # Réécrire complètement le fichier
        cat > "$file" << 'EOF'
#!/bin/bash

# Test des fonctionnalités de création PHPUnit

# Obtenir le répertoire du script et le project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"

# Source les bibliothèques de test
source "$SCRIPT_DIR/../../lib/func/loader.sh"
# Charger test_session_sync
source "$(dirname "$0")/../../lib/func/test_session_sync_enhanced.sh"

# Initialiser le test
init_test "PHPUnit: Command Create"

# Test création basique
test_session_sync "Créer un test simple" \
    --step "phpunit:create 'App\\Service\\TestService'" \
    --expect "✅" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test création avec une classe simple
test_session_sync "Créer un test pour une classe utilitaire" \
    --step "phpunit:create 'App\\Util\\Calculator'" \
    --expect "✅" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Test avec namespace simple
test_session_sync "Créer un test avec namespace simple" \
    --step "phpunit:create 'MyClass'" \
    --expect "✅" \
    --context phpunit \
    --output-check contains \
    --tag "phpunit_session"

# Afficher le résumé des tests
test_summary

# Retourner un code de sortie en fonction des résultats des tests
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
EOF

        echo -e "  ${GREEN}✓ Fichier test_phpunit_create.sh corrigé${NC}"
        ((MODIFIED_FILES++))
    fi
}

# Fonction pour corriger le fichier de synchronisation PHPUnit
fix_phpunit_sync() {
    local file="./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh"
    if [[ -f "$file" ]]; then
        echo -e "${YELLOW}Correction spéciale: $file${NC}"
        
        # Créer backup
        cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
        
        # Réécrire avec le format correct multi-étapes
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
    --tag "sync_session"

test_session_sync "Créer test pour synchronisation" \
    --step 'phpunit:create SyncTest' \
    --context phpunit \
    --tag "phpunit_session" \
    --expect "✅ Test créé :" \
    --output-check contains

test_session_sync "Vérifier variable synchronisée" \
    --step 'echo $globalVar' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "test_value" \
    --output-check exact

# Étape 2: Test synchronisation avec phpunit:code
test_session_sync "Synchronisation via phpunit:code" \
    --step 'phpunit:create CodeSyncTest' \
    --context phpunit \
    --tag "phpunit_session" \
    --expect "✅ Test créé :" \
    --output-check contains

test_session_sync "Ajouter code via phpunit:code" \
    --step 'phpunit:code --snippet "$codeVar = 123;"' \
    --context phpunit \
    --tag "phpunit_session" \
    --expect "Code ajouté" \
    --output-check contains

test_session_sync "Vérifier variable de code" \
    --step 'echo $codeVar' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "123" \
    --output-check exact

# Étape 3: Test synchronisation objet complexe
test_session_sync "Synchronisation objet" \
    --step '$user = new stdClass(); $user->name = "John"; $user->age = 30' \
    --context psysh \
    --psysh \
    --tag "sync_session"

test_session_sync "Créer test pour objet" \
    --step 'phpunit:create ObjectSyncTest' \
    --context phpunit \
    --tag "phpunit_session" \
    --expect "✅ Test créé :" \
    --output-check contains

test_session_sync "Vérifier propriété objet" \
    --step 'echo $user->name' \
    --context shell \
    --shell \
    --tag "shell_session" \
    --expect "John" \
    --output-check exact

# Afficher le résumé
test_summary

# Sortir avec le code approprié
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
EOF

        echo -e "  ${GREEN}✓ Fichier phpunit_sync corrigé${NC}"
        ((MODIFIED_FILES++))
    fi
}

# Fonction principale
main() {
    echo -e "${BLUE}Recherche des fichiers à corriger...${NC}"
    
    # Corriger les fichiers spécifiques d'abord
    fix_broken_files
    fix_phpunit_sync
    
    # Trouver tous les fichiers de test
    local test_files=()
    while IFS= read -r -d '' file; do
        if [[ ! "$file" =~ \.backup ]]; then
            test_files+=("$file")
        fi
    done < <(find "./test/shell/Command" -name "*.sh" -print0)
    
    TOTAL_FILES=${#test_files[@]}
    echo -e "${BLUE}Traitement de $TOTAL_FILES fichiers${NC}"
    echo ""
    
    # Traiter chaque fichier
    for file in "${test_files[@]}"; do
        # Ignorer les fichiers déjà corrigés
        if [[ "$file" != "./test/shell/Command/PHPUnit/test_phpunit_create.sh" && \
              "$file" != "./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh" ]]; then
            fix_file "$file"
        fi
    done
    
    echo -e "${GREEN}=== RÉSUMÉ ===${NC}"
    echo -e "${BLUE}Fichiers analysés: $TOTAL_FILES${NC}"
    echo -e "${GREEN}Fichiers modifiés: $MODIFIED_FILES${NC}"
    echo ""
    echo -e "${GREEN}✅ Correction terminée!${NC}"
    echo ""
    echo -e "${BLUE}Formats corrigés:${NC}"
    echo -e "${GREEN}  ✓ Appels test_session_sync imbriqués${NC}"
    echo -e "${GREEN}  ✓ Tests de synchronisation multi-étapes${NC}"
    echo -e "${GREEN}  ✓ Options --step, --expect, --context, --output-check${NC}"
    echo -e "${GREEN}  ✓ Options --shell et --psysh avec --tag${NC}"
    echo ""
    echo -e "${BLUE}Tests recommandés:${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/PHPUnit/test_phpunit_create.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/PHPUnit/35_test_phpunit_sync.sh${NC}"
    echo -e "${YELLOW}  ./test/shell/Command/Runner/test_runner_commands.sh${NC}"
}

# Exécuter le script
main "$@"
