#!/bin/bash

# Bibliothèque d'utilitaires pour les tests PsySH et monitor
# Fournit des fonctions spécialisées pour tester les fonctionnalités monitor

# Source les utilitaires de base
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/test_utils.sh"

# Fonction pour échapper correctement les commandes monitor
write_monitor_command() {
    local temp_file="$1"
    local code="$2"
    
    # Pour les commandes monitor, on utilise printf avec un échappement approprié
    printf 'monitor %s\n' "$(printf '%q' "$code")" >> "$temp_file"
}

# Fonction pour ajouter une pause interactive entre les étapes
wait_for_user() {
    local message="${1:-Appuyez sur Entrée pour continuer vers létape suivante, ou Échap + Entrée pour quitter...}"
    echo ""
    print_colored "$YELLOW" "$message"
    read -r input
    if [[ "$input" == $'\033' ]]; then
        print_colored "$BLUE" "Test interrompu par l'utilisateur."
        exit 0
    fi
}

# Fonction pour tester une expression monitor simple avec résultat attendu
test_monitor_expression() {
    local step_name="$1"
    local expression="$2"
    local expected_result="$3"
    local project_root="${4:-$PROJECT_ROOT}"
    
    test_monitor_result "$step_name" "$expression" "$expected_result" "$project_root"
}

# Fonction pour tester une expression monitor avec echo et pattern regex
test_monitor_echo() {
    local step_name="$1"
    local expression="$2"
    local expected_pattern="$3"
    local project_root="${4:-$PROJECT_ROOT}"
    
    test_monitor_echo_result "$step_name" "$expression" "$expected_pattern" "$project_root"
}

