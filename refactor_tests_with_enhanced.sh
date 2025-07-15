#!/bin/bash

# Script pour refactoriser tous les tests avec test_session_sync_enhanced
# Utilise les options intelligemment selon le contexte

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMMAND_DIR="$SCRIPT_DIR/test/shell/Command"
BACKUP_DIR="$SCRIPT_DIR/test_backups_$(date +%Y%m%d_%H%M%S)"

# Créer un backup
echo "Création du backup dans $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp -r "$COMMAND_DIR" "$BACKUP_DIR/"

# Fonction pour analyser le contenu d'un test et déterminer le contexte approprié
analyze_test_context() {
    local file="$1"
    
    # Compter les différents types de tests
    local monitor_count=$(grep -c "test_monitor\|monitor " "$file" 2>/dev/null || echo 0)
    local phpunit_count=$(grep -c "test_phpunit\|phpunit:" "$file" 2>/dev/null || echo 0)
    local shell_count=$(grep -c "test_shell\|shell_" "$file" 2>/dev/null || echo 0)
    local error_count=$(grep -c "test_.*_error\|error" "$file" 2>/dev/null || echo 0)
    local sync_count=$(grep -c "test_.*_sync\|sync\|responsiveness" "$file" 2>/dev/null || echo 0)
    
    echo "monitor:$monitor_count,phpunit:$phpunit_count,shell:$shell_count,error:$error_count,sync:$sync_count"
}

# Fonction pour déterminer les options appropriées selon le fichier
get_test_options() {
    local file="$1"
    local context_info="$2"
    local options=""
    
    # Analyse pour choisir les options appropriées
    if [[ $context_info == *"error:"* ]]; then
        options="--context monitor --input-type multiline --output-check error --timeout 30 --retry 2"
    elif [[ $context_info == *"sync:"* ]]; then
        options="--context monitor --input-type multiline --output-check contains --timeout 60 --sync-test"
    elif [[ $context_info == *"phpunit:"* ]]; then
        options="--context phpunit --input-type interactive --output-check contains --timeout 60"
    else
        options="--context monitor --input-type multiline --output-check contains --timeout 30"
    fi
    
    echo "$options"
}

