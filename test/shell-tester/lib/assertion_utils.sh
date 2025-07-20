#!/bin/bash

# Utilitaires pour les assertions dans les tests
# Contient des fonctions pour tester les conditions, égalité, etc.

# Déterminer le chemin vers les autres utils
ASSERTION_UTILS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$ASSERTION_UTILS_DIR/display_utils.sh"

# =================== FONCTIONS D'ASSERTION DE BASE ===================

# Vérifier si la sortie contient le texte attendu
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

# Vérifier une égalité exacte
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

# Vérifier que la commande a réussi (exit code 0)
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

# Vérifier que la commande a échoué (exit code != 0)
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

# Vérifier avec une regex
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

# Vérifier que la sortie ne contient pas le texte
check_not_contains() {
    local output="$1"
    local not_expected="$2"
    local exit_code="$3"
    
    if [[ "$output" != *"$not_expected"* ]]; then
        return 0
    else
        return 1
    fi
}

# Vérifier qu'une sortie n'est pas vide
check_not_empty() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    if [[ -n "$output" ]]; then
        return 0
    else
        return 1
    fi
}

# Vérifier qu'une sortie est vide
check_empty() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    if [[ -z "$output" ]]; then
        return 0
    else
        return 1
    fi
}

# =================== FONCTIONS D'ASSERTION AVANCÉES ===================

# Assertion avec message personnalisé
assert_with_message() {
    local condition_func="$1"
    local output="$2"
    local expected="$3"
    local exit_code="$4"
    local message="$5"
    
    if $condition_func "$output" "$expected" "$exit_code"; then
        print_success "$message"
        return 0
    else
        print_error "$message - Expected: '$expected', Got: '$output'"
        return 1
    fi
}

# Assertion pour tester une valeur numérique
check_numeric_equals() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    # Extraire les nombres de la sortie
    local output_num=$(echo "$output" | grep -oE '\[0-9\]+' | head -n1)
    local expected_num=$(echo "$expected" | grep -oE '\[0-9\]+' | head -n1)
    
    if [[ "$output_num" -eq "$expected_num" ]]; then
        return 0
    else
        return 1
    fi
}

# Assertion pour tester une valeur numérique supérieure
check_numeric_greater() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    local output_num=$(echo "$output" | grep -oE '\[0-9\]+' | head -n1)
    local expected_num=$(echo "$expected" | grep -oE '\[0-9\]+' | head -n1)
    
    if [[ "$output_num" -gt "$expected_num" ]]; then
        return 0
    else
        return 1
    fi
}

# Assertion pour tester une valeur numérique inférieure
check_numeric_less() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    local output_num=$(echo "$output" | grep -oE '\[0-9\]+' | head -n1)
    local expected_num=$(echo "$expected" | grep -oE '\[0-9\]+' | head -n1)
    
    if [[ "$output_num" -lt "$expected_num" ]]; then
        return 0
    else
        return 1
    fi
}

# =================== FONCTIONS D'ASSERTION JSON/STRUCTURES ===================

# Vérifier la présence d'une clé JSON (nécessite jq)
check_json_key() {
    local output="$1"
    local key_path="$2"
    local exit_code="$3"
    
    if command -v jq >/dev/null 2>&1; then
        if echo "$output" | jq -e "$key_path" >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    else
        # Fallback simple pour basic JSON
        if echo "$output" | grep -q "\"${key_path//./\".*\"}\""; then
            return 0
        else
            return 1
        fi
    fi
}

# Vérifier la valeur d'une clé JSON
check_json_value() {
    local output="$1"
    local key_path="$2"
    local expected_value="$3"
    local exit_code="$4"
    
    if command -v jq >/dev/null 2>&1; then
        local actual_value=$(echo "$output" | jq -r "$key_path" 2>/dev/null)
        if [[ "$actual_value" == "$expected_value" ]]; then
            return 0
        else
            return 1
        fi
    else
        # Fallback simple
        if echo "$output" | grep -q "\"${key_path//./\".*\"}\".*\"$expected_value\""; then
            return 0
        else
            return 1
        fi
    fi
}

# =================== FONCTIONS D'ASSERTION DE PERFORMANCE ===================

# Vérifier qu'une commande s'exécute en moins de X secondes
check_performance_time() {
    local start_time="$1"
    local end_time="$2"
    local max_seconds="$3"
    
    local duration=$((end_time - start_time))
    
    if [[ $duration -le $max_seconds ]]; then
        return 0
    else
        return 1
    fi
}

# =================== FONCTIONS D'ASSERTION PSYSH SPÉCIFIQUES ===================

# Vérifier qu'une sortie PsySH contient une valeur de retour
check_psysh_return() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    # Chercher le pattern "=> expected" ou "= expected"
    if echo "$output" | grep -qE "(=>|=)\s*$expected"; then
        return 0
    else
        return 1
    fi
}

# Vérifier qu'une sortie PsySH ne contient pas d'erreur
check_psysh_no_error() {
    local output="$1"
    local expected="$2"
    local exit_code="$3"
    
    local error_patterns=("PHP Fatal error" "PHP Parse error" "RuntimeException" "Error:" "Fatal error")
    
    for pattern in "${error_patterns[@]}"; do
        if echo "$output" | grep -qi "$pattern"; then
            return 1
        fi
    done
    
    return 0
}

# Vérifier qu'une sortie PsySH contient une erreur spécifique
check_psysh_error() {
    local output="$1"
    local expected_error="$2"
    local exit_code="$3"
    
    if echo "$output" | grep -qi "$expected_error"; then
        return 0
    else
        return 1
    fi
}

# =================== ALIASES POUR COMPATIBILITÉ ===================

# Aliases pour les anciennes fonctions
alias assert_contains='check_contains'
alias assert_equals='check_equals'
alias assert_success='check_success'
alias assert_failure='check_failure'
alias assert_regex='check_regex'

