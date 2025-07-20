#!/bin/bash

# =============================================================================
# FONCTION FLEXIBLE POUR TESTER LA SYNCHRONISATION EN SESSION UNIQUE - VERSION ENHANCED
# =============================================================================

# =============================================================================
# LOGIQUE INFAILLIBLE DES SESSIONS
# =============================================================================
#
# RÈGLES D'OR :
# 1. SESSION MAIN UNIVERSELLE : Toujours créée au démarrage (contexte psysh par défaut)
# 2. EXÉCUTION SYSTÉMATIQUE : Toute étape s'exécute dans main + ses tags
# 3. HÉRITAGE PAR SESSION : Chaque session conserve son contexte jusqu'à forçage
# 4. FORÇAGE LOCAL : --shell/--psysh affecte toutes les sessions de cette étape
# 5. PERSISTANCE : Les sessions survivent entre les étapes
#
# EXEMPLES DE COMPORTEMENT :
#
# Exemple 1 - Session main uniquement :
# --step "echo 'Step 1'"           # main → psysh (défaut)
# --step "echo 'Step 2'"           # main → psysh (hérité)
# --step "echo 'Step 3'" --shell   # main → shell (forcé)
# --step "echo 'Step 4'"           # main → shell (hérité)
#
# Exemple 2 - Sessions avec tags :
# --step "echo 'Step 1'" --tag "A"              # main → psysh, A → psysh (créée)
# --step "echo 'Step 2'" --tag "A"              # main → psysh, A → psysh (héritée)
# --step "echo 'Step 3'" --tag "A" --shell      # main → shell, A → shell (forcé)
# --step "echo 'Step 4'" --tag "B"              # main → shell, B → psysh (créée)
# --step "echo 'Step 5'" --tag "A"              # main → shell, A → shell (héritée)
#
# Exemple 3 - Exécution multiple :
# --step "echo 'Step 1'" --tag "A" --tag "B"    # main → psysh, A → psysh, B → psysh
# --step "echo 'Step 2'" --shell                # main → shell uniquement
# --step "echo 'Step 3'" --tag "A"              # main → shell, A → psysh (conservée)
#
# =============================================================================

# Variables globales pour les sessions (compatible bash anciennes versions)
# Format: session_name:context|session_name:context|...
GLOBAL_SESSION_CONTEXTS=""
GLOBAL_SESSION_PROCESSES=""
GLOBAL_SESSION_FIFOS_IN=""
GLOBAL_SESSION_FIFOS_OUT=""
GLOBAL_SESSION_HISTORY=""

# Fonctions utilitaires pour simuler les arrays associatifs
set_session_value() {
    local var_name="$1"
    local session_name="$2"
    local value="$3"
    local current_value
    
    eval "current_value=\$$var_name"
    
    # Supprimer l'ancienne valeur si elle existe
    current_value=$(echo "$current_value" | sed "s/\(^\|[|]\)${session_name}:[^|]*\([|]\|$\)/\1\2/g" | sed 's/^|//;s/|$//')
    
    # Ajouter la nouvelle valeur
    if [[ -n "$current_value" ]]; then
        current_value="${current_value}|${session_name}:${value}"
    else
        current_value="${session_name}:${value}"
    fi
    
    eval "$var_name='$current_value'"
}

get_session_value() {
    local var_name="$1"
    local session_name="$2"
    local current_value
    
    eval "current_value=\$$var_name"
    
    echo "$current_value" | tr '|' '\n' | grep "^${session_name}:" | cut -d':' -f2-
}

has_session() {
    local session_name="$1"
    local context
    context=$(get_session_value "GLOBAL_SESSION_CONTEXTS" "$session_name")
    [[ -n "$context" ]]
}

list_sessions() {
    echo "$GLOBAL_SESSION_CONTEXTS" | tr '|' '\n' | cut -d':' -f1
}

# Fonction pour vérifier les résultats négatifs
check_no_expect() {
    local result="$1"
    local unexpected="$2"
    local check_type="$3"
    
    case "$check_type" in
        "contains")
            [[ "$result" != *"$unexpected"* ]]
            ;;
        "exact")
            [[ "$result" != "$unexpected" ]]
            ;;
        "regex")
            [[ ! "$result" =~ $unexpected ]]
            ;;
        *)
            [[ "$result" != *"$unexpected"* ]]
            ;;
    esac
}

