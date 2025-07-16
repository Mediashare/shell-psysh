#!/bin/bash

# Script intelligent pour refactoriser tous les tests avec test_session_sync_enhanced
# Utilise des techniques d'analyse intelligente du code

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMMAND_DIR="$SCRIPT_DIR/test/shell/Command"
BACKUP_DIR="$SCRIPT_DIR/test_backups_$(date +%Y%m%d_%H%M%S)"

# Créer un backup
echo "🔄 Création du backup dans $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp -r "$COMMAND_DIR" "$BACKUP_DIR/"

# Fonctions utilitaires pour l'analyse
get_test_context_from_filename() {
    local filename="$1"
    local basename=$(basename "$filename" .sh)
    
    case "$basename" in
        *"error"*|*"08_"*|*"15_"*|*"22_"*) echo "error" ;;
        *"sync"*|*"responsiveness"*|*"23_"*|*"24_"*|*"25_"*) echo "sync" ;;
        *"performance"*|*"stress"*|*"05_"*|*"14_"*|*"20_"*) echo "performance" ;;
        *"phpunit"*|*"30_"*|*"31_"*|*"32_"*|*"33_"*|*"34_"*|*"35_"*) echo "phpunit" ;;
        *"memory"*|*"09_"*) echo "memory" ;;
        *"debug"*|*"07_"*) echo "debug" ;;
        *"realtime"*|*"06_"*) echo "realtime" ;;
        *"multiline"*|*"10_"*) echo "multiline" ;;
        *) echo "normal" ;;
    esac
}

get_options_for_context() {
    local context="$1"
    case "$context" in
        "error")
            echo "--context monitor --input-type multiline --output-check error --timeout 30 --retry 2"
            ;;
        "sync")
            echo "--context monitor --input-type multiline --output-check contains --timeout 60 --sync-test"
            ;;
        "performance")
            echo "--context monitor --input-type multiline --output-check contains --timeout 120 --benchmark"
            ;;
        "phpunit")
            echo "--context phpunit --input-type interactive --output-check contains --timeout 60"
            ;;
        "memory")
            echo "--context monitor --input-type multiline --output-check contains --timeout 60 --memory-check"
            ;;
        "debug")
            echo "--context monitor --input-type multiline --output-check contains --timeout 30 --debug"
            ;;
        "realtime")
            echo "--context monitor --input-type pipe --output-check contains --timeout 45"
            ;;
        "multiline")
            echo "--context monitor --input-type multiline --output-check contains --timeout 45"
            ;;
        *)
            echo "--context monitor --input-type multiline --output-check contains --timeout 30"
            ;;
    esac
}

# Fonction pour extraire les tests d'un fichier
extract_tests_from_file() {
    local file="$1"
    local temp_tests=$(mktemp)
    
    # Extraire les tests avec leurs lignes
    grep -n "test_monitor\|test_phpunit\|test_shell" "$file" > "$temp_tests" 2>/dev/null || true
    
    echo "$temp_tests"
}