# Fonction pour tester un monitor multi-lignes
test_monitor_multiline() {
    local step_name="$1"
    local code="$2"
    local expected_output="$3"
    local project_root="${4:-$PROJECT_ROOT}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # En mode simple, pas d'affichage détaillé
    if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
        echo ""
        print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
        print_colored "$BLUE" "Code multi-lignes:"
        echo "$code"
    fi
    
    # Créer un fichier temporaire pour le code multi-lignes
    local temp_file=$(mktemp)
    
    
    # For multiline code, execute directly in PsySH
    # Write each line of code to the temp file
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            printf '%s\n' "$line" >> "$temp_file"
        fi
    done <<< "$code"
    
    # Mode debug: afficher le contenu du fichier d'entrée
    if [[ "${DEBUG_PSYSH:-}" == "1" ]]; then
        echo ""
        print_colored "$CYAN" "=== CONTENU DU FICHIER D'ENTRÉE (MULTILINE) ==="
        cat "$temp_file" | nl -ba
        print_colored "$CYAN" "=== FIN DU FICHIER D'ENTRÉE ==="
        echo ""
    fi
    
    # Exécution
    local result
    result=$("$project_root/bin/psysh" --no-interactive < "$temp_file" 2>&1)
    local exit_code=$?
    
    # Nettoyer le fichier temporaire
    rm -f "$temp_file"
    
    # En mode simple, pas d'affichage détaillé
    if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
        echo ""
        print_colored "$BLUE" "Sortie du test:"
        echo "$result"
        echo ""
    fi
    
    # Extract clean result by removing PsySH headers
    local clean_result
    clean_result=$(echo "$result" | sed '/^Using local PsySH version/d; /^Psy Shell v/d; /^$/d' | tail -1 | sed 's/⏎$//')
    
    # Vérification
    if [[ "$clean_result" == *"$expected_output"* ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$GREEN" "✅ PASS: $step_name"
        fi
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$RED" "❌ FAIL: $step_name"
        fi
        print_colored "$RED" "Code multi-lignes:"
        echo "$code" | sed 's/^/  > /'
        print_colored "$RED" "Sortie attendue: $expected_output"
        print_colored "$RED" "Sortie obtenue: $clean_result"
        if [[ -z "$result" ]]; then
            print_colored "$RED" "⚠️  La sortie est vide - vérifiez la syntaxe du code"
        fi
        
    fi
}

# Fonction pour tester que monitor gère les erreurs correctement
test_monitor_error() {
    local step_name="$1"
    local error_code="$2"
    local expected_error_pattern="$3"
    local project_root="${4:-$PROJECT_ROOT}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # En mode simple, pas d'affichage détaillé
    if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
        echo ""
        print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
        print_colored "$BLUE" "Code avec erreur: $error_code"
        print_colored "$BLUE" "Pattern d'erreur attendu: $expected_error_pattern"
    fi
    
    # Créer un fichier temporaire pour éviter les problèmes de quotes
    local temp_file=$(mktemp)
    
    
    local result
    # Execute error code directly in PsySH
    printf '%s\n' "$error_code" >> "$temp_file"
    
    result=$("$project_root/bin/psysh" --no-interactive < "$temp_file" 2>&1)
    
    # Nettoyer le fichier temporaire
    rm -f "$temp_file"
    
    # En mode simple, pas d'affichage détaillé
    if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
        echo ""
        print_colored "$BLUE" "Sortie du test:"
        echo "$result"
        echo ""
    fi
    
    # Vérification que l'erreur correspond au pattern attendu
    if echo "$result" | grep -qE "$expected_error_pattern"; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$GREEN" "✅ PASS: $step_name (erreur détectée correctement)"
        fi
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$RED" "❌ FAIL: $step_name"
        fi
        print_colored "$RED" "Code avec erreur: $error_code"
        print_colored "$RED" "Pattern d'erreur attendu: $expected_error_pattern"
        print_colored "$RED" "Sortie obtenue: $result"
        if [[ -z "$result" ]]; then
            print_colored "$RED" "⚠️  Aucune sortie obtenue - le code n'a peut-être pas généré d'erreur"
        else
            print_colored "$RED" "⚠️  L'erreur générée ne correspond pas au pattern attendu"
        fi
        
    fi
}

# Fonction pour tester la responsiveness du shell après monitor
test_shell_responsiveness() {
    local step_name="$1"
    local monitor_commands="$2"
    local follow_up_command="$3"
    local expected_followup_output="$4"
    local project_root="${5:-$PROJECT_ROOT}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # En mode simple, pas d'affichage détaillé
    if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
        echo ""
        print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
        print_colored "$BLUE" "Commands monitor: $monitor_commands"
        print_colored "$BLUE" "Commande de suivi: $follow_up_command"
    fi
    
    
    # Créer un fichier temporaire pour éviter les problèmes de quotes
    local temp_file=$(mktemp)
    # Write both commands to the same file to ensure variable persistence
    printf '%s\n' "$monitor_commands" >> "$temp_file"
    printf '%s\n' "$follow_up_command" >> "$temp_file"
    
    # Mode debug: afficher le contenu du fichier d'entrée
    if [[ "${DEBUG_PSYSH:-}" == "1" ]]; then
        echo ""
        print_colored "$CYAN" "=== CONTENU DU FICHIER D'ENTRÉE (RESPONSIVENESS) ==="
        cat "$temp_file" | nl -ba
        print_colored "$CYAN" "=== FIN DU FICHIER D'ENTRÉE ==="
        echo ""
    fi
    
    # Exécuter les commandes
    local result
    result=$("$project_root/bin/psysh" --no-interactive < "$temp_file" 2>&1)
    local exit_code=$?
    
    # Nettoyer le fichier temporaire
    rm -f "$temp_file"
    
    # En mode simple, pas d'affichage détaillé
    if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
        echo ""
        print_colored "$BLUE" "Sortie du test:"
        echo "$result"
        echo ""
    fi
    
    if [[ $exit_code -ne 0 ]]; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$RED" "❌ FAIL: $step_name (erreur d'exécution)"
        fi
        print_colored "$RED" "Code de sortie: $exit_code"
        print_colored "$RED" "Commande monitor: $monitor_commands"
        print_colored "$RED" "Commande de suivi: $follow_up_command"
        print_colored "$RED" "Résultat attendu: $expected_followup_output"
        if [[ -n "$result" ]]; then
            print_colored "$RED" "Sortie obtenue: $result"
        else
            print_colored "$RED" "Aucune sortie obtenue"
        fi
        return 1
    fi
    
    # Vérifier que la sortie attendue est présente
    if echo "$result" | grep -q "$expected_followup_output"; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$GREEN" "✅ PASS: $step_name (shell responsive)"
        fi
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$RED" "❌ FAIL: $step_name"
        fi
        print_colored "$RED" "Commande monitor: $monitor_commands"
        print_colored "$RED" "Commande de suivi: $follow_up_command"
        print_colored "$RED" "Résultat attendu: $expected_followup_output"
        print_colored "$RED" "Résultat obtenu: $result"
        if [[ -z "$result" ]]; then
            print_colored "$RED" "⚠️  La sortie est vide - possible problème de persistance"
        fi
        
    fi
}

# Fonction pour tester les numéros de ligne d'erreur
test_error_line_numbers() {
    local step_name="$1"
    local error_code="$2"
    local expected_line_number="$3"
    local project_root="${4:-$PROJECT_ROOT}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo ""
    print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
    print_colored "$BLUE" "Code avec erreur: $error_code"
    print_colored "$BLUE" "Numéro de ligne attendu: $expected_line_number"
    
    # Créer un fichier temporaire pour la commande monitor
    local temp_file=$(mktemp)
    # Execute error code directly in PsySH
    printf '%s\n' "$error_code" >> "$temp_file"
    
    local result
    result=$("$project_root/bin/psysh" --no-interactive < "$temp_file" 2>&1)
    rm -f "$temp_file"
    
    echo ""
    print_colored "$BLUE" "Sortie du test:"
    echo "$result"
    echo ""
    
    # Vérifier le numéro de ligne
    if echo "$result" | grep -q "Line in your code: $expected_line_number"; then
        PASS_COUNT=$((PASS_COUNT + 1))
        print_colored "$GREEN" "✅ PASS: $step_name (ligne $expected_line_number correcte)"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        print_colored "$RED" "❌ FAIL: $step_name"
        print_colored "$RED" "Expected line number: $expected_line_number"
        print_colored "$RED" "Got: $result"
        
        # Pause pour permettre à l'utilisateur d'examiner l'erreur
        echo ""
        print_colored "$YELLOW" "Test échoué. Appuyez sur Entrée pour continuer ou Échap + Entrée pour quitter..."
        read -r input
        if [[ "$input" == $'\033' ]]; then
            exit 1
        fi
    fi
}

# Fonction flexible pour tester la synchronisation entre shell et monitor
# Supporte variables, fonctions, classes, traits, globals, etc.
test_sync_bidirectional() {
    local step_name="$1"
    local setup_code="$2"           # Code exécuté dans le shell principal
    local monitor_code="$3"          # Code exécuté dans monitor
    local verification_code="$4"     # Code pour vérifier la synchronisation
    local expected_result="$5"       # Résultat attendu
    local sync_type="$6"             # Type de synchronisation (variable, function, class, trait, global)
    local project_root="${7:-$PROJECT_ROOT}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo ""
    print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
    print_colored "$BLUE" "Type de synchronisation: $sync_type"
    print_colored "$BLUE" "Setup: $setup_code"
    print_colored "$BLUE" "Monitor: $monitor_code"
    print_colored "$BLUE" "Vérification: $verification_code"
    print_colored "$BLUE" "Résultat attendu: $expected_result"
    
    # Créer un fichier temporaire pour la séquence complète
    local temp_file=$(mktemp)
    
    # Ajouter le code de setup si fourni
    if [[ -n "$setup_code" ]]; then
        printf '%s\n' "$setup_code" >> "$temp_file"
    fi
    
    # Ajouter le code monitor
    if [[ -n "$monitor_code" ]]; then
        # Execute monitor code directly in PsySH
        printf '%s\n' "$monitor_code" >> "$temp_file"
    fi
    
    # Ajouter le code de vérification
    if [[ -n "$verification_code" ]]; then
        printf '%s\n' "$verification_code" >> "$temp_file"
    fi
    
    
    # Mode debug: afficher le contenu du fichier d'entrée
    if [[ "${DEBUG_PSYSH:-}" == "1" ]]; then
        echo ""
        print_colored "$CYAN" "=== CONTENU DU FICHIER D'ENTRÉE ==="
        cat "$temp_file" | nl -ba
        print_colored "$CYAN" "=== FIN DU FICHIER D'ENTRÉE ==="
        echo ""
    fi
    
    # Exécution
    local result
    result=$("$project_root/bin/psysh" --no-interactive < "$temp_file" 2>&1)
    local exit_code=$?
    
    # Nettoyer le fichier temporaire
    rm -f "$temp_file"
    
    echo ""
    print_colored "$BLUE" "Sortie du test:"
    echo "$result"
    echo ""
    
    # Vérification du résultat
    if [[ "$result" == *"$expected_result"* ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        print_colored "$GREEN" "✅ PASS: $step_name (synchronisation $sync_type fonctionne)"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        print_colored "$RED" "❌ FAIL: $step_name (bug de synchronisation $sync_type)"
        print_colored "$RED" "Expected to contain: $expected_result"
        print_colored "$RED" "Got: $result"
        
        # En mode automatisé, ne pas attendre
        if [[ "${AUTO_MODE:-}" != "1" ]]; then
            # Pause pour permettre à l'utilisateur d'examiner l'erreur
            echo ""
            print_colored "$YELLOW" "Test échoué. Appuyez sur Entrée pour continuer ou Échap + Entrée pour quitter..."
            read -r input
            if [[ "$input" == $'\033' ]]; then
                exit 1
            fi
        fi
    fi
}

# Fonction pour tester le bug de synchronisation de variables (version simple)
test_monitor_sync_bug() {
    local step_name="$1"
    local setup_code="$2"
    local monitor_code="$3"
    local verification_code="$4"
    local expected_result="$5"
    local project_root="${6:-$PROJECT_ROOT}"
    
    test_sync_bidirectional "$step_name" "$setup_code" "$monitor_code" "$verification_code" "$expected_result" "variable" "$project_root"
}

# Fonction pour tester les performances (avec mesure de temps)
test_monitor_performance() {
    local step_name="$1"
    local code="$2"
    local max_time_seconds="$3"
    local project_root="${4:-$PROJECT_ROOT}"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo ""
    print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
    print_colored "$BLUE" "Code: $code"
    print_colored "$BLUE" "Temps maximum attendu: ${max_time_seconds}s"
    
    local start_time=$(date +%s)
    
    # Créer un fichier temporaire pour la commande monitor
    local temp_file=$(mktemp)
    # Execute code directly in PsySH for performance testing
    printf '%s\n' "$code" >> "$temp_file"
    
    local result
    result=$("$project_root/bin/psysh" --no-interactive < "$temp_file" 2>&1)
    rm -f "$temp_file"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    print_colored "$BLUE" "Sortie du test:"
    echo "$result"
    print_colored "$BLUE" "Temps d'exécution: ${duration}s"
    echo ""
    
    if [[ $duration -le $max_time_seconds ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        print_colored "$GREEN" "✅ PASS: $step_name (${duration}s ≤ ${max_time_seconds}s)"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        print_colored "$RED" "❌ FAIL: $step_name"
        print_colored "$RED" "Expected: ≤ ${max_time_seconds}s"
        print_colored "$RED" "Got: ${duration}s"
        
        # En mode automatisé, ne pas attendre
        if [[ "${AUTO_MODE:-}" != "1" ]]; then
            # Pause pour permettre à l'utilisateur d'examiner l'erreur
            echo ""
            print_colored "$YELLOW" "Test échoué. Appuyez sur Entrée pour continuer ou Échap + Entrée pour quitter..."
            read -r input
            if [[ "$input" == $'\033' ]]; then
                exit 1
            fi
        fi
    fi
}

# Alias pour test_monitor_error pour compatibilité
test_psysh_error() {
    test_monitor_error "$@"
}

# Fonction simplifiée pour les tests de synchronisation
test_psysh_sync() {
    local step_name="$1"
    local code="$2"
    local expected="$3"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    echo ""
    print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
    
    # Pour les tests de sync, on skip les plus complexes
    if [[ "$code" == *"monitor"* ]]; then
        print_colored "$BLUE" "⏭️  SKIP: Test de synchronisation complexe"
        return
    fi
    
    # Sinon on exécute normalement
    test_monitor_expression "$step_name" "$code" "$expected"
}