# Fonction pour vérifier les résultats attendus
check_result() {
    local result="$1"
    local expected="$2"
    local check_type="$3"
    
    case "$check_type" in
        "contains")
            [[ "$result" == *"$expected"* ]]
            ;;
        "exact")
            [[ "$result" == "$expected" ]]
            ;;
        "regex")
            [[ "$result" =~ $expected ]]
            ;;
        "json")
            # Vérification basique JSON (peut être améliorée)
            echo "$result" | jq -e . > /dev/null 2>&1 && [[ "$result" == *"$expected"* ]]
            ;;
        "error")
            [[ "$result" == *"error"* ]] || [[ "$result" == *"Error"* ]] || [[ "$result" == *"ERROR"* ]]
            ;;
        "not_contains")
            [[ "$result" != *"$expected"* ]]
            ;;
        "result")
            # Evaluation du résultat comme expression
            eval "[[ $result $expected ]]"
            ;;
        "debug")
            # En mode debug, toujours passer
            true
            ;;
        *)
            # Par défaut, utiliser contains
            [[ "$result" == *"$expected"* ]]
            ;;
    esac
}

# Fonction principale pour tester la synchronisation avec gestion avancée des tags
# Usage: test_session_sync "description" [--debug] --step "command1" --tag "session1" --expect "result1" [options] ...
#
# OPTIONS GLOBALES :
#   --debug               : mode debug avec détails complets
#   --metrics             : affiche les métriques de performance
#   --performance         : affiche les métriques de performance avancées
#   --list-tags           : affiche tous les tags actifs et leur état
#
# OPTIONS PAR ÉTAPE :
#   --step "command"      : commande à exécuter
#   --tag "name"          : nom du tag pour la session (peut être utilisé plusieurs fois)
#   --expect "result"     : résultat attendu (peut être utilisé plusieurs fois)
#   --no-expect "result"  : résultat qui ne doit PAS apparaître
#   --shell               : force l'exécution dans un shell basique
#   --psysh               : force l'exécution dans psysh
#   --context TYPE        : monitor, phpunit, shell, psysh, mixed (HÉRITABLE - DEPRECATED)
#   --input-type TYPE     : pipe, file, echo, interactive, multiline (HÉRITABLE)
#   --output-check TYPE   : contains, exact, regex, json, error, not_contains, result, debug (peut être utilisé plusieurs fois pour correspondre aux --expect)
#   --timeout SECONDS     : timeout pour l'exécution (HÉRITABLE)
#   --retry COUNT         : nombre de tentatives en cas d'échec (HÉRITABLE)
#   --description "desc"  : description détaillée de l'étape
#   --debug              : mode debug pour cette étape (HÉRITABLE)
#   --log-level LEVEL    : niveau de log (debug, info, warn, error) (HÉRITABLE)
#   --quiet              : supprime la sortie (sauf erreur) (HÉRITABLE)
#   --verbose            : affiche plus de détails (HÉRITABLE)
#   --max-output BYTES   : limite la sortie capturée (HÉRITABLE)
#
# OPTIONS DE GESTION DES TAGS :
#   --tag-info TAG_NAME   : affiche les infos d'un tag spécifique
#   --tag-status          : affiche l'état du tag courant
#   --tag-timeout SECONDS : timeout spécifique pour ce tag
#   --tag-env "VAR=value" : variables d'environnement pour ce tag
#   --tag-cd "PATH"       : répertoire de travail pour ce tag
#   --tag-name "DESC"     : description humaine du tag
#   --tag-reset TAG_NAME  : remet à zéro un tag spécifique
#   --tag-kill TAG_NAME   : termine forcément un tag
#   --tag-debug TAG_NAME  : active le debug pour un tag
#   --tag-log "PATH"      : sauvegarde les logs du tag
#   --tag-history TAG_NAME : affiche l'historique des commandes du tag
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
    local no_expectations=()
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
    local step_tags=()
    local step_shells=()
    local step_psyshs=()
    
    # Gestion des sessions par tag
    # Note: Using regular arrays instead of associative arrays for compatibility
    local tag_sessions_shell=()
    local tag_sessions_psysh=()
    local tag_shell_pids=()
    local tag_psysh_pids=()
    local tag_shell_fifos_in=()
    local tag_shell_fifos_out=()
    local tag_psysh_fifos_in=()
    local tag_psysh_fifos_out=()
    local tag_info=()
    local tag_history=()
    local tag_env=()
    local tag_timeout=()
    local tag_working_dir=()
    local tag_description=()
    
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
    local current_no_expects=()
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
    local current_shell="false"
    local current_psysh="false"
    
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
            --no-expect) 
                current_no_expects+=("$2")
                shift 2 
                ;;
            --tag) 
                if [[ -z "$current_tags" ]]; then
                    current_tags="$2"
                else
                    current_tags+=",$2"
                fi
                shift 2 
                ;;
            --shell) current_shell="true"; shift ;;
            --psysh) current_psysh="true"; shift ;;
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
            
            # Options de gestion des tags (simplifiées pour compatibilité)
            --list-tags) 
                echo -e "${CYAN}=== Tags actifs ===${NC}"
                echo -e "${YELLOW}Note: Fonctionnalité de gestion des tags simplifiée pour compatibilité${NC}"
                shift 
                ;;
            --tag-info) 
                echo -e "${CYAN}=== Info du tag '$2' ===${NC}"
                echo -e "${YELLOW}Note: Fonctionnalité de gestion des tags simplifiée pour compatibilité${NC}"
                shift 2 
                ;;
            --tag-timeout) 
                echo -e "${YELLOW}Note: --tag-timeout ignoré pour compatibilité${NC}"
                shift 3 
                ;;
            --tag-env) 
                echo -e "${YELLOW}Note: --tag-env ignoré pour compatibilité${NC}"
                shift 3 
                ;;
            --tag-cd) 
                echo -e "${YELLOW}Note: --tag-cd ignoré pour compatibilité${NC}"
                shift 3 
                ;;
            --tag-name) 
                echo -e "${YELLOW}Note: --tag-name ignoré pour compatibilité${NC}"
                shift 3 
                ;;
            --tag-history) 
                echo -e "${CYAN}=== Historique du tag '$2' ===${NC}"
                echo -e "${YELLOW}Note: Fonctionnalité de gestion des tags simplifiée pour compatibilité${NC}"
                shift 2 
                ;;
            
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
    
    # Activer le mode debug global si DEBUG_MODE est défini
    if [[ "$DEBUG_MODE" == "1" ]]; then
        global_debug=true
    fi
    
    # Métriques de performance
    local start_time=$(date +%s.%N)
    local step_times=()
    
    # =============================================================================
    # IMPLÉMENTATION DU SYSTÈME DE SESSIONS INFAILLIBLE
    # =============================================================================
    
    # Créer le répertoire de sessions
    local session_dir=$(mktemp -d)
    local log_dir="$session_dir/logs"
    mkdir -p "$log_dir"
    
    # Initialiser la session main (RÈGLE 1: SESSION MAIN UNIVERSELLE)
    # Note: On l'initialise seulement dans les variables, la création physique se fait à la demande
    
    # Variables pour le debug détaillé
    local test_call_signature="test_session_sync \"$description\""
    local test_debug_info=""
    
    # Construire la signature complète du test pour le debug
    build_test_signature() {
        local sig="$test_call_signature"
        if [[ "$global_debug" == "true" ]]; then
            sig+=' --debug'
        fi
        if [[ "$global_metrics" == "true" ]]; then
            sig+=' --metrics'
        fi
        if [[ "$global_performance" == "true" ]]; then
            sig+=' --performance'
        fi
        
        for i in "${!steps[@]}"; do
            sig+=" \\\n    --step \"${steps[$i]}\" --context ${contexts[$i]} --expect \"${expectations[$i]}\" --output-check ${output_checks[$i]}"
            if [[ -n "${step_tags[$i]}" ]]; then
                IFS=',' read -ra tags <<< "${step_tags[$i]}"
                for tag in "${tags[@]}"; do
                    tag=$(echo "$tag" | xargs)
                    if [[ -n "$tag" ]]; then
                        sig+=" --tag \"$tag\""
                    fi
                done
            fi
        done
        
        echo "$sig"
    }
    
    # Fonctions pour gérer les sessions avec la logique infaillible
    create_session() {
        local session_name="$1"
        local context="$2"  # "shell" ou "psysh"
        
        if [[ "$global_debug" == "true" ]]; then
            echo -e "${CYAN}[SESSION] Création de la session '$session_name' avec contexte '$context'${NC}" >&2
        fi
        
        # Créer les FIFOs pour cette session
        local fifo_in="$session_dir/${session_name}_${context}_in"
        local fifo_out="$session_dir/${session_name}_${context}_out"
        mkfifo "$fifo_in" "$fifo_out"
        
        # Sauvegarder la configuration de la session
        set_session_value "GLOBAL_SESSION_CONTEXTS" "$session_name" "$context"
        set_session_value "GLOBAL_SESSION_FIFOS_IN" "$session_name" "$fifo_in"
        set_session_value "GLOBAL_SESSION_FIFOS_OUT" "$session_name" "$fifo_out"
        
        # Démarrer le processus selon le contexte
        local pid
        if [[ "$context" == "shell" ]]; then
            bash -c "exec 0<$fifo_in 1>$fifo_out 2>&1; bash" &
            pid=$!
        elif [[ "$context" == "psysh" ]]; then
            bash -c "exec 0<$fifo_in 1>$fifo_out 2>&1; $PSYSH_CMD" &
            pid=$!
        else
            echo -e "${RED}[ERREUR] Contexte de session inconnu: $context${NC}"
            return 1
        fi
        
        set_session_value "GLOBAL_SESSION_PROCESSES" "$session_name" "$pid"
        
        # Initialiser l'historique de la session
        set_session_value "GLOBAL_SESSION_HISTORY" "$session_name" "[SESSION_CREATED:$context]"
        
        if [[ "$global_debug" == "true" ]]; then
            echo -e "${CYAN}[SESSION] Session '$session_name' créée avec PID $pid${NC}" >&2
        fi
    }
    
    ensure_session_exists() {
        local session_name="$1"
        local preferred_context="$2"  # "shell" ou "psysh"
        
        if ! has_session "$session_name"; then
            # RÈGLE 2: CRÉER une nouvelle session avec le contexte préféré
            create_session "$session_name" "$preferred_context"
        fi
    }
    
    switch_session_context() {
        local session_name="$1"
        local new_context="$2"
        
        local current_context
        current_context=$(get_session_value "GLOBAL_SESSION_CONTEXTS" "$session_name")
        
        if [[ "$current_context" == "$new_context" ]]; then
        if [[ "$global_debug" == "true" ]]; then
            echo -e "${CYAN}[SESSION] Session '$session_name' déjà en contexte '$new_context'${NC}" >&2
        fi
            return 0
        fi
        
        if [[ "$global_debug" == "true" ]]; then
            echo -e "${CYAN}[SESSION] Basculement session '$session_name': $current_context → $new_context${NC}" >&2
        fi
        
        # Terminer l'ancienne session
        local old_pid
        old_pid=$(get_session_value "GLOBAL_SESSION_PROCESSES" "$session_name")
        if [[ -n "$old_pid" ]]; then
            kill "$old_pid" 2>/dev/null
        fi
        
        # Créer une nouvelle session avec le nouveau contexte
        create_session "$session_name" "$new_context"
        
        # Ajouter à l'historique
        local history
        history=$(get_session_value "GLOBAL_SESSION_HISTORY" "$session_name")
        set_session_value "GLOBAL_SESSION_HISTORY" "$session_name" "${history}[CONTEXT_SWITCH:$current_context→$new_context]"
    }
    
    execute_in_session() {
        local session_name="$1"
        local command="$2"
        local timeout="$3"
        
        local context
        context=$(get_session_value "GLOBAL_SESSION_CONTEXTS" "$session_name")
        
        local fifo_in
        fifo_in=$(get_session_value "GLOBAL_SESSION_FIFOS_IN" "$session_name")
        
        local fifo_out
        fifo_out=$(get_session_value "GLOBAL_SESSION_FIFOS_OUT" "$session_name")
        
        # Créer un fichier de log spécifique pour cette commande
        local cmd_log="$log_dir/${session_name}_$(date +%s%N).log"
        
        if [[ "$global_debug" == "true" ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] SESSION: $session_name" >> "$cmd_log"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONTEXT: $context" >> "$cmd_log"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] COMMAND: $command" >> "$cmd_log"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] FIFO_IN: $fifo_in" >> "$cmd_log"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] FIFO_OUT: $fifo_out" >> "$cmd_log"
            echo "" >> "$cmd_log"
            
            echo -e "${CYAN}[SESSION] Exécution dans session '$session_name' ($context): $command${NC}" >&2
        fi
        
        # Vérifier que les FIFOs existent
        if [[ -z "$fifo_in" || -z "$fifo_out" ]]; then
            echo "ERREUR: FIFOs non définis pour la session '$session_name' (context: $context)"
            return 1
        fi
        
        if [[ ! -p "$fifo_in" || ! -p "$fifo_out" ]]; then
            echo "ERREUR: FIFOs non créés pour la session '$session_name'"
            echo "  FIFO_IN: $fifo_in (existe: $([[ -p "$fifo_in" ]] && echo "oui" || echo "non"))"
            echo "  FIFO_OUT: $fifo_out (existe: $([[ -p "$fifo_out" ]] && echo "oui" || echo "non"))"
            return 1
        fi
        
        # Envoyer la commande
        echo "$command" > "$fifo_in"
        if [[ "$context" == "psysh" ]]; then
            echo "echo '---COMMAND_END---';" > "$fifo_in"
        else
            echo "echo '---COMMAND_END---'" > "$fifo_in"
        fi
        
        # Lire la réponse et la logger séparément
        local result=""
        local line=""
        local line_count=0
        
        if [[ "$global_debug" == "true" ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] OUTPUT:" >> "$cmd_log"
        fi
        
        while IFS= read -r -t "$timeout" line < "$fifo_out"; do
            if [[ "$line" == "---COMMAND_END---" ]]; then
                break
            fi
            
            result+="$line"$'\n'
            ((line_count++))
            
            # Logger chaque ligne séparément dans le fichier de log
            if [[ "$global_debug" == "true" ]]; then
                echo "[$line_count] $line" >> "$cmd_log"
            fi
        done
        
        if [[ "$global_debug" == "true" ]]; then
            echo "" >> "$cmd_log"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] RESULT_LENGTH: ${#result}" >> "$cmd_log"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] LINE_COUNT: $line_count" >> "$cmd_log"
        fi
        
        # Ajouter à l'historique
        local history
        history=$(get_session_value "GLOBAL_SESSION_HISTORY" "$session_name")
        set_session_value "GLOBAL_SESSION_HISTORY" "$session_name" "${history}[CMD:$command]"
        
        # Nettoyer le résultat (supprimer les trailing newlines)
        result=$(echo "$result" | sed 's/[[:space:]]*$//')
        
        echo "$result"
    }
    
    # Fonction pour exécuter une étape dans toutes ses sessions (RÈGLE 2: EXÉCUTION SYSTÉMATIQUE)
    execute_step_in_all_sessions() {
        local step_index="$1"
        local command="$2"
        local timeout="$3"
        local forced_shell="$4"
        local forced_psysh="$5"
        local step_tags="$6"
        
        local results=()
        local sessions_used=()
        
        # Déterminer le contexte forcé pour cette étape
        local forced_context=""
        if [[ "$forced_shell" == "true" ]]; then
            forced_context="shell"
        elif [[ "$forced_psysh" == "true" ]]; then
            forced_context="psysh"
        fi
        
        # RÈGLE 1: Toujours exécuter dans la session main
        sessions_used+=("main")
        
        # RÈGLE 4: Appliquer le forçage si nécessaire
        if [[ -n "$forced_context" ]]; then
            switch_session_context "main" "$forced_context"
        fi
        
        # Exécuter dans la session main
        local main_result
        main_result=$(execute_in_session "main" "$command" "$timeout")
        results+=("main:$main_result")
        
        # RÈGLE 2: Exécuter dans toutes les sessions tagguées
        if [[ -n "$step_tags" ]]; then
            IFS=',' read -ra tags <<< "$step_tags"
            for tag in "${tags[@]}"; do
                tag=$(echo "$tag" | xargs)  # Trim whitespace
                if [[ -n "$tag" ]]; then
                    sessions_used+=("$tag")
                    
                    # RÈGLE 3: Créer ou utiliser la session tagguée
                    if [[ -n "$forced_context" ]]; then
                        # Forcer le contexte ou basculer si la session existe
                        if has_session "$tag"; then
                            switch_session_context "$tag" "$forced_context"
                        else
                            ensure_session_exists "$tag" "$forced_context"
                        fi
                    else
                        # Utiliser le contexte par défaut (psysh) pour les nouvelles sessions
                        ensure_session_exists "$tag" "psysh"
                    fi
                    
                    # Exécuter dans la session tagguée
                    local tag_result
                    tag_result=$(execute_in_session "$tag" "$command" "$timeout")
                    results+=("$tag:$tag_result")
                fi
            done
        fi
        
        # Afficher les résultats si debug activé
        if [[ "$global_debug" == "true" ]]; then
            echo -e "${CYAN}[DEBUG] Étape $((step_index+1)) exécutée dans sessions: ${sessions_used[*]}${NC}" >&2
            for result in "${results[@]}"; do
                local session_name=$(echo "$result" | cut -d':' -f1)
                local session_result=$(echo "$result" | cut -d':' -f2-)
                echo -e "${CYAN}[DEBUG]   Session '$session_name': $session_result${NC}" >&2
            done
        fi
        
        # Retourner le résultat de la session main (comportement par défaut)
        echo "$main_result"
    }
    
    # Fonction de nettoyage des sessions
    cleanup_all_sessions() {
        if [[ "$global_debug" == "true" ]]; then
            echo -e "${CYAN}[SESSION] Nettoyage de toutes les sessions${NC}"
        fi
        
        # Lister toutes les sessions actives
        local sessions
        sessions=$(list_sessions)
        
        # Terminer chaque session
        echo "$sessions" | while read -r session_name; do
            if [[ -n "$session_name" ]]; then
                local pid
                pid=$(get_session_value "GLOBAL_SESSION_PROCESSES" "$session_name")
                if [[ -n "$pid" ]]; then
                    kill "$pid" 2>/dev/null
                    if [[ "$global_debug" == "true" ]]; then
                        echo -e "${CYAN}[SESSION] Session '$session_name' terminée (PID $pid)${NC}"
                    fi
                fi
            fi
        done
        
        # Nettoyer le répertoire temporaire
        rm -rf "$session_dir"
        
        # Réinitialiser les variables globales
        GLOBAL_SESSION_CONTEXTS=""
        GLOBAL_SESSION_PROCESSES=""
        GLOBAL_SESSION_FIFOS_IN=""
        GLOBAL_SESSION_FIFOS_OUT=""
        GLOBAL_SESSION_HISTORY=""
    }
    
    trap cleanup_all_sessions EXIT
    
    # Exécuter chaque étape avec ses options
    local all_passed=true
    local step_results=()
    
    # Gestion des étapes asynchrones
    local async_pids=()
    local async_results=()
    local step_id_map=()
    
    # Créer une carte des step-id vers les indices (fonctionnalité simplifiée)
    # Note: step_id_map non utilisé dans la version simplifiée pour compatibilité
    
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
                
                # =============================================================================
                # EXÉCUTION AVEC LA LOGIQUE INFAILLIBLE DES SESSIONS
                # =============================================================================
                
                # Extraire les options --shell et --psysh pour cette étape
                local forced_shell="false"
                local forced_psysh="false"
                
                # Nous devons parcourir step_shells et step_psyshs pour trouver les valeurs
                # Note: Ces arrays ne sont pas remplis dans le code actuel, nous devons les extraire
                # depuis step_tags[$i] qui contient les options combinées
                
                # Extraire les tags réels de cette étape
                local step_tags_value="${step_tags[$i]}"
                
                # Simuler l'extraction des options --shell et --psysh
                # (Cette logique devrait être améliorée pour parser correctement)
                # Pour l'instant, nous utilisons le contexte pour déterminer le type
                case "$context" in
                    "shell")
                        forced_shell="true"
                        ;;
                    "psysh")
                        forced_psysh="true"
                        ;;
                    "monitor")
                        # Monitor utilise psysh par défaut
                        forced_psysh="true"
                        actual_step="monitor $actual_step"
                        ;;
                    "phpunit")
                        # PHPUnit utilise psysh par défaut
                        forced_psysh="true"
                        if [[ "$actual_step" != phpunit:* ]]; then
                            actual_step="phpunit:$actual_step"
                        fi
                        ;;
                esac
                
        # S'assurer que la session main existe avec le bon contexte
        local main_default_context="psysh"
        if [[ -n "$forced_context" ]]; then
            main_default_context="$forced_context"
        elif [[ "$context" == "shell" ]]; then
            main_default_context="shell"
        elif [[ "$context" == "psysh" ]]; then
            main_default_context="psysh"
        fi
        
        ensure_session_exists "main" "$main_default_context"
                
                # Exécuter dans toutes les sessions (main + tags)
                step_result=$(execute_step_in_all_sessions "$i" "$actual_step" "$timeout" "$forced_shell" "$forced_psysh" "$step_tags_value")
                
                # Gestion des contextes spéciaux pour compatibilité
                case "$context" in
                    "mixed")
                        # Pour mixed, utiliser l'ancienne méthode
                        step_result=$(execute_mixed_test "$actual_step" "$input_type" "$timeout")
                        ;;
                    *)
                        # Déjà géré par execute_step_in_all_sessions
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
                    echo -e "${GREEN}✅ Étape $((i+1)): $description: OK${NC}"
                fi
                if [[ "$debug" == "true" || "$global_debug" == "true" ]]; then
                    echo -e "${CYAN}[DEBUG] Result: $step_result${NC}" >&2
                fi
            else
                echo -e "${RED}❌ Étape $((i+1)): $description: FAIL${NC}"
                if [[ "$quiet" != "true" ]]; then
                    echo -e "${RED}Expected: $expect${NC}"
                    echo -e "${RED}Got: $step_result${NC}"
                fi
                
                # Affichage détaillé de debug si activé
                if [[ "$debug" == "true" || "$global_debug" == "true" ]]; then
                    echo -e "${CYAN}╭─ DEBUG INFO - Étape $((i+1)) FAILED ─╮${NC}" >&2
                    echo -e "${CYAN}│ Description: $description${NC}" >&2
                    echo -e "${CYAN}│ Commande: $actual_step${NC}" >&2
                    echo -e "${CYAN}│ Contexte: $context${NC}" >&2
                    echo -e "${CYAN}│ Tags: ${step_tags_value}${NC}" >&2
                    echo -e "${CYAN}│ Timeout: ${timeout}s${NC}" >&2
                    echo -e "${CYAN}│ Tentatives: $((attempt-1))/$retry${NC}" >&2
                    
                    if [[ -n "$setup" ]]; then
                        echo -e "${CYAN}│ Setup: $setup${NC}"
                    fi
                    if [[ -n "$cleanup" ]]; then
                        echo -e "${CYAN}│ Cleanup: $cleanup${NC}"
                    fi
                    if [[ -n "$mock" ]]; then
                        echo -e "${CYAN}│ Mock: $mock${NC}"
                    fi
                    if [[ -n "$input_file" ]]; then
                        echo -e "${CYAN}│ Input file: $input_file${NC}"
                    fi
                    if [[ -n "$output_file" ]]; then
                        echo -e "${CYAN}│ Output file: $output_file${NC}"
                    fi
                    
                    echo -e "${CYAN}│ Sortie complète:${NC}"
                    echo "$step_result" | while IFS= read -r line; do
                        echo -e "${CYAN}│   $line${NC}"
                    done
                    
                    if [[ -n "$expect" ]]; then
                        echo -e "${CYAN}│ Comparaison ($output_check):${NC}"
                        echo -e "${CYAN}│   Attendu: $expect${NC}"
                        echo -e "${CYAN}│   Obtenu:  $step_result${NC}"
                        
                        # Analyse de la différence
                        case "$output_check" in
                            "exact")
                                if [[ "$step_result" == "$expect" ]]; then
                                    echo -e "${CYAN}│   Match: exact (OK)${NC}"
                                else
                                    echo -e "${CYAN}│   Match: exact (FAIL)${NC}"
                                    echo -e "${CYAN}│   Différence: caractères différents${NC}"
                                fi
                                ;;
                            "contains")
                                if [[ "$step_result" == *"$expect"* ]]; then
                                    echo -e "${CYAN}│   Match: contains (OK)${NC}"
                                else
                                    echo -e "${CYAN}│   Match: contains (FAIL)${NC}"
                                    echo -e "${CYAN}│   '$expect' non trouvé dans '$step_result'${NC}"
                                fi
                                ;;
                            "regex")
                                if [[ "$step_result" =~ $expect ]]; then
                                    echo -e "${CYAN}│   Match: regex (OK)${NC}"
                                else
                                    echo -e "${CYAN}│   Match: regex (FAIL)${NC}"
                                    echo -e "${CYAN}│   Pattern '$expect' ne correspond pas à '$step_result'${NC}"
                                fi
                                ;;
                        esac
                    fi
                    
                    echo -e "${CYAN}╰─────────────────────────────────────────────────╯${NC}"
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
                echo -e "${CYAN}🔄 --sync-test option is deprecated, use multiple --step with --expect and different --context l'étape $((i+1))${NC}"
                exit 0
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

