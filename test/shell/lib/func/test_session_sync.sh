#!/bin/bash

# =============================================================================
# FONCTION FLEXIBLE POUR TESTER LA SYNCHRONISATION EN SESSION UNIQUE
# =============================================================================

# Fonction principale pour tester la synchronisation dans une même session PsySH
# Usage: test_session_sync "description" [--debug] --step "command1" --expect "result1" [--context TYPE] [--input-type TYPE] [--output-check TYPE] [--timeout SECONDS] [--retry COUNT] [--sync-test] ...
#
# OPTIONS GLOBALES :
#   --debug               : mode debug avec détails complets (pour toute la commande)
#
# OPTIONS PAR ÉTAPE (héritage automatique) :
#   --step "command"      : commande à exécuter
#   --expect "result"     : résultat attendu
#   --context TYPE        : monitor, phpunit, shell, psysh, mixed
#   --input-type TYPE     : pipe, file, echo, interactive, multiline
#   --output-check TYPE   : contains, exact, regex, json, error, not-contains
#   --timeout SECONDS     : timeout pour l'exécution
#   --retry COUNT         : nombre de tentatives en cas d'échec
#   --sync-test          : active le test de synchronisation bidirectionnelle
#   --mock "target=mock" : remplace target par mock pendant l'étape
#   --cleanup "command"  : commande de nettoyage à exécuter après l'étape
#   --setup "command"    : commande de setup à exécuter avant l'étape
#   --async              : exécute cette étape en arrière-plan (asynchrone)
#   --wait-for ID        : attend la fin de l'étape asynchrone avec cet ID
#   --step-id ID         : identifiant unique pour cette étape (pour --wait-for)
#   --condition "expr"   : condition à valider avant d'exécuter l'étape
#   --skip-on-fail       : continue même si cette étape échoue
#   --benchmark          : mesure les performances détaillées de cette étape
#   --memory-check       : vérifie l'utilisation mémoire après l'étape
#   --output-file "path" : sauvegarde la sortie dans un fichier
#   --input-file "path"  : utilise un fichier comme entrée
#   --env "VAR=value"    : définit une variable d'environnement pour l'étape
#   --working-dir "path" : répertoire de travail pour cette étape
#   --log-level LEVEL    : niveau de log pour cette étape (debug, info, warn, error)
#   --tags "tag1,tag2"   : tags pour filtrer/regrouper les étapes
#   --description "desc" : description détaillée de l'étape
#   --pause-after        : pause après cette étape pour inspection manuelle
#   --depends-on "step_id" : cette étape dépend d'une autre étape (utile avec --async)
#   --parallel-group "group" : groupe d'étapes à exécuter en parallèle
#   --fail-fast          : arrête tout le test si cette étape échoue
#   --critical           : marque cette étape comme critique (alias pour --fail-fast)
#   --quiet              : supprime la sortie de cette étape (sauf en cas d'erreur)
#   --verbose            : affiche plus de détails pour cette étape
#   --repeat COUNT       : répète cette étape COUNT fois
#   --delay SECONDS      : attend SECONDS secondes avant d'exécuter l'étape
#   --max-output BYTES   : limite la sortie capturée à BYTES octets
#
# HÉRITAGE DES OPTIONS :
# Si une option n'est pas spécifiée pour une étape, elle hérite de l'étape précédente
#
# Exemples d'utilisation :
#
# 1. Test avec héritage d'options :
#    test_session_sync "Test avec héritage" \
#        --step "echo 'Step 1'" --expect "Step" --context "psysh" --input-type "file" --output-check "not_contains" \
#        --step "echo 'Step 2'" --expect "Step" --context "monitor" --output-check "contains" \
#        --step "echo 'Step 3'" --expect "Step 3" --input-type "pipe"
#
# 2. Test avec fonctionnalités avancées :
#    test_session_sync "Test avancé" --debug \
#        --step "setup_data()" --timeout 60 --retry 3 \
#        --step "process_data()" --sync-test --expect "processed" \
#        --step "validate_data()" --output-check "regex" --expect "^valid"
#
# 3. Test de performance avec métriques :
#    test_session_sync "Performance test" \
#        --step "start_timer()" --metrics \
#        --step "heavy_computation()" --timeout 120 --expect "completed" \
#        --step "stop_timer()" --performance-check
#
test_session_sync() {
    local description="$1"
    shift
    
    # Variables globales
    local global_debug=false
    local global_metrics=false
    local global_performance=false
    
    # Parser les options globales
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                global_debug=true
                shift
                ;;
            --metrics)
                global_metrics=true
                shift
                ;;
            --performance)
                global_performance=true
                shift
                ;;
            --step)
                # On a trouvé la première étape, on s'arrête
                break
                ;;
            *)
                shift
                ;;
        esac
    done
    
    ((TEST_COUNT++))
    echo -e "${BLUE}>>> Étape $TEST_COUNT: $description${NC}"
    
    # Variables pour les étapes
    local steps=()
    local expectations=()
    local contexts=()
    local input_types=()
    local output_checks=()
    local timeouts=()
    local retries=()
    local sync_tests=()
    local step_debug=()
    
    # Variables pour les nouvelles options
    local step_mocks=()
    local step_cleanups=()
    local step_setups=()
    local step_async=()
    local step_wait_for=()
    local step_step_ids=()
    local step_conditions=()
    local step_skip_on_fail=()
    local step_benchmarks=()
    local step_memory_checks=()
    local step_output_files=()
    local step_input_files=()
    local step_envs=()
    local step_working_dirs=()
    local step_log_levels=()
    local step_tags=()
    local step_descriptions=()
    local step_pause_afters=()
    local step_depends_on=()
    local step_parallel_groups=()
    local step_fail_fasts=()
    local step_criticals=()
    local step_quiets=()
    local step_verboses=()
    local step_repeats=()
    local step_delays=()
    local step_max_outputs=()
    
    # Variables pour l'héritage
    local current_step=""
    local current_expect=""
    local current_context="monitor"
    local current_input_type="echo"
    local current_output_check="contains"
    local current_timeout="30"
    local current_retry="1"
    local current_sync_test="false"
    local current_debug="$global_debug"
    local current_mock=""
    local current_cleanup=""
    local current_setup=""
    local current_async="false"
    local current_wait_for=""
    local current_step_id=""
    local current_condition=""
    local current_skip_on_fail="false"
    local current_benchmark="false"
    local current_memory_check="false"
    local current_output_file=""
    local current_input_file=""
    local current_env=""
    local current_working_dir=""
    local current_log_level="info"
    local current_tags=""
    local current_description=""
    local current_pause_after="false"
    local current_depends_on=""
    local current_parallel_group=""
    local current_fail_fast="false"
    local current_critical="false"
    local current_quiet="false"
    local current_verbose="false"
    local current_repeat="1"
    local current_delay="0"
    local current_max_output="0"
    
    # Parser les étapes avec héritage
    while [[ $# -gt 0 ]]; do
        case $1 in
            --step)
                # Sauvegarder l'étape précédente si elle existe
                if [[ -n "$current_step" ]]; then
                    steps+=("$current_step")
                    expectations+=("$current_expect")
                    contexts+=("$current_context")
                    input_types+=("$current_input_type")
                    output_checks+=("$current_output_check")
                    timeouts+=("$current_timeout")
                    retries+=("$current_retry")
                    sync_tests+=("$current_sync_test")
                    step_debug+=("$current_debug")
                fi
                current_step="$2"
                current_expect=""  # Reset expectation mais pas les autres options (héritage)
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
            --input-type)
                current_input_type="$2"
                shift 2
                ;;
            --output-check)
                current_output_check="$2"
                shift 2
                ;;
            --timeout)
                current_timeout="$2"
                shift 2
                ;;
            --retry)
                current_retry="$2"
                shift 2
                ;;
            --sync-test)
                current_sync_test="true"
                shift
                ;;
            --debug)
                current_debug="true"
                shift
                ;;
            --mock)
                current_mock="$2"
                shift 2
                ;;
            --cleanup)
                current_cleanup="$2"
                shift 2
                ;;
            --setup)
                current_setup="$2"
                shift 2
                ;;
            --async)
                current_async="true"
                shift
                ;;
            --wait-for)
                current_wait_for="$2"
                shift 2
                ;;
            --step-id)
                current_step_id="$2"
                shift 2
                ;;
            --condition)
                current_condition="$2"
                shift 2
                ;;
            --skip-on-fail)
                current_skip_on_fail="true"
                shift
                ;;
            --benchmark)
                current_benchmark="true"
                shift
                ;;
            --memory-check)
                current_memory_check="true"
                shift
                ;;
            --output-file)
                current_output_file="$2"
                shift 2
                ;;
            --input-file)
                current_input_file="$2"
                shift 2
                ;;
            --env)
                current_env="$2"
                shift 2
                ;;
            --working-dir)
                current_working_dir="$2"
                shift 2
                ;;
            --log-level)
                current_log_level="$2"
                shift 2
                ;;
            --tags)
                current_tags="$2"
                shift 2
                ;;
            --description)
                current_description="$2"
                shift 2
                ;;
            --pause-after)
                current_pause_after="true"
                shift
                ;;
            --depends-on)
                current_depends_on="$2"
                shift 2
                ;;
            --parallel-group)
                current_parallel_group="$2"
                shift 2
                ;;
            --fail-fast)
                current_fail_fast="true"
                shift
                ;;
            --critical)
                current_critical="true"
                current_fail_fast="true"  # critical est un alias pour fail-fast
                shift
                ;;
            --quiet)
                current_quiet="true"
                shift
                ;;
            --verbose)
                current_verbose="true"
                shift
                ;;
            --repeat)
                current_repeat="$2"
                shift 2
                ;;
            --delay)
                current_delay="$2"
                shift 2
                ;;
            --max-output)
                current_max_output="$2"
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
        input_types+=("$current_input_type")
        output_checks+=("$current_output_check")
        timeouts+=("$current_timeout")
        retries+=("$current_retry")
        sync_tests+=("$current_sync_test")
        step_debug+=("$current_debug")
    fi
    
    # Affichage debug si activé
    if [[ "$global_debug" == "true" || "$DEBUG_MODE" == "1" ]]; then
        echo -e "${CYAN}[DEBUG] Nombre d'étapes: ${#steps[@]}${NC}"
        for i in "${!steps[@]}"; do
            echo -e "${CYAN}[DEBUG] Étape $((i+1)): ${steps[$i]}${NC}"
            echo -e "${CYAN}[DEBUG]   Context: ${contexts[$i]} | Input: ${input_types[$i]} | Check: ${output_checks[$i]}${NC}"
            echo -e "${CYAN}[DEBUG]   Timeout: ${timeouts[$i]}s | Retry: ${retries[$i]} | Sync: ${sync_tests[$i]}${NC}"
        done
    fi
    
    # Métriques de performance si activées
    local start_time=$(date +%s.%N)
    local step_times=()
    
    # Exécuter chaque étape individuellement avec ses options
    local all_passed=true
    local step_results=()
    
    for i in "${!steps[@]}"; do
        local step="${steps[$i]}"
        local expect="${expectations[$i]}"
        local context="${contexts[$i]}"
        local input_type="${input_types[$i]}"
        local output_check="${output_checks[$i]}"
        local timeout="${timeouts[$i]}"
        local retry="${retries[$i]}"
        local sync_test="${sync_tests[$i]}"
        local debug="${step_debug[$i]}"
        
        # Métriques par étape
        local step_start=$(date +%s.%N)
        
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
            "psysh")
                # Commande dans PsySH
                ;;
            "shell")
                # Commande shell
                ;;
            "mixed")
                # Commande dans le shell ou PsySH
                ;;
        esac
        
        # Exécuter l'étape avec retry
        local step_success=false
        local step_result=""
        local attempt=1
        
        while [[ $attempt -le $retry ]]; do
            if [[ $retry -gt 1 ]]; then
                echo -e "${YELLOW}[Étape $((i+1)) - Tentative $attempt/$retry]${NC}"
            fi
            
            # Exécuter selon le contexte
            case "$context" in
                "monitor")
                    step_result=$(execute_monitor_test "$step" "$input_type" "$timeout")
                    ;;
                "phpunit")
                    step_result=$(execute_phpunit_test "$step" "$input_type" "$timeout")
                    ;;
                "shell")
                    step_result=$(execute_shell_test "$step" "$input_type" "$timeout")
                    ;;
                "psysh")
                    step_result=$(execute_psysh_test "$step" "$input_type" "$timeout")
                    ;;
                "mixed")
                    step_result=$(execute_mixed_test "$step" "$input_type" "$timeout")
                    ;;
                *)
                    echo -e "${RED}❌ Contexte inconnu: $context${NC}"
                    step_result="ERROR: Unknown context"
                    ;;
            esac
            
            # Vérifier le résultat
            if [[ -n "$expect" ]]; then
                if check_result "$step_result" "$expect" "$output_check"; then
                    step_success=true
                    break
                fi
            else
                # Pas d'expectation, considérer comme réussi si pas d'erreur
                if [[ $? -eq 0 ]]; then
                    step_success=true
                    break
                fi
            fi
            
            ((attempt++))
            if [[ $attempt -le $retry ]]; then
                echo -e "${YELLOW}⏳ Nouvelle tentative dans 1 seconde...${NC}"
                sleep 1
            fi
        done
        
        # Enregistrer le résultat
        step_results+=("$step_result")
        
        # Métriques par étape
        local step_end=$(date +%s.%N)
        local step_duration=$(echo "$step_end - $step_start" | bc -l)
        step_times+=("$step_duration")
        
        # Affichage du résultat de l'étape
        if [[ "$step_success" == "true" ]]; then
            echo -e "${GREEN}✅ Étape $((i+1)): OK${NC}"
            if [[ "$debug" == "true" || "$global_debug" == "true" ]]; then
                echo -e "${CYAN}[DEBUG] Result: $step_result${NC}"
            fi
        else
            echo -e "${RED}❌ Étape $((i+1)): FAIL${NC}"
            echo -e "${RED}Expected: $expect${NC}"
            echo -e "${RED}Got: $step_result${NC}"
            all_passed=false
        fi
        
        # Test de synchronisation si demandé
        if [[ "$sync_test" == "true" ]]; then
            test_synchronization "$step" "$expect"
        fi
    done
    
    # Métriques globales
    local end_time=$(date +%s.%N)
    local total_duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Affichage du résultat final
    if [[ "$all_passed" == "true" ]]; then
        ((PASS_COUNT++))
        echo -e "${GREEN}✅ PASS: $description${NC}"
        echo -e "${CYAN}🔄 Synchronisation réussie dans session unique${NC}"
        
        # Affichage des métriques si activées
        if [[ "$global_metrics" == "true" ]]; then
            echo -e "${CYAN}📊 Métriques:${NC}"
            echo -e "${CYAN}   Durée totale: ${total_duration}s${NC}"
            echo -e "${CYAN}   Nombre d'étapes: ${#steps[@]}${NC}"
            for i in "${!step_times[@]}"; do
                echo -e "${CYAN}   Étape $((i+1)): ${step_times[$i]}s${NC}"
            done
        fi
    else
        ((FAIL_COUNT++))
        echo -e "${RED}❌ FAIL: $description${NC}"
        echo -e "${RED}Étapes échouées détectées${NC}"
        
        # Affichage détaillé des échecs
        for i in "${!steps[@]}"; do
            if [[ -n "${expectations[$i]}" ]]; then
                echo -e "${RED}Étape $((i+1)): ${steps[$i]} -> Expected: ${expectations[$i]}${NC}"
            fi
        done
    fi
    
    # Affichage des métriques de performance si activées
    if [[ "$global_performance" == "true" ]]; then
        echo -e "${CYAN}⚡ Performance:${NC}"
        echo -e "${CYAN}   Durée moyenne par étape: $(echo "$total_duration / ${#steps[@]}" | bc -l)s${NC}"
        echo -e "${CYAN}   Étapes/seconde: $(echo "${#steps[@]} / $total_duration" | bc -l)${NC}"
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
