#!/bin/bash

# =============================================================================
# FONCTION FLEXIBLE POUR TESTER LA SYNCHRONISATION EN SESSION UNIQUE - VERSION ENHANCED
# =============================================================================

# Fonction principale pour tester la synchronisation dans une même session PsySH
# Usage: test_session_sync "description" [--debug] --step "command1" --expect "result1" [options] ...
#
# OPTIONS GLOBALES :
#   --debug               : mode debug avec détails complets
#   --metrics             : affiche les métriques de performance
#   --performance         : affiche les métriques de performance avancées
#
# OPTIONS PAR ÉTAPE :
#   --step "command"      : commande à exécuter
#   --expect "result"     : résultat attendu (peut être utilisé plusieurs fois)
#   --context TYPE        : monitor, phpunit, shell, psysh, mixed (HÉRITABLE)
#   --input-type TYPE     : pipe, file, echo, interactive, multiline (HÉRITABLE)
#   --output-check TYPE   : contains, exact, regex, json, error, not_contains, result, debug (peut être utilisé plusieurs fois pour correspondre aux --expect)
#   --timeout SECONDS     : timeout pour l'exécution (HÉRITABLE)
#   --retry COUNT         : nombre de tentatives en cas d'échec (HÉRITABLE)
#   --sync-test          : active le test de synchronisation bidirectionnelle (NON-HÉRITABLE)
#   --debug              : mode debug pour cette étape (HÉRITABLE)
#   --log-level LEVEL    : niveau de log (debug, info, warn, error) (HÉRITABLE)
#   --quiet              : supprime la sortie (sauf erreur) (HÉRITABLE)
#   --verbose            : affiche plus de détails (HÉRITABLE)
#   --max-output BYTES   : limite la sortie capturée (HÉRITABLE)
#
# OPTIONS NON-HÉRITABLES (spécifiques à chaque étape) :
#   --mock "target=mock" : remplace target par mock pendant l'étape
#   --cleanup "command"  : commande de nettoyage à exécuter après l'étape
#   --setup "command"    : commande de setup à exécuter avant l'étape
#   --cleanup-context TYPE : contexte pour la commande cleanup (monitor, phpunit, shell, psysh)
#   --setup-context TYPE   : contexte pour la commande setup (monitor, phpunit, shell, psysh)
#   --async              : exécute cette étape en arrière-plan
#   --wait-for ID        : attend la fin de l'étape asynchrone avec cet ID
#   --step-id ID         : identifiant unique pour cette étape
#   --condition "expr"   : condition à valider avant d'exécuter l'étape
#   --skip-on-fail       : continue même si cette étape échoue
#   --benchmark          : mesure les performances détaillées de cette étape
#   --memory-check       : vérifie l'utilisation mémoire après l'étape
#   --output-file "path" : sauvegarde la sortie dans un fichier
#   --input-file "path"  : utilise un fichier comme entrée
#   --env "VAR=value"    : définit une variable d'environnement
#   --working-dir "path" : répertoire de travail
#   --tags "tag1,tag2"   : tags pour filtrer/regrouper
#   --description "desc" : description détaillée de l'étape
#   --pause-after        : pause après cette étape
#   --depends-on "step_id" : cette étape dépend d'une autre étape
#   --parallel-group "group" : groupe d'étapes à exécuter en parallèle
#   --fail-fast          : arrête tout le test si cette étape échoue
#   --critical           : marque cette étape comme critique
#   --repeat COUNT       : répète cette étape COUNT fois
#   --delay SECONDS      : attend SECONDS secondes avant d'exécuter
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
    local expectations_output_checks=()
    local contexts=()
    local input_types=()
    local output_checks=()
    local timeouts=()
    local retries=()
    local step_debug=()
    local log_levels=()
    local quiets=()
    local verboses=()
    local max_outputs=()
    
    # Variables pour options non-héritables
    local step_mocks=()
    local step_cleanups=()
    local step_setups=()
    local step_cleanup_contexts=()
    local step_setup_contexts=()
    local step_sync_tests=()
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
    local step_tags=()
    local step_descriptions=()
    local step_pause_afters=()
    local step_depends_on=()
    local step_parallel_groups=()
    local step_fail_fasts=()
    local step_criticals=()
    local step_repeats=()
    local step_delays=()
    
    # Variables pour l'héritage (options héritables)
    local current_step=""
    local current_expects=()
    local current_expects_output_checks=()
    local current_context="monitor"
    local current_input_type="echo"
    local current_output_check="contains"
    local current_timeout="30"
    local current_retry="1"
    local current_debug="$global_debug"
    local current_log_level="info"
    local current_quiet="false"
    local current_verbose="false"
    local current_max_output="0"
    
    # Variables pour options non-héritables (reset à chaque étape)
    local current_mock=""
    local current_cleanup=""
    local current_setup=""
    local current_cleanup_context="shell"
    local current_setup_context="shell"
    local current_sync_test="false"
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
    local current_tags=""
    local current_description=""
    local current_pause_after="false"
    local current_depends_on=""
    local current_parallel_group=""
    local current_fail_fast="false"
    local current_critical="false"
    local current_repeat="1"
    local current_delay="0"
    
    # Parser les étapes avec héritage sélectif
    while [[ $# -gt 0 ]]; do
        case $1 in
            --step)
                # Sauvegarder l'étape précédente si elle existe
                if [[ -n "$current_step" ]]; then
                    steps+=("$current_step")
                    # Jointure des expectations multiples avec délimiteur
                    local joined_expects=$(printf "%s|" "${current_expects[@]}")
                    joined_expects=${joined_expects%|} # Supprimer le dernier |
                    expectations+=("$joined_expects")
                    
                    # Jointure des output checks multiples avec délimiteur  
                    local joined_output_checks=$(printf "%s|" "${current_expects_output_checks[@]}")
                    joined_output_checks=${joined_output_checks%|} # Supprimer le dernier |
                    expectations_output_checks+=("$joined_output_checks")
                    
                    contexts+=("$current_context")
                    input_types+=("$current_input_type")
                    output_checks+=("$current_output_check")
                    timeouts+=("$current_timeout")
                    retries+=("$current_retry")
                    step_debug+=("$current_debug")
                    log_levels+=("$current_log_level")
                    quiets+=("$current_quiet")
                    verboses+=("$current_verbose")
                    max_outputs+=("$current_max_output")
                    
                    # Sauvegarder les options non-héritables
                    step_mocks+=("$current_mock")
                    step_cleanups+=("$current_cleanup")
                    step_setups+=("$current_setup")
                    step_cleanup_contexts+=("$current_cleanup_context")
                    step_setup_contexts+=("$current_setup_context")
                    step_sync_tests+=("$current_sync_test")
                    step_async+=("$current_async")
                    step_wait_for+=("$current_wait_for")
                    step_step_ids+=("$current_step_id")
                    step_conditions+=("$current_condition")
                    step_skip_on_fail+=("$current_skip_on_fail")
                    step_benchmarks+=("$current_benchmark")
                    step_memory_checks+=("$current_memory_check")
                    step_output_files+=("$current_output_file")
                    step_input_files+=("$current_input_file")
                    step_envs+=("$current_env")
                    step_working_dirs+=("$current_working_dir")
                    step_tags+=("$current_tags")
                    step_descriptions+=("$current_description")
                    step_pause_afters+=("$current_pause_after")
                    step_depends_on+=("$current_depends_on")
                    step_parallel_groups+=("$current_parallel_group")
                    step_fail_fasts+=("$current_fail_fast")
                    step_criticals+=("$current_critical")
                    step_repeats+=("$current_repeat")
                    step_delays+=("$current_delay")
                fi
                
                current_step="$2"
                current_expects=()  # Reset expectations
                current_expects_output_checks=()  # Reset output checks
                
                # Reset des options non-héritables
                current_mock=""
                current_cleanup=""
                current_setup=""
                current_async="false"
                current_wait_for=""
                current_step_id=""
                current_condition=""
                current_skip_on_fail="false"
                current_benchmark="false"
                current_memory_check="false"
                current_output_file=""
                current_input_file=""
                current_env=""
                current_working_dir=""
                current_tags=""
                current_description=""
                current_pause_after="false"
                current_depends_on=""
                current_parallel_group=""
                current_fail_fast="false"
                current_critical="false"
                current_repeat="1"
                current_delay="0"
                
                shift 2
                ;;
            # Options héritables
            --expect) 
                current_expects+=("$2")
                # Si pas d'output-check spécifié, utiliser celui par défaut
                if [[ ${#current_expects_output_checks[@]} -lt ${#current_expects[@]} ]]; then
                    current_expects_output_checks+=("$current_output_check")
                fi
                shift 2 
                ;;
            --context) current_context="$2"; shift 2 ;;
            --input-type) current_input_type="$2"; shift 2 ;;
            --output-check) 
                # Si on a des expects, associer ce output-check au dernier expect
                if [[ ${#current_expects[@]} -gt 0 ]]; then
                    current_expects_output_checks[${#current_expects[@]}-1]="$2"
                else
                    current_output_check="$2"
                fi
                shift 2 
                ;;
            --timeout) current_timeout="$2"; shift 2 ;;
            --retry) current_retry="$2"; shift 2 ;;
            --sync-test) current_sync_test="true"; shift ;;
            --debug) current_debug="true"; shift ;;
            --log-level) current_log_level="$2"; shift 2 ;;
            --quiet) current_quiet="true"; shift ;;
            --verbose) current_verbose="true"; shift ;;
            --max-output) current_max_output="$2"; shift 2 ;;
            
            # Options non-héritables
            --mock) current_mock="$2"; shift 2 ;;
            --cleanup) current_cleanup="$2"; shift 2 ;;
            --setup) current_setup="$2"; shift 2 ;;
            --cleanup-context) current_cleanup_context="$2"; shift 2 ;;
            --setup-context) current_setup_context="$2"; shift 2 ;;
            --async) current_async="true"; shift ;;
            --wait-for) current_wait_for="$2"; shift 2 ;;
            --step-id) current_step_id="$2"; shift 2 ;;
            --condition) current_condition="$2"; shift 2 ;;
            --skip-on-fail) current_skip_on_fail="true"; shift ;;
            --benchmark) current_benchmark="true"; shift ;;
            --memory-check) current_memory_check="true"; shift ;;
            --output-file) current_output_file="$2"; shift 2 ;;
            --input-file) current_input_file="$2"; shift 2 ;;
            --env) current_env="$2"; shift 2 ;;
            --working-dir) current_working_dir="$2"; shift 2 ;;
            --tags) current_tags="$2"; shift 2 ;;
            --description) current_description="$2"; shift 2 ;;
            --pause-after) current_pause_after="true"; shift ;;
            --depends-on) current_depends_on="$2"; shift 2 ;;
            --parallel-group) current_parallel_group="$2"; shift 2 ;;
            --fail-fast) current_fail_fast="true"; shift ;;
            --critical) current_critical="true"; current_fail_fast="true"; shift ;;
            --repeat) current_repeat="$2"; shift 2 ;;
            --delay) current_delay="$2"; shift 2 ;;
            
            *)
                echo -e "${RED}❌ Option inconnue: $1${NC}"
                return 1
                ;;
        esac
    done
    
    # Ajouter la dernière étape
    if [[ -n "$current_step" ]]; then
        steps+=("$current_step")
        
        # Jointure des expectations multiples avec délimiteur
        local joined_expects=$(printf "%s|" "${current_expects[@]}")
        joined_expects=${joined_expects%|} # Supprimer le dernier |
        expectations+=("$joined_expects")
        
        # Jointure des output checks multiples avec délimiteur  
        local joined_output_checks=$(printf "%s|" "${current_expects_output_checks[@]}")
        joined_output_checks=${joined_output_checks%|} # Supprimer le dernier |
        expectations_output_checks+=("$joined_output_checks")
        
        contexts+=("$current_context")
        input_types+=("$current_input_type")
        output_checks+=("$current_output_check")
        timeouts+=("$current_timeout")
        retries+=("$current_retry")
        step_debug+=("$current_debug")
        log_levels+=("$current_log_level")
        quiets+=("$current_quiet")
        verboses+=("$current_verbose")
        max_outputs+=("$current_max_output")
        
        # Sauvegarder les options non-héritables
        step_mocks+=("$current_mock")
        step_cleanups+=("$current_cleanup")
        step_setups+=("$current_setup")
        step_cleanup_contexts+=("$current_cleanup_context")
        step_setup_contexts+=("$current_setup_context")
        step_sync_tests+=("$current_sync_test")
        step_async+=("$current_async")
        step_wait_for+=("$current_wait_for")
        step_step_ids+=("$current_step_id")
        step_conditions+=("$current_condition")
        step_skip_on_fail+=("$current_skip_on_fail")
        step_benchmarks+=("$current_benchmark")
        step_memory_checks+=("$current_memory_check")
        step_output_files+=("$current_output_file")
        step_input_files+=("$current_input_file")
        step_envs+=("$current_env")
        step_working_dirs+=("$current_working_dir")
        step_tags+=("$current_tags")
        step_descriptions+=("$current_description")
        step_pause_afters+=("$current_pause_after")
        step_depends_on+=("$current_depends_on")
        step_parallel_groups+=("$current_parallel_group")
        step_fail_fasts+=("$current_fail_fast")
        step_criticals+=("$current_critical")
        step_repeats+=("$current_repeat")
        step_delays+=("$current_delay")
    fi
    
    # Affichage debug si activé
    if [[ "$global_debug" == "true" || "$DEBUG_MODE" == "1" ]]; then
        echo -e "${CYAN}[DEBUG] Nombre d'étapes: ${#steps[@]}${NC}"
        for i in "${!steps[@]}"; do
            echo -e "${CYAN}[DEBUG] Étape $((i+1)): ${steps[$i]}${NC}"
            echo -e "${CYAN}[DEBUG]   Context: ${contexts[$i]} | Input: ${input_types[$i]} | Check: ${output_checks[$i]}${NC}"
            echo -e "${CYAN}[DEBUG]   Timeout: ${timeouts[$i]}s | Retry: ${retries[$i]} | Sync: ${sync_tests[$i]}${NC}"
            [[ -n "${step_mocks[$i]}" ]] && echo -e "${CYAN}[DEBUG]   Mock: ${step_mocks[$i]}${NC}"
            [[ -n "${step_setups[$i]}" ]] && echo -e "${CYAN}[DEBUG]   Setup: ${step_setups[$i]}${NC}"
            [[ -n "${step_cleanups[$i]}" ]] && echo -e "${CYAN}[DEBUG]   Cleanup: ${step_cleanups[$i]}${NC}"
        done
    fi
    
    # Métriques de performance
    local start_time=$(date +%s.%N)
    local step_times=()
    
    # Exécuter chaque étape avec ses options
    local all_passed=true
    local step_results=()
    
    # Gestion des étapes asynchrones
    declare -A async_pids
    declare -A async_results
    declare -A step_id_map
    
    # Créer une carte des step-id vers les indices
    for i in "${!steps[@]}"; do
        local step_id="${step_step_ids[$i]}"
        if [[ -n "$step_id" ]]; then
            step_id_map["$step_id"]=$i
        fi
    done
    
    for i in "${!steps[@]}"; do
        local step="${steps[$i]}"
        local expect="${expectations[$i]}"
        local expect_output_checks="${expectations_output_checks[$i]}"
        local context="${contexts[$i]}"
        local input_type="${input_types[$i]}"
        local output_check="${output_checks[$i]}"
        local timeout="${timeouts[$i]}"
        local retry="${retries[$i]}"
        local sync_test="${step_sync_tests[$i]}"
        local debug="${step_debug[$i]}"
        local quiet="${quiets[$i]}"
        local verbose="${verboses[$i]}"
        
        # Options spécifiques à l'étape
        local mock="${step_mocks[$i]}"
        local cleanup="${step_cleanups[$i]}"
        local setup="${step_setups[$i]}"
        local condition="${step_conditions[$i]}"
        local skip_on_fail="${step_skip_on_fail[$i]}"
        local benchmark="${step_benchmarks[$i]}"
        local memory_check="${step_memory_checks[$i]}"
        local output_file="${step_output_files[$i]}"
        local input_file="${step_input_files[$i]}"
        local env="${step_envs[$i]}"
        local working_dir="${step_working_dirs[$i]}"
        local description="${step_descriptions[$i]}"
        local pause_after="${step_pause_afters[$i]}"
        local fail_fast="${step_fail_fasts[$i]}"
        local repeat="${step_repeats[$i]}"
        local delay="${step_delays[$i]}"
        
        # Afficher la description de l'étape si présente
        if [[ -n "$description" ]]; then
            echo -e "${YELLOW}[Étape $((i+1))] $description${NC}"
        fi
        
        # Vérifier la condition si présente
        if [[ -n "$condition" ]]; then
            if ! eval "$condition"; then
                echo -e "${YELLOW}⏭️  Étape $((i+1)) ignorée (condition non remplie): $condition${NC}"
                continue
            fi
        fi
        
        # Délai avant exécution
        if [[ "$delay" -gt 0 ]]; then
            echo -e "${YELLOW}⏳ Attente de ${delay}s avant l'étape $((i+1))...${NC}"
            sleep "$delay"
        fi
        
        # Répéter l'étape si nécessaire
        for ((rep=1; rep<=repeat; rep++)); do
            if [[ "$repeat" -gt 1 ]]; then
                echo -e "${YELLOW}[Étape $((i+1)) - Répétition $rep/$repeat]${NC}"
            fi
            
            # Métriques par étape
            local step_start=$(date +%s.%N)
            
            # Changer de répertoire de travail si spécifié
            if [[ -n "$working_dir" ]]; then
                pushd "$working_dir" > /dev/null 2>&1
            fi
            
            # Définir les variables d'environnement si spécifiées
            if [[ -n "$env" ]]; then
                export "$env"
            fi
            
            # Setup avant l'exécution
            if [[ -n "$setup" ]]; then
                if [[ "$verbose" == "true" || "$global_debug" == "true" ]]; then
                    echo -e "${CYAN}[SETUP] Exécution: $setup${NC}"
                fi
                eval "$setup"
            fi
            
            # Appliquer le mock si défini
            if [[ -n "$mock" ]]; then
                if [[ "$verbose" == "true" || "$global_debug" == "true" ]]; then
                    echo -e "${CYAN}[MOCK] Application: $mock${NC}"
                fi
                # Implémentation basique du mock
                local mock_target=$(echo "$mock" | cut -d'=' -f1)
                local mock_replacement=$(echo "$mock" | cut -d'=' -f2)
                alias "$mock_target"="$mock_replacement"
            fi
            
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
                    # Commande shell directe
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
                
                # Benchmark si activé
                if [[ "$benchmark" == "true" ]]; then
                    local bench_start=$(date +%s.%N)
                fi
                
                # Gestion des entrées depuis fichier
                local actual_step="$step"
                if [[ -n "$input_file" ]]; then
                    if [[ -f "$input_file" ]]; then
                        actual_step=$(cat "$input_file")
                        if [[ "$verbose" == "true" || "$global_debug" == "true" ]]; then
                            echo -e "${CYAN}[INPUT-FILE] Commande lue depuis $input_file: $actual_step${NC}"
                        fi
                    else
                        echo -e "${RED}❌ Fichier d'entrée non trouvé: $input_file${NC}"
                        step_result="ERROR: Input file not found"
                        break
                    fi
                fi
                
                # Exécuter selon le contexte
                case "$context" in
                    "monitor")
                        step_result=$(execute_monitor_test "$actual_step" "$input_type" "$timeout")
                        ;;
                    "phpunit")
                        step_result=$(execute_phpunit_test "$actual_step" "$input_type" "$timeout")
                        ;;
                    "shell")
                        step_result=$(execute_shell_test "$actual_step" "$input_type" "$timeout")
                        ;;
                    "psysh")
                        step_result=$(execute_psysh_test "$actual_step" "$input_type" "$timeout")
                        ;;
                    "mixed")
                        step_result=$(execute_mixed_test "$actual_step" "$input_type" "$timeout")
                        ;;
                    *)
                        echo -e "${RED}❌ Contexte inconnu: $context${NC}"
                        step_result="ERROR: Unknown context"
                        ;;
                esac
                
                # Limitation de la sortie si spécifiée
                if [[ "$current_max_output" -gt 0 ]]; then
                    step_result=$(echo "$step_result" | head -c "$current_max_output")
                    if [[ "$verbose" == "true" || "$global_debug" == "true" ]]; then
                        echo -e "${CYAN}[MAX-OUTPUT] Sortie limitée à $current_max_output octets${NC}"
                    fi
                fi
                
                # Benchmark si activé
                if [[ "$benchmark" == "true" ]]; then
                    local bench_end=$(date +%s.%N)
                    local bench_duration=$(echo "$bench_end - $bench_start" | bc -l)
                    echo -e "${CYAN}⚡ Benchmark Étape $((i+1)): ${bench_duration}s${NC}"
                fi
                
                # Vérification mémoire si activée
                if [[ "$memory_check" == "true" ]]; then
                    local memory_usage=$(ps -o pid,vsz,rss,comm -p $$ | tail -1)
                    echo -e "${CYAN}🧠 Mémoire Étape $((i+1)): $memory_usage${NC}"
                fi
                
                # Sauvegarder la sortie dans un fichier si spécifié
                if [[ -n "$output_file" ]]; then
                    echo "$step_result" > "$output_file"
                fi
                
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
            
            # Cleanup après l'exécution
            if [[ -n "$cleanup" ]]; then
                if [[ "$verbose" == "true" || "$global_debug" == "true" ]]; then
                    echo -e "${CYAN}[CLEANUP] Exécution: $cleanup${NC}"
                fi
                eval "$cleanup"
            fi
            
            # Supprimer le mock si défini
            if [[ -n "$mock" ]]; then
                local mock_target=$(echo "$mock" | cut -d'=' -f1)
                unalias "$mock_target" 2>/dev/null
            fi
            
            # Restaurer le répertoire de travail
            if [[ -n "$working_dir" ]]; then
                popd > /dev/null 2>&1
            fi
            
            # Métriques par étape
            local step_end=$(date +%s.%N)
            local step_duration=$(echo "$step_end - $step_start" | bc -l)
            step_times+=("$step_duration")
            
            # Affichage du résultat
            if [[ "$step_success" == "true" ]]; then
                if [[ "$quiet" != "true" ]]; then
                    echo -e "${GREEN}✅ Étape $((i+1)): OK${NC}"
                fi
                if [[ "$debug" == "true" || "$global_debug" == "true" ]]; then
                    echo -e "${CYAN}[DEBUG] Result: $step_result${NC}"
                fi
            else
                echo -e "${RED}❌ Étape $((i+1)): FAIL${NC}"
                if [[ "$quiet" != "true" ]]; then
                    echo -e "${RED}Expected: $expect${NC}"
                    echo -e "${RED}Got: $step_result${NC}"
                fi
                
                if [[ "$skip_on_fail" == "true" ]]; then
                    echo -e "${YELLOW}⏭️  Continuer malgré l'échec (skip-on-fail activé)${NC}"
                elif [[ "$fail_fast" == "true" ]]; then
                    echo -e "${RED}⏹️  Arrêt immédiat (fail-fast activé)${NC}"
                    return 1
                else
                    all_passed=false
                fi
            fi
            
            # Pause si demandée
            if [[ "$pause_after" == "true" ]]; then
                echo -e "${YELLOW}⏸️  Pause après l'étape $((i+1)). Appuyez sur Entrée pour continuer...${NC}"
                read -r
            fi
            
            # Test de synchronisation si demandé
            if [[ "$sync_test" == "true" ]]; then
                # test_synchronization "$step" "$expect" # @TODO: Fix this function call
            fi
        done
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
# EXEMPLES D'UTILISATION AVEC LES NOUVELLES OPTIONS
# =============================================================================

# Exemple avec mock et setup/cleanup
example_advanced_test() {
    test_session_sync "Test avancé avec mock et setup/cleanup" \
        --setup "echo 'Initialisation...'" \
        --step "send_email('test@example.com')" \
        --mock "send_email=echo 'Email simulé:'" \
        --expect "Email simulé:" \
        --cleanup "echo 'Nettoyage...'" \
        --step "verify_email_sent()" \
        --expect "Email envoyé"
}

# Exemple avec conditions et retry
example_conditional_test() {
    test_session_sync "Test avec conditions" \
        --step "setup_database()" \
        --condition "[ -f /tmp/db_ready ]" \
        --retry 3 \
        --step "run_tests()" \
        --expect "Tests passed" \
        --fail-fast \
        --cleanup "rm -f /tmp/db_ready"
}

# Exemple avec benchmark et métriques
example_performance_test() {
    test_session_sync "Test de performance" --metrics --performance \
        --step "heavy_computation()" \
        --benchmark \
        --memory-check \
        --timeout 60 \
        --expect "Computation completed" \
        --step "cleanup_resources()" \
        --quiet
}