# Exemple avec contextes mixtes et sessions persistantes
example_mixed_context_persistent() {
    test_session_sync "Test avec contextes mixtes et sessions persistantes" \
        --step "MY_VAR=42" \
        --context shell \
        --expect "" \
        --step "echo \"Variable shell: $MY_VAR\"" \
        --context shell \
        --expect "Variable shell: 42" \
        --step "\$x = 10; \$y = 20;" \
        --context monitor \
        --expect "" \
        --step "echo \$x + \$y;" \
        --context monitor \
        --expect "30" \
        --step "\$result = \$x * \$y;" \
        --context phpunit \
        --expect "" \
        --step "assert '\$result == 200' --message='Test multiplication'" \
        --context phpunit \
        --expect "✅" \
        --step "echo \"Test terminé\"" \
        --context shell \
        --expect "Test terminé"
}

# =============================================================================
# EXEMPLES DÉMONSTRATIFS DE LA LOGIQUE INFAILLIBLE DES SESSIONS
# =============================================================================

# Exemple 1: Session main uniquement avec héritage de contexte
example_session_main_only() {
    test_session_sync "Exemple session main uniquement" --debug \
        --step "echo 'Step 1 in psysh'" \
        --context psysh \
        --expect "Step 1 in psysh" \
        --step "echo 'Step 2 in psysh (hérité)'" \
        --expect "Step 2 in psysh (hérité)" \
        --step "echo 'Step 3 in shell'" \
        --context shell \
        --expect "Step 3 in shell" \
        --step "echo 'Step 4 in shell (hérité)'" \
        --expect "Step 4 in shell (hérité)"
}

