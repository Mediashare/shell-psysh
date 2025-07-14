#!/bin/bash

# =============================================================================
# FONCTION FLEXIBLE POUR TESTER LA SYNCHRONISATION EN SESSION UNIQUE
# =============================================================================

# Fonction principale pour tester la synchronisation dans une même session PsySH
# Usage: test_session_sync "description" --step "command1" --expect "result1" --step "command2" --expect "result2" ...
#
# Exemples d'utilisation :
#
# 1. Test de synchronisation de variables :
#    test_session_sync "Variable sync test" \
#        --step '$var = "hello"' --expect "hello" \
#        --step 'echo $var' --expect "hello"
#
# 2. Test avec contextes mixtes :
#    test_session_sync "Mixed context test" \
#        --step 'monitor "echo 1"' --context monitor --expect "1" \
#        --step 'phpunit:echo "test"' --context phpunit --expect "test"
#
# 3. Test de fonctions :
#    test_session_sync "Function sync test" \
#        --step 'function myFunc() { return "result"; }' \
#        --step 'echo myFunc()' --expect "result"
#
test_session_sync() {
    local description="$1"
    shift
    
    ((TEST_COUNT++))
    echo -e "${BLUE}>>> Étape $TEST_COUNT: $description${NC}"
    
    # Parser les étapes et attentes
    local steps=()
    local expectations=()
    local contexts=()
    local current_step=""
    local current_expect=""
    local current_context="monitor"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --step)
                if [[ -n "$current_step" ]]; then
                    steps+=("$current_step")
                    expectations+=("$current_expect")
                    contexts+=("$current_context")
                fi
                current_step="$2"
                current_expect=""  # Reset expectation
                current_context="monitor"  # Reset context
                shift 2
                ;;
            --expect)
                current_expect="$2"
                shift 2
                ;;
            --context)
                current_context="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}❌ Option inconnue: $1${NC}"
                return 1
                ;;
        esac
    done
    
    # Ajouter la dernière étape
    if [[ -n "$current_step" ]]; then
        steps+=("$current_step")
        expectations+=("$current_expect")
        contexts+=("$current_context")
    fi
    
    # Construire la commande complète pour une session unique
    local full_command=""
    local verification_points=()
    
    for i in "${!steps[@]}"; do
        local step="${steps[$i]}"
        local expect="${expectations[$i]}"
        local context="${contexts[$i]}"
        
        # Adapter la commande selon le contexte
        case "$context" in
            "phpunit")
                if [[ "$step" != phpunit:* ]]; then
                    step="phpunit:$step"
                fi
                ;;
            "monitor")
                if [[ "$step" != monitor* ]]; then
                    step="monitor \"$step\""
                fi
                ;;
            "shell")
                # Commande shell directe dans PsySH
                ;;
        esac
        
        full_command+="$step; "
        
        # Ajouter une vérification si attendue
        if [[ -n "$expect" ]]; then
            verification_points+=("$expect")
        fi
    done
    
    # Ajouter une commande finale pour capturer l'état
    full_command+="echo '=== SESSION_SYNC_COMPLETE ==='";
    
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo -e "${CYAN}[DEBUG] Full command: $full_command${NC}"
        echo -e "${CYAN}[DEBUG] Verification points: ${verification_points[*]}${NC}"
    fi
    
    # Exécuter toute la séquence dans une session unique
    local result=$(execute_monitor_test "$full_command" "echo" "30")
    
    # Vérifier chaque point d'attente
    local all_passed=true
    for expect in "${verification_points[@]}"; do
        if [[ -n "$expect" && "$result" != *"$expect"* ]]; then
            all_passed=false
            break
        fi
    done
    
    if [[ "$all_passed" == "true" && "$result" == *"SESSION_SYNC_COMPLETE"* ]]; then
        ((PASS_COUNT++))
        echo -e "${GREEN}✅ PASS: $description${NC}"
        echo -e "${CYAN}🔄 Synchronisation réussie dans session unique${NC}"
        if [[ "$DEBUG_MODE" == "1" ]]; then
            echo -e "${CYAN}[DEBUG] Result: $result${NC}"
        fi
    else
        ((FAIL_COUNT++))
        echo -e "${RED}❌ FAIL: $description${NC}"
        echo -e "${RED}Steps: ${steps[*]}${NC}"
        echo -e "${RED}Expected: ${verification_points[*]}${NC}"
        echo -e "${RED}Got: $result${NC}"
    fi
}

