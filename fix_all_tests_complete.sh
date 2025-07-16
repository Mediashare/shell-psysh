#!/bin/bash

# =============================================================================
# SCRIPT POUR CORRIGER AUTOMATIQUEMENT TOUS LES FICHIERS DE TEST
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Correction automatique de tous les fichiers de test...${NC}"

# Fonction pour corriger un fichier
fix_test_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    echo -e "${CYAN}🔧 Fixing $basename...${NC}"
    
    # Ajouter l'import test_session_sync si pas déjà présent
    if ! grep -q "test_session_sync_enhanced.sh" "$file"; then
        sed -i '' '/source.*loader\.sh/a\
source "$SCRIPT_DIR/../../lib/func/test_session_sync_enhanced.sh"
' "$file"
    fi
    
    # Remplacer test_execute par test_session_sync
    sed -i '' 's/test_execute \([^"]*\)"\([^"]*\)" \\\\/test_session_sync \1"\2" \\\\/g' "$file"
    sed -i '' 's/test_execute \([^"]*\)"\([^"]*\)" \([^'"'"']*\)'"'"'\([^'"'"']*\)'"'"' \\\\/test_session_sync \1"\2" \\\\\n    --step \3"\4" \\\\/g' "$file"
    
    # Remplacer les patterns test_execute avec 3 arguments
    sed -i '' 's/test_execute "\([^"]*\)" \([^"]*\) "\([^"]*\)"/test_session_sync "\1" \\\n    --step \2 \\\n    --expect "\3" \\\n    --context monitor/g' "$file"
    
    # Remplacer test_monitor par test_session_sync
    sed -i '' 's/test_monitor \([^"]*\)"\([^"]*\)" \([^'"'"']*\)'"'"'\([^'"'"']*\)'"'"' "\([^"]*\)"/test_session_sync \1"\2" \\\n    --step \3"\4" \\\n    --expect "\5" \\\n    --context monitor/g' "$file"
    
    # Remplacer test_phpunit par test_session_sync
    sed -i '' 's/test_phpunit \([^"]*\)"\([^"]*\)" \([^'"'"']*\)'"'"'\([^'"'"']*\)'"'"' "\([^"]*\)"/test_session_sync \1"\2" \\\n    --step \3"\4" \\\n    --expect "\5" \\\n    --context phpunit/g' "$file"
    
    # Remplacer test_shell par test_session_sync
    sed -i '' 's/test_shell \([^"]*\)"\([^"]*\)" \([^'"'"']*\)'"'"'\([^'"'"']*\)'"'"' "\([^"]*\)"/test_session_sync \1"\2" \\\n    --step \3"\4" \\\n    --expect "\5" \\\n    --context shell/g' "$file"
    
    # Remplacer test_from_file par test_session_sync
    sed -i '' 's/test_from_file "\([^"]*\)" "\([^"]*\)" "\([^"]*\)"/test_session_sync "\1" \\\n    --step "cat \2" \\\n    --expect "\3" \\\n    --context shell/g' "$file"
    
    # Remplacer test_error_pattern par test_session_sync
    sed -i '' 's/test_error_pattern "\([^"]*\)" \([^"]*\) "\([^"]*\)"/test_session_sync "\1" \\\n    --step \2 \\\n    --expect "\3" \\\n    --context monitor --output-check error/g' "$file"
    
    # Remplacer test_combined_commands par test_session_sync
    sed -i '' 's/test_combined_commands "\([^"]*\)" \([^"]*\) \([^"]*\) \([^"]*\) "\([^"]*\)"/test_session_sync "\1" \\\n    --step \2 \\\n    --step \3 \\\n    --step \4 \\\n    --expect "\5" \\\n    --context monitor/g' "$file"
    
    # Remplacer test_monitor_expression par test_session_sync
    sed -i '' 's/test_monitor_expression "\([^"]*\)" \([^"]*\) "\([^"]*\)"/test_session_sync "\1" \\\n    --step \2 \\\n    --expect "\3" \\\n    --context monitor --output-check result/g' "$file"
    
    # Remplacer test_monitor_error par test_session_sync
    sed -i '' 's/test_monitor_error "\([^"]*\)" \([^"]*\) "\([^"]*\)"/test_session_sync "\1" \\\n    --step \2 \\\n    --expect "\3" \\\n    --context monitor --output-check error/g' "$file"
    
    # Remplacer test_monitor_multiline par test_session_sync
    sed -i '' 's/test_monitor_multiline "\([^"]*\)" \([^"]*\) "\([^"]*\)"/test_session_sync "\1" \\\n    --step \2 \\\n    --expect "\3" \\\n    --context monitor --input-type multiline/g' "$file"
    
    # Remplacer test_shell_responsiveness par test_session_sync
    sed -i '' 's/test_shell_responsiveness "\([^"]*\)" \([^"]*\) \([^"]*\) "\([^"]*\)"/test_session_sync "\1" \\\n    --step \2 \\\n    --expect "\4" \\\n    --context shell/g' "$file"
    
    # Corriger les options avec = vers format --option value
    sed -i '' 's/--context=/--context /g' "$file"
    sed -i '' 's/--output-check=/--output-check /g' "$file"
    sed -i '' 's/--input-type=/--input-type /g' "$file"
    sed -i '' 's/--retry=/--retry /g' "$file"
    sed -i '' 's/--timeout=/--timeout /g' "$file"
    sed -i '' 's/--debug=/--debug /g' "$file"
    sed -i '' 's/--sync-test=/--sync-test /g' "$file"
    
    echo -e "${GREEN}✅ $basename corrigé${NC}"
}

# Compter les fichiers
total_files=0
fixed_files=0

# Trouver tous les fichiers de test et les corriger
find ./test/shell/Command -name "*.sh" -type f | while read -r file; do
    basename=$(basename "$file")
    
    # Ignorer les fichiers déjà corrigés
    if grep -q "test_session_sync" "$file" && ! grep -q "test_execute\|test_monitor\|test_phpunit\|test_shell\|test_from_file\|test_error_pattern\|test_combined_commands" "$file"; then
        echo -e "${YELLOW}⏭️  Skipping $basename (already corrected)${NC}"
        continue
    fi
    
    fix_test_file "$file"
    ((fixed_files++))
done

echo ""
echo -e "${GREEN}🎉 Correction terminée!${NC}"
echo -e "${CYAN}💡 $fixed_files fichiers ont été corrigés${NC}"