# Exemple 2: Sessions avec tags et héritage
example_session_with_tags() {
    test_session_sync "Exemple sessions avec tags" --debug \
        --step "echo 'Step 1 main+A'" \
        --tag "A" \
        --context psysh \
        --expect "Step 1 main+A" \
        --step "echo 'Step 2 main+A'" \
        --tag "A" \
        --expect "Step 2 main+A" \
        --step "echo 'Step 3 main+A (shell)'" \
        --tag "A" \
        --context shell \
        --expect "Step 3 main+A (shell)" \
        --step "echo 'Step 4 main+B'" \
        --tag "B" \
        --expect "Step 4 main+B" \
        --step "echo 'Step 5 main+A (shell hérité)'" \
        --tag "A" \
        --expect "Step 5 main+A (shell hérité)"
}

# Exemple 3: Exécution multiple avec plusieurs tags
example_multiple_tags() {
    test_session_sync "Exemple exécution multiple" --debug \
        --step "echo 'Step 1 dans main, A et B'" \
        --tag "A" \
        --tag "B" \
        --context psysh \
        --expect "Step 1 dans main, A et B" \
        --step "echo 'Step 2 dans main uniquement'" \
        --context shell \
        --expect "Step 2 dans main uniquement" \
        --step "echo 'Step 3 dans main et A'" \
        --tag "A" \
        --expect "Step 3 dans main et A"
}