# =============================================================================
# FONCTIONS SPÉCIALISÉES POUR LA SYNCHRONISATION
# =============================================================================

# Fonction simplifiée pour tester des variables
# Usage: test_variable_sync_session "description" "var_name" "var_value" "verification_expr"
test_variable_sync_session() {
    local description="$1"
    local var_name="$2"
    local var_value="$3"
    local verification_expr="$4"
    
    test_session_sync "$description" \
        --step "\$var_name = $var_value" \
        --expect "$var_name" \
        --step "echo \$var_name" \
        --expect "$var_value" \
        --step "$verification_expr" \
        --expect "$var_value"
}

# Fonction pour tester des fonctions
# Usage: test_function_sync_session "description" "function_def" "function_call" "expected_result"
test_function_sync_session() {
    local description="$1"
    local function_def="$2"
    local function_call="$3"
    local expected_result="$4"
    
    test_session_sync "$description" \
        --step "$function_def" \
        --step "$function_call" \
        --expect "$expected_result"
}

# Fonction pour tester des classes
# Usage: test_class_sync_session "description" "class_def" "instance_creation" "method_call" "expected_result"
test_class_sync_session() {
    local description="$1"
    local class_def="$2"
    local instance_creation="$3"
    local method_call="$4"
    local expected_result="$5"
    
    test_session_sync "$description" \
        --step "$class_def" \
        --step "$instance_creation" \
        --step "$method_call" \
        --expect "$expected_result"
}

# Fonction pour tester des contextes mixtes (monitor + phpunit)
# Usage: test_mixed_context_sync "description" context1 command1 expected1 context2 command2 expected2 ...
test_mixed_context_sync() {
    local description="$1"
    shift
    
    # Cette fonction accepte des triplets: context command expected
    local args=()
    while [[ $# -gt 0 ]]; do
        if [[ $# -ge 3 ]]; then
            args+=("--context" "$1" "--step" "$2" "--expect" "$3")
            shift 3
        else
            echo -e "${RED}❌ Arguments insuffisants pour test_mixed_context_sync${NC}"
            return 1
        fi
    done
    
    test_session_sync "$description" "${args[@]}"
}

# Fonction pour tester la persistance de données complexes
# Usage: test_complex_data_session "description" "setup_data" "access_patterns" "expected_values"
test_complex_data_session() {
    local description="$1"
    local setup_data="$2"
    local access_patterns="$3"
    local expected_values="$4"
    
    test_session_sync "$description" \
        --step "$setup_data" \
        --step "$access_patterns" \
        --expect "$expected_values"
}

# Test de synchronisation bidirectionnelle (version simplifiée pour compatibilité)
# Usage: test_sync_bidirectional "description" "setup_command" "verify_command" "expected"
test_sync_bidirectional() {
    local description="$1"
    local setup_command="$2"
    local verify_command="$3"
    local expected="$4"
    
    test_session_sync "$description" \
        --step "$setup_command" \
        --step "$verify_command" \
        --expect "$expected"
}

# =============================================================================
# EXEMPLES D'UTILISATION
# =============================================================================

# Exemple 1: Test de synchronisation de variable simple
example_variable_sync() {
    test_variable_sync_session \
        "Synchronisation variable \$name" \
        "name" \
        "\"John\"" \
        "echo \$name"
}

# Exemple 2: Test de synchronisation de fonction
example_function_sync() {
    test_function_sync_session \
        "Synchronisation fonction greet()" \
        "function greet(\$name) { return \"Hello \" . \$name; }" \
        "echo greet('World')" \
        "Hello World"
}

# Exemple 3: Test de synchronisation de classe
example_class_sync() {
    test_class_sync_session \
        "Synchronisation classe User" \
        "class User { public \$name; function __construct(\$n) { \$this->name = \$n; } function getName() { return \$this->name; } }" \
        "\$user = new User('Alice')" \
        "echo \$user->getName()" \
        "Alice"
}

# Exemple 4: Test de contexte mixte
example_mixed_context() {
    test_mixed_context_sync \
        "Test contexte mixte monitor + phpunit" \
        "monitor" "echo 'test monitor'" "test monitor" \
        "phpunit" "echo 'test phpunit'" "test phpunit"
}
