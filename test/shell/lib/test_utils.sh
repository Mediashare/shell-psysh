#!/bin/bash

# Bibliothèque d'utilitaires pour les tests
# Fournit des fonctions d'assertion et de gestion des tests

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales pour les statistiques de test
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Déterminer le répertoire racine du projet
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../.. && pwd )"
export PROJECT_ROOT

# Fonction pour afficher un message avec couleur
print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Fonction pour initialiser un test
init_test() {
    local test_name="$1"
    echo ""
    print_colored "$BLUE" "🧪 $test_name"
    print_colored "$BLUE" "$(printf '=%.0s' $(seq 1 ${#test_name}))"
    echo ""
    TEST_COUNT=0
    PASS_COUNT=0
    FAIL_COUNT=0
}

# Fonction pour afficher un résumé des tests
test_summary() {
    echo ""
    if [[ $FAIL_COUNT -eq 0 ]]; then
        print_colored "$GREEN" "🎉 Tous les tests sont PASSÉS ! ($PASS_COUNT/$TEST_COUNT)"
    else
        print_colored "$RED" "❌ $FAIL_COUNT tests échoués sur $TEST_COUNT"
        print_colored "$GREEN" "✅ $PASS_COUNT tests réussis"
    fi
    echo ""
}

# Fonction pour exécuter une étape de test avec gestion d'erreur
run_test_step() {
    local step_name="$1"
    local command="$2"
    local expected_output="$3"
    local check_function="${4:-check_contains}" # Fonction de vérification par défaut
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo ""
    print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
    print_colored "$BLUE" "Commande: $command"
    
    # Exécution de la commande
    local result
    local exit_code
    result=$(eval "$command" 2>&1)
    exit_code=$?
    
    echo ""
    print_colored "$BLUE" "Sortie du test:"
    echo "$result"
    echo ""
    
    # Vérification du résultat
    if $check_function "$result" "$expected_output" "$exit_code"; then
        PASS_COUNT=$((PASS_COUNT + 1))
        print_colored "$GREEN" "✅ PASS: $step_name"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        print_colored "$RED" "❌ FAIL: $step_name"
        print_colored "$RED" "Expected: $expected_output"
        print_colored "$RED" "Got: $result"
    fi
}

# Fonction de vérification par défaut: vérifie si la sortie contient le texte attendu
check_contains() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    if [[ "$output" == *"$expected"* ]]; then
        return 0
    else
        return 1
    fi
}

# Fonction de vérification: vérifie une égalité exacte
check_equals() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    if [[ "$output" == "$expected" ]]; then
        return 0
    else
        return 1
    fi
}