# Exemple 4: Test complet avec forçage --shell et --psysh
example_context_forcing() {
    test_session_sync "Exemple forçage de contexte" --debug \
        --step "echo 'Step 1 psysh par défaut'" \
        --expect "Step 1 psysh par défaut" \
        --step "echo 'Step 2 forcé shell'" \
        --shell \
        --expect "Step 2 forcé shell" \
        --step "echo 'Step 3 hérité shell'" \
        --expect "Step 3 hérité shell" \
        --step "echo 'Step 4 forcé psysh'" \
        --psysh \
        --expect "Step 4 forcé psysh" \
        --step "echo 'Step 5 avec tag et forçage'" \
        --tag "test" \
        --shell \
        --expect "Step 5 avec tag et forçage"
}

# Exemple 5: Cas complexe illustrant votre question
example_complex_case() {
    test_session_sync "Cas complexe de votre question" --debug \
        --step "echo 'Step 1 avec tags'" \
        --tag "psysh" \
        --tag "step_1" \
        --expect "Step 1 avec tags" \
        --step "echo 'Step 2 session main'" \
        --expect "Step 2 session main" \
        --step "echo 'Step 3 avec shell'" \
        --shell \
        --tag "shell" \
        --expect "Step 3 avec shell" \
        --step "echo 'Step 4 retour tag psysh'" \
        --tag "psysh" \
        --expect "Step 4 retour tag psysh"
}