# Fonction pour parser un test spécifique
parse_test() {
    local file="$1"
    local line_num="$2"
    local line_content="$3"
    
    local description=""
    local command=""
    local expected=""
    local test_type=""
    
    # Identifier le type de test
    if [[ "$line_content" == *"test_monitor_multiline"* ]]; then
        test_type="multiline"
        description=$(echo "$line_content" | sed -n 's/.*test_monitor_multiline "\([^"]*\)".*/\1/p')
    elif [[ "$line_content" == *"test_monitor_expression"* ]]; then
        test_type="expression"
        description=$(echo "$line_content" | sed -n 's/.*test_monitor_expression "\([^"]*\)".*/\1/p')
        command=$(echo "$line_content" | sed -n "s/.*test_monitor_expression \"[^\"]*\" '\([^']*\)'.*/\1/p")
        expected=$(echo "$line_content" | sed -n "s/.*test_monitor_expression \"[^\"]*\" '[^']*' '\([^']*\)'.*/\1/p")
    elif [[ "$line_content" == *"test_monitor_error"* ]]; then
        test_type="error"
        description=$(echo "$line_content" | sed -n 's/.*test_monitor_error "\([^"]*\)".*/\1/p')
        command=$(echo "$line_content" | sed -n "s/.*test_monitor_error \"[^\"]*\" '\([^']*\)'.*/\1/p")
        expected=$(echo "$line_content" | sed -n "s/.*test_monitor_error \"[^\"]*\" '[^']*' '\([^']*\)'.*/\1/p")
    elif [[ "$line_content" == *"test_shell_responsiveness"* ]]; then
        test_type="responsiveness"
        description=$(echo "$line_content" | sed -n 's/.*test_shell_responsiveness "\([^"]*\)".*/\1/p')
    fi
    
    # Pour les tests multiline, extraire les lignes suivantes
    if [[ "$test_type" == "multiline" ]]; then
        # Lire les lignes suivantes jusqu'à trouver le pattern complet
        local start_line=$((line_num + 1))
        local end_line=$((line_num + 20))
        
        # Extraire le bloc de commande (entre les premiers quotes)
        command=$(sed -n "${start_line},${end_line}p" "$file" | \
                  sed -n "/^'/,/^'.*\\\\$/p" | \
                  sed "s/^'//; s/'.*\\\\$//" | \
                  tr '\n' ' ' | \
                  sed 's/[[:space:]]*$//')
        
        # Extraire la valeur attendue (dernière ligne avec quotes)
        expected=$(sed -n "${start_line},${end_line}p" "$file" | \
                   grep "^'[^']*'$" | \
                   tail -1 | \
                   sed "s/^'//; s/'$//")
    fi
    
    # Pour les tests responsiveness, extraire les étapes multiples
    if [[ "$test_type" == "responsiveness" ]]; then
        local start_line=$((line_num + 1))
        local setup_cmd=$(sed -n "${start_line}p" "$file" | sed "s/^'//; s/'.*$//")
        local verify_cmd=$(sed -n "$((start_line + 1))p" "$file" | sed "s/^'//; s/'.*$//")
        local expected_result=$(sed -n "$((start_line + 2))p" "$file" | sed "s/^'//; s/'.*$//")
        
        command="$setup_cmd|$verify_cmd"
        expected="$expected_result"
    fi
    
    echo "$test_type|$description|$command|$expected"
}