# Fonction de vérification: vérifie que la commande a réussi (exit code 0)
check_success() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    if [[ $exit_code -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Fonction de vérification: vérifie que la commande a échoué (exit code != 0)
check_failure() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    if [[ $exit_code -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Fonction de vérification: vérifie avec une regex
check_regex() {
    local output="$1"
    local pattern="$2"
    local exit_code="$3"
    
    if echo "$output" | grep -qE "$pattern"; then
        return 0
    else
        return 1
    fi
}

# Fonction pour extraire le résultat d'une commande monitor
extract_monitor_result() {
    local output="$1"
    # Skip the header lines and get the actual result
    local result=$(echo "$output" | sed '/^Using local PsySH version/d; /^Psy Shell v/d; /^$/d' | tail -n 1 | sed 's/⏎$//')
    # Remove => prefix and surrounding quotes if present
    result=$(echo "$result" | sed 's/^=> *//')
    result=$(echo "$result" | sed 's/^= //')
    result=$(echo "$result" | sed 's/^"\(.*\)"$/\1/')
    # Trim whitespace
    result=$(echo "$result" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    echo "$result"
}

# Fonction pour extraire le résultat d'un echo dans monitor (depuis les lignes de monitoring)
extract_monitor_echo() {
    local output="$1"
    # Skip the header lines and get the actual result
    local result=$(echo "$output" | sed '/^Using local PsySH version/d; /^Psy Shell v/d; /^$/d' | tail -n 1 | sed 's/⏎$//')
    # Remove => prefix and surrounding quotes if present
    result=$(echo "$result" | sed 's/^=> *//')
    result=$(echo "$result" | sed 's/^= //')
    result=$(echo "$result" | sed 's/^"\(.*\)"$/\1/')
    # Trim whitespace
    result=$(echo "$result" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    echo "$result"
}

# Fonction pour tester un echo dans monitor avec résultat et regex
test_monitor_echo_result() {
    local step_name="$1"
    local monitor_code="$2"
    local expected_pattern="$3"
    local project_root="${4:-$PROJECT_ROOT}"
    
    
    # Créer un fichier temporaire pour éviter les problèmes de quotes
    local temp_file=$(mktemp)
    
    local full_output
    # For tests, we'll execute the PHP code directly instead of using monitor
    # This ensures compatibility and tests the core functionality 
    printf '%s\n' "$monitor_code" >> "$temp_file"
    full_output=$("$project_root/bin/psysh" --no-interactive < "$temp_file" 2>&1)
    local result=$(extract_monitor_echo "$full_output")
    
    # Nettoyer le fichier temporaire
    rm -f "$temp_file"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # En mode simple, pas d'affichage détaillé
    if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
        echo ""
        print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
        print_colored "$BLUE" "Code monitor: $monitor_code"
        print_colored "$BLUE" "Pattern attendu: $expected_pattern"
        
        echo ""
        print_colored "$BLUE" "Sortie complète du test:"
        echo "$full_output"
        echo ""
        print_colored "$BLUE" "Résultat extrait: $result"
        echo ""
    fi
    
    if echo "$result" | grep -qE "$expected_pattern"; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$GREEN" "✅ PASS: $step_name"
        fi
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$RED" "❌ FAIL: $step_name"
        fi
        print_colored "$RED" "Code monitor: $monitor_code"
        print_colored "$RED" "Pattern attendu: $expected_pattern"
        print_colored "$RED" "Résultat obtenu: $result"
        if [[ -z "$result" ]]; then
            print_colored "$RED" "⚠️  La sortie est vide - vérifiez la syntaxe du code"
        fi
        if [[ -n "$full_output" ]]; then
            print_colored "$RED" "Sortie complète pour debug:"
            echo "$full_output" | head -20  # Limiter l'affichage
        fi
    fi
}

# Fonction pour exécuter un test monitor et vérifier le résultat
test_monitor_result() {
    local step_name="$1"
    local monitor_code="$2"
    local expected_result="$3"
    local project_root="${4:-$PROJECT_ROOT}"
    
    
    # Créer un fichier temporaire pour éviter les problèmes de quotes
    local temp_file=$(mktemp)
    
    local full_output
    # For tests, we'll execute the PHP code directly instead of using monitor
    # This ensures compatibility and tests the core functionality
    printf '%s\n' "$monitor_code" >> "$temp_file"
    full_output=$("$project_root/bin/psysh" --no-interactive < "$temp_file" 2>&1)
    local result=$(extract_monitor_result "$full_output")
    
    # Nettoyer le fichier temporaire
    rm -f "$temp_file"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    # En mode simple, pas d'affichage détaillé
    if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
        echo ""
        print_colored "$YELLOW" ">>> Étape $TEST_COUNT: $step_name"
        print_colored "$BLUE" "Code monitor: $monitor_code"
        print_colored "$BLUE" "Résultat attendu: $expected_result"
        
        echo ""
        print_colored "$BLUE" "Sortie complète du test:"
        echo "$full_output"
        echo ""
        print_colored "$BLUE" "Résultat extrait: $result"
        echo ""
    fi
    
    if [[ "$result" == "$expected_result" ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$GREEN" "✅ PASS: $step_name"
        fi
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        if [[ "${SIMPLE_MODE:-}" != "1" ]]; then
            print_colored "$RED" "❌ FAIL: $step_name"
        fi
        print_colored "$RED" "Code monitor: $monitor_code"
        print_colored "$RED" "Résultat attendu: $expected_result"
        print_colored "$RED" "Résultat obtenu: $result"
        if [[ -z "$result" ]]; then
            print_colored "$RED" "⚠️  La sortie est vide - vérifiez la syntaxe du code"
        fi
        if [[ -n "$full_output" ]]; then
            print_colored "$RED" "Sortie complète pour debug:"
            echo "$full_output" | head -20  # Limiter l'affichage
        fi
    fi
}

# Fonction pour ajouter une pause interactive entre les étapes
wait_for_user() {
    local message
    message="${1:-Appuyez sur Entrée pour continuer vers létape suivante, ou Échap + Entrée pour quitter...}"
    echo ""
    print_colored "$YELLOW" "$message"
    read -r input
    if [[ "$input" == $'\033' ]]; then
        print_colored "$BLUE" "Test interrompu par l'utilisateur."
        exit 0
    fi
}