# Fonction pour refactoriser un fichier de test
refactor_test_file() {
    local file="$1"
    local temp_file=$(mktemp)
    
    echo "Refactorisation de $file..."
    
    # Lire le fichier et générer la nouvelle version
    {
        echo "#!/bin/bash"
        echo ""
        echo "# Test refactorisé avec test_session_sync_enhanced"
        echo "# $(grep "^# Test" "$file" | head -1 | sed 's/^# //')"
        echo ""
        echo "# Obtenir le répertoire du script et charger les fonctions"
        echo "SCRIPT_DIR=\"\$( cd \"\$( dirname \"\${BASH_SOURCE[0]}\" )\" && pwd )\""
        echo "source \"\$SCRIPT_DIR/../../lib/func/loader.sh\""
        echo ""
        echo "init_test_environment"
        
        # Extraire le nom du test
        local test_name=$(grep "^init_test\|^# Test" "$file" | head -1 | sed 's/.*"\(.*\)".*/\1/' | sed 's/^# Test[^:]*: //')
        if [[ -z "$test_name" ]]; then
            test_name=$(basename "$file" .sh | sed 's/_/ /g' | sed 's/^[0-9]*[_ ]*//')
        fi
        
        echo "init_test \"$test_name\""
        echo ""
        
        # Analyser le contexte
        local context_info=$(analyze_test_context "$file")
        local base_options=$(get_test_options "$file" "$context_info")
        
        echo "# Configuration des options par défaut"
        echo "# $context_info"
        echo ""
        
        # Extraire et convertir les tests existants
        local step_count=1
        
        # Rechercher les patterns de test existants
        grep -n "test_monitor\|test_phpunit\|test_shell" "$file" | while IFS=: read -r line_num line_content; do
            # Extraire les paramètres du test
            local description=""
            local command=""
            local expected=""
            
            # Parser selon le type de test
            if [[ "$line_content" == *"test_monitor_multiline"* ]]; then
                # Extraire description, command et expected des lignes suivantes
                description=$(echo "$line_content" | sed "s/.*test_monitor_multiline \"\([^\"]*\)\".*/\1/")
                
                # Lire les lignes suivantes pour command et expected
                local next_lines=$(sed -n "${line_num},$((line_num+10))p" "$file" | tail -n +2)
                command=$(echo "$next_lines" | sed -n "1,/^'/p" | sed "s/^'//; s/'$//" | tr '\n' ' ')
                expected=$(echo "$next_lines" | sed -n "/^'.*'$/p" | tail -1 | sed "s/^'//; s/'$//")
                
                # Générer le test refactorisé
                echo "# Étape $step_count: $description"
                echo "test_session_sync \"$description\" \\"
                echo "    $base_options \\"
                echo "    --step \"$command\" \\"
                echo "    --expect \"$expected\""
                echo ""
                
            elif [[ "$line_content" == *"test_monitor_expression"* ]]; then
                # Parser expression simple
                description=$(echo "$line_content" | sed "s/.*test_monitor_expression \"\([^\"]*\)\".*/\1/")
                command=$(echo "$line_content" | sed "s/.*test_monitor_expression \"[^\"]*\" '\([^']*\)'.*/\1/")
                expected=$(echo "$line_content" | sed "s/.*test_monitor_expression \"[^\"]*\" '[^']*' '\([^']*\)'.*/\1/")
                
                echo "# Étape $step_count: $description"
                echo "test_session_sync \"$description\" \\"
                echo "    $base_options \\"
                echo "    --step \"$command\" \\"
                echo "    --expect \"$expected\""
                echo ""
                
            elif [[ "$line_content" == *"test_monitor_error"* ]]; then
                # Parser test d'erreur
                description=$(echo "$line_content" | sed "s/.*test_monitor_error \"\([^\"]*\)\".*/\1/")
                command=$(echo "$line_content" | sed "s/.*test_monitor_error \"[^\"]*\" '\([^']*\)'.*/\1/")
                expected=$(echo "$line_content" | sed "s/.*test_monitor_error \"[^\"]*\" '[^']*' '\([^']*\)'.*/\1/")
                
                echo "# Étape $step_count: $description"
                echo "test_session_sync \"$description\" \\"
                echo "    --context monitor --input-type multiline --output-check error --timeout 30 \\"
                echo "    --step \"$command\" \\"
                echo "    --expect \"$expected\""
                echo ""
                
            elif [[ "$line_content" == *"test_shell_responsiveness"* ]]; then
                # Parser test de synchronisation
                description=$(echo "$line_content" | sed "s/.*test_shell_responsiveness \"\([^\"]*\)\".*/\1/")
                
                echo "# Étape $step_count: $description"
                echo "test_session_sync \"$description\" \\"
                echo "    --context monitor --input-type multiline --output-check contains --timeout 60 --sync-test \\"
                
                # Extraire les étapes multiples
                local setup_cmd=$(sed -n "$((line_num+1))p" "$file" | sed "s/^'//; s/'.*$//")
                local verify_cmd=$(sed -n "$((line_num+2))p" "$file" | sed "s/^'//; s/'.*$//")
                local expected_result=$(sed -n "$((line_num+3))p" "$file" | sed "s/^'//; s/'.*$//")
                
                echo "    --step \"$setup_cmd\" \\"
                echo "    --step \"$verify_cmd\" \\"
                echo "    --expect \"$expected_result\""
                echo ""
            fi
            
            ((step_count++))
        done
        
        echo ""
        echo "# Afficher le résumé"
        echo "test_summary"
        echo ""
        echo "# Nettoyer l'environnement de test"
        echo "cleanup_test_environment"
        echo ""
        echo "# Sortir avec le code approprié"
        echo "if [[ \$FAIL_COUNT -gt 0 ]]; then"
        echo "    exit 1"
        echo "else"
        echo "    exit 0"
        echo "fi"
        
    } > "$temp_file"
    
    # Remplacer le fichier original
    mv "$temp_file" "$file"
    chmod +x "$file"
}

# Fonction principale
refactor_all_tests() {
    echo "Début de la refactorisation des tests..."
    
    # Trouver tous les fichiers de test
    find "$COMMAND_DIR" -name "*.sh" -type f | while read -r file; do
        # Ignorer les fichiers qui utilisent déjà test_session_sync_enhanced
        if ! grep -q "test_session_sync" "$file"; then
            refactor_test_file "$file"
        else
            echo "Skipping $file (already uses test_session_sync)"
        fi
    done
    
    echo "Refactorisation terminée!"
    echo "Backup créé dans: $BACKUP_DIR"
}

# Exécuter la refactorisation
refactor_all_tests