# Fonction pour refactoriser un fichier
refactor_file() {
    local file="$1"
    local temp_file=$(mktemp)
    
    echo "🔄 Refactorisation de $(basename "$file")..."
    
    # Déterminer le contexte et les options
    local context=$(get_test_context_from_filename "$file")
    local base_options=$(get_options_for_context "$context")
    
    # Extraire le nom du test
    local test_name=$(grep -E "^init_test|^# Test" "$file" | head -1 | sed 's/.*"\([^"]*\)".*/\1/' | sed 's/^# Test[^:]*: //')
    if [[ -z "$test_name" ]]; then
        test_name=$(basename "$file" .sh | sed 's/_/ /g' | sed 's/^[0-9]*[_ ]*//')
    fi
    
    # Générer le header
    {
        echo "#!/bin/bash"
        echo ""
        echo "# Test refactorisé avec test_session_sync_enhanced"
        echo "# $test_name"
        echo ""
        echo "# Obtenir le répertoire du script et charger les fonctions"
        echo "SCRIPT_DIR=\"\$( cd \"\$( dirname \"\${BASH_SOURCE[0]}\" )\" && pwd )\""
        echo "source \"\$SCRIPT_DIR/../../lib/func/loader.sh\""
        echo ""
        echo "# Initialiser l'environnement de test"
        echo "init_test_environment"
        echo "init_test \"$test_name\""
        echo ""
    } > "$temp_file"
    
    # Extraire et grouper les tests
    local tests_file=$(extract_tests_from_file "$file")
    
    if [[ -s "$tests_file" ]]; then
        # Grouper les tests par contexte similaire
        local current_group=""
        local group_tests=()
        local group_count=1
        
        while IFS=: read -r line_num line_content; do
            local test_info=$(parse_test "$file" "$line_num" "$line_content")
            local test_type=$(echo "$test_info" | cut -d'|' -f1)
            local description=$(echo "$test_info" | cut -d'|' -f2)
            local command=$(echo "$test_info" | cut -d'|' -f3)
            local expected=$(echo "$test_info" | cut -d'|' -f4)
            
            # Échapper les caractères spéciaux
            command=$(echo "$command" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
            expected=$(echo "$expected" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
            
            # Déterminer le groupe (par type ou par contexte)
            local group_name=""
            case "$test_type" in
                "error") group_name="Gestion des erreurs" ;;
                "responsiveness") group_name="Synchronisation" ;;
                "expression"|"multiline") group_name="Tests fonctionnels" ;;
                *) group_name="Tests généraux" ;;
            esac
            
            # Si le groupe change, écrire le groupe précédent
            if [[ "$current_group" != "$group_name" && ${#group_tests[@]} -gt 0 ]]; then
                write_test_group "$temp_file" "$current_group" "${group_tests[@]}"
                group_tests=()
                ((group_count++))
            fi
            
            current_group="$group_name"
            
            # Ajouter au groupe actuel
            if [[ "$test_type" == "responsiveness" ]]; then
                # Gérer les tests de synchronisation avec étapes multiples
                local setup_cmd=$(echo "$command" | cut -d'|' -f1)
                local verify_cmd=$(echo "$command" | cut -d'|' -f2)
                group_tests+=("$description|$setup_cmd|$verify_cmd|$expected|sync")
            else
                group_tests+=("$description|$command|$expected|$test_type")
            fi
            
        done < "$tests_file"
        
        # Écrire le dernier groupe
        if [[ ${#group_tests[@]} -gt 0 ]]; then
            write_test_group "$temp_file" "$current_group" "${group_tests[@]}"
        fi
    fi
    
    # Ajouter le footer
    {
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
    } >> "$temp_file"
    
    # Remplacer le fichier original
    mv "$temp_file" "$file"
    chmod +x "$file"
    
    rm -f "$tests_file"
}

# Fonction pour écrire un groupe de tests
write_test_group() {
    local file="$1"
    local group_name="$2"
    shift 2
    local tests=("$@")
    
    # Déterminer les options selon le groupe
    local options=""
    case "$group_name" in
        "Gestion des erreurs")
            options="--context monitor --input-type multiline --output-check error --timeout 30 --retry 2"
            ;;
        "Synchronisation")
            options="--context monitor --input-type multiline --output-check contains --timeout 60 --sync-test"
            ;;
        *)
            options="--context monitor --input-type multiline --output-check contains --timeout 30"
            ;;
    esac
    
    {
        echo "# $group_name"
        echo "test_session_sync \"$group_name\" \\"
        echo "    $options \\"
        
        for test in "${tests[@]}"; do
            local description=$(echo "$test" | cut -d'|' -f1)
            local command=$(echo "$test" | cut -d'|' -f2)
            local expected=$(echo "$test" | cut -d'|' -f3)
            local test_type=$(echo "$test" | cut -d'|' -f4)
            
            if [[ "$test_type" == "sync" ]]; then
                # Test de synchronisation avec étapes multiples
                local verify_cmd=$(echo "$test" | cut -d'|' -f3)
                echo "    --step \"$command\" \\"
                echo "    --step \"$verify_cmd\" \\"
                echo "    --expect \"$expected\" \\"
            else
                echo "    --step \"$command\" \\"
                echo "    --expect \"$expected\" \\"
            fi
        done
        
        # Supprimer le dernier backslash
        echo ""
    } >> "$file"
    
    # Nettoyer le dernier backslash
    sed -i '' 's/\\$//g' "$file"
}

# Fonction principale
main() {
    echo "🚀 Début de la refactorisation intelligente des tests..."
    
    # Trouver tous les fichiers .sh dans Command
    find "$COMMAND_DIR" -name "*.sh" -type f | sort | while read -r file; do
        # Ignorer les fichiers déjà refactorisés
        if ! grep -q "test_session_sync" "$file"; then
            refactor_file "$file"
        else
            echo "⏭️  Skipping $(basename "$file") (already refactored)"
        fi
    done
    
    echo "✅ Refactorisation terminée!"
    echo "📂 Backup créé dans: $BACKUP_DIR"
    echo ""
    echo "📊 Statistiques:"
    echo "   - Tests totaux: $(find "$COMMAND_DIR" -name "*.sh" | wc -l)"
    echo "   - Tests refactorisés: $(find "$COMMAND_DIR" -name "*.sh" -exec grep -l "test_session_sync" {} \; | wc -l)"
}

# Exécuter le script
main "$@"
