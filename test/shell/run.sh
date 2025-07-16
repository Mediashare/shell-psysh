#!/bin/bash

# Script principal pour exécuter les tests PsySH Enhanced
# Architecture modulaire avec séparation des responsabilités

# Obtenir le répertoire du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Charger la configuration et les utilitaires
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/lib/display_utils.sh"
source "$SCRIPT_DIR/lib/unified_test_executor.sh"
source "$SCRIPT_DIR/lib/psysh_utils.sh"
source "$SCRIPT_DIR/lib/timeout_handler.sh"

# Revenir au répertoire des tests
cd "$SCRIPT_DIR"

# Découvrir tous les tests disponibles
tests=()
temp_file=$(mktemp)
find "$SCRIPT_DIR/Command" -name "*.sh" -type f | sort > "$temp_file"

while IFS= read -r full_path; do
    # Extraire le chemin relatif depuis le répertoire tests
    relative_path="${full_path#$SCRIPT_DIR/}"
    tests+=("$relative_path")
done < "$temp_file"

rm -f "$temp_file"

# Vérifier que nous avons trouvé des tests
if [[ ${#tests[@]} -eq 0 ]]; then
    echo -e "${RED}❌ Aucun fichier de test trouvé dans $SCRIPT_DIR/Command${NC}"
    exit 1
fi

# Rendre tous les scripts exécutables
for test_file in "${tests[@]}"; do
    if [[ -f "$test_file" ]]; then
        chmod +x "$test_file"
    fi
done

# Afficher les tests découverts
echo -e "${CYAN}📂 Tests découverts: ${#tests[@]} fichiers${NC}"
for i in "${!tests[@]}"; do
    echo -e "${BLUE}  $((i+1)).${NC} ${tests[$i]}"
done
echo ""

# Fonction pour afficher le header d'un test
show_test_header() {
    local test_file=$1
    local test_num=$2
    local total=$3
    
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}🧪 TEST ${test_num}/${total}${NC} : ${GREEN}$test_file${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Variable pour le mode automatique
AUTO_MODE=${AUTO_MODE:-0}
# Variable pour le mode simple
SIMPLE_MODE=${SIMPLE_MODE:-0}
# Variable pour pause sur échec
PAUSE_ON_FAIL=${PAUSE_ON_FAIL:-0}
# Variable pour tracker si simple mode a été explicitement demandé
EXPLICIT_SIMPLE_MODE=0

# Fonction pour attendre une action utilisateur
wait_for_action() {
    local message=$1
    echo ""
    # --pause-on-fail override AUTO_MODE pour les pauses
    if [[ $AUTO_MODE == "1" && $PAUSE_ON_FAIL != "1" ]]; then
        echo -e "${PURPLE}$message (AUTO MODE: continuing automatically)${NC}"
        sleep 1
        return 0
    fi
    echo -e "${PURPLE}$message${NC}"
    read -s -n 1 key
    if [[ $key == $'\e' ]]; then
        return 1  # Escape pressed
    fi
    return 0  # Enter or other key pressed
}

# Fonction pour générer une stack trace shell RÉELLE et utilisable (compatible POSIX)
generate_shell_stack_trace() {
    local temp_output=$1
    local main_test_file=$2
    
    echo -e "   ${PURPLE}🔍 CALL STACK - Chemin d'exécution réel:${NC}"
    
    # 1. Extraire la stack d'appels de fonctions depuis les logs TRACE
    echo -e "   ${CYAN}📞 Pile des appels de fonctions:${NC}"
    local call_stack=$(grep -n "\[TRACE\]" "$temp_output" | grep -E "(ENTER|EXIT)" | tail -10)
    if [[ -n "$call_stack" ]]; then
        echo "$call_stack" | while IFS= read -r trace_line; do
            local line_num=$(echo "$trace_line" | cut -d: -f1)
            local trace_content=$(echo "$trace_line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
            
            # Extraire le fichier et la ligne d'appel avec sed
            if echo "$trace_content" | grep -q "ENTER:"; then
                local func_name=$(echo "$trace_content" | sed 's/.*ENTER: \([^|]*\).*/\1/' | sed 's/().*//g')
                local file_info=$(echo "$trace_content" | sed -n 's/.*Fichier: \([^:]*\):\([0-9]*\).*/\1:\2/p')
                if [[ -n "$file_info" ]]; then
                    local file_name=$(echo "$file_info" | cut -d: -f1)
                    local file_line=$(echo "$file_info" | cut -d: -f2)
                    echo -e "   ${GREEN}   ↘ $func_name()${NC} ${CYAN}[$(basename "$file_name"):$file_line]${NC}"
                else
                    echo -e "   ${GREEN}   ↘ $func_name()${NC}"
                fi
            elif echo "$trace_content" | grep -q "EXIT:"; then
                local func_name=$(echo "$trace_content" | sed 's/.*EXIT: \([^|]*\).*/\1/' | sed 's/().*//g')
                local file_info=$(echo "$trace_content" | sed -n 's/.*Fichier: \([^:]*\):\([0-9]*\).*/\1:\2/p')
                if [[ -n "$file_info" ]]; then
                    local file_name=$(echo "$file_info" | cut -d: -f1)
                    local file_line=$(echo "$file_info" | cut -d: -f2)
                    echo -e "   ${RED}   ↙ $func_name()${NC} ${CYAN}[$(basename "$file_name"):$file_line]${NC}"
                else
                    echo -e "   ${RED}   ↙ $func_name()${NC}"
                fi
            fi
        done
    else
        echo -e "   ${YELLOW}   ⚠️ Aucune trace ENTER/EXIT détectée${NC}"
    fi
    
    # 2. Séquence d'exécution avec contexte
    echo -e "\n   ${PURPLE}⚡ Séquence d'exécution détaillée:${NC}"
    local execution_sequence=$(grep -n -E "(\[DEBUG\] Command:|\[TRACE\].*Paramètres:|>>> Étape|❌ FAIL:|✅ PASS:)" "$temp_output" | head -15)
    if [[ -n "$execution_sequence" ]]; then
        echo "$execution_sequence" | while IFS= read -r exec_line; do
            local line_num=$(echo "$exec_line" | cut -d: -f1)
            local exec_content=$(echo "$exec_line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
            
            # Formater selon le type de ligne
            if echo "$exec_content" | grep -q "^\[DEBUG\] Command:"; then
                local command=$(echo "$exec_content" | sed 's/^\[DEBUG\] Command: //')
                echo -e "   ${BLUE}   🔧 EXEC: ${NC}$command ${CYAN}[ligne $line_num]${NC}"
            elif echo "$exec_content" | grep -q "^\[TRACE\].*Paramètres:"; then
                local params=$(echo "$exec_content" | sed 's/^\[TRACE\].*Paramètres: //')
                echo -e "   ${YELLOW}   📋 PARAMS: ${NC}$params ${CYAN}[ligne $line_num]${NC}"
            elif echo "$exec_content" | grep -q "^>>> Étape"; then
                echo -e "   ${PURPLE}   📌 STEP: ${NC}$exec_content ${CYAN}[ligne $line_num]${NC}"
            elif echo "$exec_content" | grep -q "^❌ FAIL:"; then
                echo -e "   ${RED}   💥 FAIL: ${NC}$exec_content ${CYAN}[ligne $line_num]${NC}"
            elif echo "$exec_content" | grep -q "^✅ PASS:"; then
                echo -e "   ${GREEN}   ✅ PASS: ${NC}$exec_content ${CYAN}[ligne $line_num]${NC}"
            fi
        done
    fi
    
    # 3. Analyse des fichiers shell réellement impliqués
    echo -e "\n   ${PURPLE}📂 Fichiers shell impliqués:${NC}"
    
    # Extraire tous les fichiers mentionnés dans les traces
    local involved_files=$(grep "Fichier:" "$temp_output" | sed 's/.*Fichier: \([^:]*\):[0-9]*.*/\1/' | sort -u)
    if [[ -n "$involved_files" ]]; then
        echo "$involved_files" | while IFS= read -r file_path; do
            if [[ -f "$file_path" ]]; then
                echo -e "   ${CYAN}   📄 $(basename "$file_path")${NC} ${GRAY}[$file_path]${NC}"
                # Montrer les fonctions de ce fichier qui sont appelées
                local file_functions=$(grep "Fichier: $file_path" "$temp_output" | grep "ENTER:" | sed 's/.*ENTER: \([^|]*\).*/\1/' | sed 's/().*//g' | sort -u)
                if [[ -n "$file_functions" ]]; then
                    echo "$file_functions" | while IFS= read -r func_name; do
                        echo -e "   ${GREEN}     ↳ $func_name()${NC}"
                    done
                fi
            fi
        done
    fi
    
    # 4. Point d'erreur précis avec stack
    echo -e "\n   ${PURPLE}💥 Point d'erreur avec contexte:${NC}"
    local error_context=$(grep -B 5 -A 5 -E "(RuntimeException|Fatal error|command not found|syntax error)" "$temp_output" | head -20)
    if [[ -n "$error_context" ]]; then
        echo "$error_context" | nl -w3 -s': ' | while IFS= read -r context_line; do
            if echo "$context_line" | grep -qE "(RuntimeException|Fatal error|command not found|syntax error)"; then
                echo -e "   ${RED}   → $context_line${NC}"
            elif echo "$context_line" | grep -qE "(\[TRACE\]|\[DEBUG\])"; then
                echo -e "   ${YELLOW}   $context_line${NC}"
            else
                echo -e "   ${GRAY}   $context_line${NC}"
            fi
        done
    else
        echo -e "   ${YELLOW}   ⚠️ Point d'erreur non identifié dans les logs${NC}"
    fi
    
    # 5. Chemin d'exécution reconstruit
    echo -e "\n   ${PURPLE}🗺️ Chemin d'exécution reconstruit:${NC}"
    local execution_path=$(grep -n "\[TRACE\]" "$temp_output" | grep -E "(ENTER|Appelé depuis)" | tail -8)
    if [[ -n "$execution_path" ]]; then
        echo "$execution_path" | while IFS= read -r path_line; do
            local line_num=$(echo "$path_line" | cut -d: -f1)
            local path_content=$(echo "$path_line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
            
            if echo "$path_content" | grep -q "Appelé depuis:"; then
                local caller_info=$(echo "$path_content" | sed 's/.*Appelé depuis: \([^:]*\):\([0-9]*\).*/\1:\2/')
                if [[ -n "$caller_info" && "$caller_info" != "$path_content" ]]; then
                    local caller_file=$(echo "$caller_info" | cut -d: -f1)
                    local caller_line=$(echo "$caller_info" | cut -d: -f2)
                    echo -e "   ${BLUE}   📍 Called from: ${NC}$(basename "$caller_file"):$caller_line ${CYAN}[output ligne $line_num]${NC}"
                fi
            elif echo "$path_content" | grep -q "ENTER:"; then
                local func_name=$(echo "$path_content" | sed 's/.*ENTER: \([^|]*\).*/\1/' | sed 's/().*//g')
                echo -e "   ${GREEN}   🔄 Entering: ${NC}$func_name() ${CYAN}[output ligne $line_num]${NC}"
            fi
        done
    else
        echo -e "   ${YELLOW}   ⚠️ Chemin d'exécution non tracé${NC}"
    fi
}


# Fonction pour exécuter un test en mode simple
run_test_simple() {
    local test_file=$1
    local test_num=$2
    local total=$3
    
    # Affichage minimal
    echo -ne "${BLUE}Test $test_num/$total${NC}: ${test_file} ... "
    
    if [ ! -f "$test_file" ]; then
        echo -e "${RED}ERREUR: Fichier non trouvé${NC}"
        return 1
    fi
    
    # Capturer temporairement la sortie
    local temp_output=$(mktemp)
    
    # Exporter les variables nécessaires pour les sous-scripts
    
    # Exécuter le test et capturer le code de retour
    env DEBUG_MODE="$DEBUG_MODE" ./$test_file > "$temp_output" 2>&1
    local exit_code=$?
    
    # Capturer les détails du test et extraire les statistiques
    capture_test_details "$test_file" "$temp_output"
    capture_debug_details "$test_file" "$temp_output" $exit_code
    
    # Extraire les statistiques des étapes pour affichage
    local step_stats=""
    if [[ -f "$temp_output" ]]; then
        # Détecter à la fois l'ancien et le nouveau format des étapes
        local total_steps_old
        total_steps_old=$(grep -c "Etape [0-9]*:" "$temp_output" 2>/dev/null)
        if [[ -z "$total_steps_old" ]]; then total_steps_old=0; fi
        local total_steps_new
        total_steps_new=$(grep -c ">>> Étape [0-9]*:" "$temp_output" 2>/dev/null)
        if [[ -z "$total_steps_new" ]]; then total_steps_new=0; fi
        local total_steps=$((total_steps_old + total_steps_new))
        local passed_steps=$(grep -c "✅ PASS:" "$temp_output" 2>/dev/null || echo "0")
        local failed_steps=$(grep -c "❌ FAIL:" "$temp_output" 2>/dev/null || echo "0")
        
        # Remove any potential newlines from the variables and ensure they're valid numbers
        total_steps=${total_steps//[[:space:]]/}
        passed_steps=${passed_steps//[[:space:]]/}
        failed_steps=${failed_steps//[[:space:]]/}
        
        # Ensure we have valid numeric values (default to 0 if empty or invalid)
        case "$total_steps" in ''|*[!0-9]*) total_steps=0;; esac
        case "$passed_steps" in ''|*[!0-9]*) passed_steps=0;; esac
        case "$failed_steps" in ''|*[!0-9]*) failed_steps=0;; esac
        
        # Update to reflect accurate step stats
        step_stats=" (${passed_steps}/${failed_steps}/${total_steps} étapes)"
        # Fix exit status determination if there are failed steps
        if [[ $failed_steps -gt 0 ]]; then
            exit_code=1
        fi
    fi
    
    # Le mode debug est maintenant géré directement dans test_session_sync
    # Pas besoin d'affichage supplémentaire ici
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ SUCCESS${NC}${step_stats}"
        
        # Vérification de cohérence : si exit_code=0 mais aucune étape réussie, signaler
        if [[ -f "$temp_output" ]]; then
            # Utiliser la même logique que plus haut pour détecter les étapes
            local total_steps_old
            total_steps_old=$(grep -c "Etape [0-9]*:" "$temp_output" 2>/dev/null)
            if [[ -z "$total_steps_old" ]]; then total_steps_old=0; fi
            local total_steps_new
            total_steps_new=$(grep -c ">>> Étape [0-9]*:" "$temp_output" 2>/dev/null)
            if [[ -z "$total_steps_new" ]]; then total_steps_new=0; fi
            local total_steps=$((total_steps_old + total_steps_new))
            local passed_steps=$(grep -c "✅ PASS:" "$temp_output" 2>/dev/null || echo "0")
            local failed_steps=$(grep -c "❌ FAIL:" "$temp_output" 2>/dev/null || echo "0")
            
            # Remove any potential newlines from the variables
            total_steps=${total_steps//[[:space:]]/}
            passed_steps=${passed_steps//[[:space:]]/}
            failed_steps=${failed_steps//[[:space:]]/}
            
            # Alerte si succès mais aucune étape détectée
            if [[ $total_steps -eq 0 ]]; then
                echo -e "   ${YELLOW}⚠️  Attention: Aucune étape détectée dans ce test${NC}"
            elif [[ $passed_steps -eq 0 && $failed_steps -eq 0 ]]; then
                echo -e "   ${YELLOW}⚠️  Attention: Aucun résultat PASS/FAIL détecté${NC}"
            elif [[ $failed_steps -gt 0 ]]; then
                echo -e "   ${YELLOW}⚠️  Attention: Marqué SUCCESS mais contient des étapes échouées (${failed_steps})${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ FAIL${NC}${step_stats}"
        
        # Si PAUSE_ON_FAIL est activé, afficher les détails et attendre
        if [[ $PAUSE_ON_FAIL == "1" ]]; then
            while true; do
                echo ""
                echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${RED}Détails de l'échec pour $test_file:${NC}"
                echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                
                # Afficher les informations d'échec
                if [[ $DEBUG_MODE == "1" ]]; then
                    # Mode debug: afficher directement les logs debug du test
                    echo -e "${CYAN}🔍 ANALYSE DÉTAILLÉE DE L'ÉCHEC:${NC}"
                    echo ""
                    
                    # Afficher les boîtes debug si elles existent
                    local debug_boxes=$(grep -A 20 "╭─ DEBUG INFO" "$temp_output")
                    if [[ -n "$debug_boxes" ]]; then
                        echo -e "${YELLOW}📋 INFORMATIONS DEBUG:${NC}"
                        echo "$debug_boxes" | while IFS= read -r line; do
                            if [[ "$line" =~ ^╭─ ]]; then
                                echo -e "   ${BLUE}$line${NC}"
                            elif [[ "$line" =~ ^│ ]]; then
                                echo -e "   ${CYAN}$line${NC}"
                            elif [[ "$line" =~ ^╰─ ]]; then
                                echo -e "   ${BLUE}$line${NC}"
                            else
                                echo -e "   $line"
                            fi
                        done
                        echo ""
                    fi
                    
                    # Afficher les étapes qui ont échoué
                    echo -e "${YELLOW}📋 ÉTAPES QUI ONT ÉCHOUÉ:${NC}"
                    grep -B2 -A5 "❌ FAIL:" "$temp_output" | head -30 | while IFS= read -r line; do
                        if [[ "$line" =~ ^❌\ FAIL: ]]; then
                            echo -e "   ${RED}🚫 ${line#❌ FAIL: }${NC}"
                        elif [[ "$line" =~ ^\>\>\>\ Étape ]]; then
                            echo -e "   ${BLUE}📍 ${line}${NC}"
                        elif [[ "$line" =~ ^Expected: ]]; then
                            echo -e "   ${YELLOW}🎯 ATTENDU: ${line#Expected: }${NC}"
                        elif [[ "$line" =~ ^Got: ]]; then
                            echo -e "   ${RED}❌ OBTENU: ${line#Got: }${NC}"
                        elif [[ "$line" =~ ^Étapes\ échouées ]]; then
                            echo -e "   ${RED}💥 ${line}${NC}"
                        elif [[ "$line" =~ ^Étape\ [0-9] ]]; then
                            echo -e "   ${PURPLE}🔍 ${line}${NC}"
                        elif [[ "$line" =~ ^-- ]]; then
                            echo "   ────────────────────────────────────────"
                        fi
                    done
                    
                    echo ""
                    echo -e "${BLUE}⚡ DERNIÈRES COMMANDES:${NC}"
                    
                    # Extraire les commandes debug
                    grep -E "(\[DEBUG\] Étape [0-9]|\[DEBUG\] Commande:|\[DEBUG\] Result:)" "$temp_output" | tail -10 | while IFS= read -r line; do
                        if [[ "$line" =~ ^\[DEBUG\]\ Étape ]]; then
                            echo -e "   ${PURPLE}📋 ${line}${NC}"
                        elif [[ "$line" =~ ^\[DEBUG\]\ Commande: ]]; then
                            echo -e "   ${CYAN}⚡ ${line}${NC}"
                        elif [[ "$line" =~ ^\[DEBUG\]\ Result: ]]; then
                            echo -e "   ${GREEN}📤 ${line}${NC}"
                        fi
                    done
                    
                    echo ""
                    echo -e "${RED}🚨 ERREURS SYSTÈME dans ${YELLOW}$(basename "$test_file")${RED}:${NC}"
                    local system_errors=$(grep -n -E "(RuntimeException|PARSE ERROR|Fatal error|Warning:|command not found|No such file)" "$temp_output" | head -5)
                    if [[ -n "$system_errors" ]]; then
                        echo "$system_errors" | while IFS= read -r line; do
                            if echo "$line" | grep -q "^[[:space:]]*[0-9]"; then
                                local line_num=$(echo "$line" | cut -d: -f1)
                                local error_content=$(echo "$line" | cut -d: -f2-)
                                echo -e "   ${RED}💥 [Ligne $line_num] ${error_content}${NC}"
                                echo ""
                            fi
                        done
                    else
                        echo -e "   ${GREEN}✓ Aucune erreur système${NC}"
                    fi
                else
                    # Mode normal: affichage concis et lisible
                    echo -e "${YELLOW}📋 RÉSUMÉ DE L'ÉCHEC:${NC}"
                    tail -n 50 "$temp_output" | grep -E "(Étape|FAIL|attendu|obtenu|erreur|>>>)" | tail -n 12 | while IFS= read -r line; do
                        if [[ "$line" =~ ^❌\ FAIL: ]]; then
                            echo -e "   ${RED}● ${line#❌ FAIL: }${NC}"
                        elif [[ "$line" =~ ">>>"* ]]; then
                            echo -e "   ${BLUE}📍 ${line}${NC}"
                        else
                            echo -e "   ${CYAN}${line}${NC}"
                        fi
                    done
                fi
                
                echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                echo -e "${YELLOW}Test échoué. Actions disponibles:${NC}"
                echo -e "${GREEN}  ENTRÉE${NC} - Continuer avec le test suivant"
                echo -e "${BLUE}  R${NC} - Relancer ce test"
                echo -e "${RED}  ESC${NC} - Arrêter tous les tests"
                echo ""
                echo -ne "${YELLOW}Votre choix: ${NC}"
                
                read -s -n 1 key
                
                case $key in
                    $'\e')  # ESC
                        echo "ESC - Arrêt"
                        rm -f "$temp_output"
                        return 2  # Signal to stop all tests
                        ;;
                    'r'|'R')
                        echo "R - Relance du test"
                        echo ""
                        echo -e "${YELLOW}🔄 Relance du test $test_file...${NC}"
                        # Relancer le test (on sort de la boucle pour recommencer)
                        rm -f "$temp_output"
                        return 3  # Signal to retry
                        ;;
                    *) # ENTRÉE ou autre touche
                        echo "ENTRÉE - Continue"
                        break  # Sortir de la boucle while, continuer avec le test suivant
                        ;;
                esac
            done
        fi
    fi
    
    rm -f "$temp_output"
    return $exit_code
}

# Fonction pour exécuter un test
run_test() {
    local test_file=$1
    local test_num=$2
    local total=$3
    
    show_test_header "$test_file" "$test_num" "$total"
    
    if [ ! -f "$test_file" ]; then
        echo -e "${RED}❌ Fichier non trouvé: $test_file${NC}"
        # modify to skip if no steps detected
        if [[ $total_steps -eq 0 ]]; then
            echo -e "${YELLOW}⚠️  SKIPPED: Aucune étape détectée${NC}"
        elif [[ $AUTO_MODE != "1" ]]; then
            sleep 2
        fi
        return
    fi
    
    # Afficher un aperçu du test
    echo -e "${BLUE}📄 Description du test:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    grep "^# Test" "$test_file" | head -3
    echo ""
    
    echo -e "${BLUE}💻 Code principal du test:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Détecter le type de test (nouveau avec test_monitor ou ancien avec monitor direct)
    if grep -q "^test_monitor" "$test_file"; then
        # Nouveau format avec fonctions test_monitor
        echo -e "${CYAN}Tests inclus dans ce fichier:${NC}"
        grep -E "^test_monitor" "$test_file" | head -5 | while read -r line; do
            test_name=$(echo "$line" | sed 's/.*"\([^"]*\)".*/\1/')
            echo "   • $test_name"
        done
        
        echo ""
        echo -e "${CYAN}Code PHP exécutable (copiable dans PsySH):${NC}"
        
        # Extraire le code PHP des nouveaux tests
        grep -A 20 "^test_monitor" "$test_file" | \
        sed -n "/'.*{/,/}.*'/p" | \
        sed "s/^'//g" | \
        sed "s/'.*\\\\$//g" | \
        sed "s/'$//g" | \
        grep -E "^(function|if|return|echo|\$|for|while| |})" | \
        grep -v "^#" | \
        grep -v "^test_monitor" | \
        head -15 | \
        while read -r line; do
            echo "    $line"
        done
    else
        # Ancien format avec monitor direct
        echo -e "${CYAN}Tests inclus dans ce fichier:${NC}"
        # Essayer d'abord le format ">>> Test X:"
        if grep -q ">>> Test \[0-9\]*:" "$test_file"; then
            grep ">>> Test \[0-9\]*:" "$test_file" | head -5 | while read -r line; do
                test_name=$(echo "$line" | sed 's/.*>>> Test \[0-9\]*: //' | sed 's/\"//')
                echo "   • $test_name"
            done
        else
            # Format plus simple ">>> Test avec..."
            grep ">>> Test" "$test_file" | head -5 | while read -r line; do
                test_name=$(echo "$line" | sed 's/.*>>> Test //' | sed 's/\"//' | sed 's/^avec //')
                echo "   • $test_name"
            done
        fi
        
        echo ""
        echo -e "${CYAN}Code PHP exécutable (copiable dans PsySH):${NC}"
        
        # Extraire les commandes monitor des anciens tests - méthode simple par position
        { grep "monitor '" "$test_file" 2>/dev/null || true; grep 'monitor "' "$test_file" 2>/dev/null || true; } | head -4 | while read -r line; do
            # Méthode basique: supprimer les 9 premiers caractères ("monitor '") et le dernier ("'")
            if [[ "$line" == *"monitor '"* ]]; then
                php_code=${line:9}      # Enlever "monitor '"
                php_code=${php_code%\'} # Enlever la quote finale
            else
                php_code=${line:9}      # Enlever 'monitor "'
                php_code=${php_code%\"}  # Enlever la quote finale
            fi
            
            if [[ -n "$php_code" ]]; then
                echo "    $php_code"
                echo ""
            fi
        done
    fi
    
    # Si pas de fonctions test_monitor, chercher les anciennes patterns
    if [ $(grep -E "^test_monitor|^monitor" "$test_file" | wc -l) -eq 0 ]; then
        grep -E "^monitor|^\$" "$test_file" | head -10
    fi
    
    total_lines=$(grep -E "^test_monitor|^monitor|^\$" "$test_file" | wc -l)
    if [ $total_lines -gt 10 ]; then
        echo -e "${CYAN}... (${NC}$total_lines${CYAN} lignes au total)${NC}"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Attendre avant de lancer
    if ! wait_for_action "⏸️  Appuyez sur ENTRÉE pour lancer le test (ou ESC pour passer)..."; then
        echo -e "\n${YELLOW}⏭️  Test passé${NC}"
        if [[ $AUTO_MODE != "1" ]]; then
            sleep 1
        fi
        return
    fi
    
    # Lancer le test
    echo -e "\n${GREEN}🚀 Exécution du test...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Exécuter le test avec les variables d'environnement
    env AUTO_MODE="$AUTO_MODE" SIMPLE_MODE="$SIMPLE_MODE" DEBUG_MODE="$DEBUG_MODE" ./$test_file
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✅ Test terminé!${NC}"
    
    # Attendre avant de continuer
    if ! wait_for_action "⏸️  Appuyez sur ENTRÉE pour continuer (ou ESC pour arrêter)..."; then
        return 1  # Signal to stop
    fi
    return 0
}

# Fonction pour afficher l'aide
DEBUG_MODE=0

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all              Exécuter tous les tests en mode automatique"
    echo "  --simple           Mode simple avec progression minimale"
    echo "  --pause-on-fail    Met en pause automatiquement sur échec (avec --simple)"
    echo "  --debug            Mode debug avec informations détaillées"
    echo "  --help             Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0                           # Mode interactif normal"
    echo "  $0 --all                     # Tous les tests, mode automatique"
    echo "  $0 --simple                  # Tous les tests, affichage minimal"
    echo "  $0 --simple --pause-on-fail  # Affichage minimal avec pause sur échec"
    exit 0
}

# Traiter les paramètres
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            AUTO_MODE=1
            shift
            ;;
        --simple)
            SIMPLE_MODE=1
            AUTO_MODE=1
            EXPLICIT_SIMPLE_MODE=1
            shift
            ;;
        --pause-on-fail)
            PAUSE_ON_FAIL=1
            shift
            ;;
        --debug)
            DEBUG_MODE=1
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            echo "Utilisez --help pour voir les options disponibles"
            exit 1
            ;;
    esac
done

# Variables globales pour le comptage
TOTAL_TESTS_COUNT=0
TOTAL_PASS_SCRIPTS=0
TOTAL_FAIL_SCRIPTS=0
FAILED_SCRIPTS=()
FAILED_DETAILS=()
DEBUG_DETAILS=()

# Fonction pour capturer les détails d'échec
capture_test_details() {
    local test_file=$1
    local temp_output=$2
    
    # Extraire le résumé du test
    local summary=$(grep -E "(🎉.*PASSÉS|❌.*tests échoués)" "$temp_output" | tail -1)
    
    if [[ -z "$summary" ]]; then
        return 1
    fi
    
    # Extraire le nombre de tests
    if echo "$summary" | grep -q "[0-9].*tests.*échoués.*sur.*[0-9]"; then
        local failed_count=$(echo "$summary" | sed -E 's/.*([0-9]+).*tests.*échoués.*sur.*([0-9]+).*/\1/')
        local total_count=$(echo "$summary" | sed -E 's/.*([0-9]+).*tests.*échoués.*sur.*([0-9]+).*/\2/')
        TOTAL_TESTS_COUNT=$((TOTAL_TESTS_COUNT + total_count))
        
        # Extraire les détails des échecs
        local fail_details=$(grep -B 3 -A 3 "❌ FAIL:" "$temp_output" | grep -E "(❌ FAIL:|Résultat attendu:|Résultat obtenu:|Pattern d'erreur)" | head -20)
        FAILED_DETAILS+=("\n${YELLOW}$test_file:${NC}\n$fail_details")
        return 0
    elif echo "$summary" | grep -q "([0-9]*/[0-9]*)"; then
        local total_count=$(echo "$summary" | sed -E 's/.*\(([0-9]+)\/([0-9]+)\).*/\2/')
        TOTAL_TESTS_COUNT=$((TOTAL_TESTS_COUNT + total_count))
        return 0
    fi
    
    return 1
}

# Fonction pour capturer les détails de debug optimisés pour l'IA
capture_debug_details() {
    local test_file=$1
    local temp_output=$2
    local exit_code=$3
    
    # Debug QUE pour les tests qui échouent
    if [[ $DEBUG_MODE == "1" && $exit_code -ne 0 ]]; then
        local debug_info=""
        local file_base=$(basename "$test_file")
        
        debug_info+="\n${CYAN}╭─ FAIL: $file_base ─ Exit: $exit_code${NC}\n"
        
        if [[ -f "$temp_output" ]]; then
            # 1. Extraire les étapes qui échouent avec leur contexte
            local failed_lines=$(grep -n -B1 -A1 "❌" "$temp_output" | head -15)
            if [[ -n "$failed_lines" ]]; then
                debug_info+="${YELLOW}ÉTAPES ÉCHOUÉES:${NC}\n$failed_lines\n\n"
            fi
            
            # 2. Extraire les commandes exécutées avant l'erreur
            local commands=$(grep -E "(echo|phpunit:|\$PSYSH_CMD)" "$temp_output" | tail -3)
            if [[ -n "$commands" ]]; then
                debug_info+="${BLUE}DERNIÈRES COMMANDES:${NC}\n$commands\n\n"
            fi
            
            # 3. Extraire les erreurs spécifiques avec patterns utiles
            local errors=$(grep -E "(RuntimeException|PARSE ERROR|Too many arguments|command not found|Not enough arguments|Undefined)" "$temp_output" | head -3)
            if [[ -n "$errors" ]]; then
                debug_info+="${RED}ERREURS DÉTECTÉES:${NC}\n$errors\n\n"
            fi
            
            # 4. Extraire les valeurs attendues vs obtenues
            local comparisons=$(grep -A1 -B1 -E "(attendu|obtenu|expected|actual)" "$temp_output" | head -6)
            if [[ -n "$comparisons" ]]; then
                debug_info+="${PURPLE}COMPARAISONS:${NC}\n$comparisons\n\n"
            fi
            
            # 5. Contexte des assertions (si c'est un test d'assertion)
            if [[ "$file_base" == *"assert"* ]]; then
                local assertions=$(grep -E "(phpunit:assert|Assertion)" "$temp_output" | tail -2)
                if [[ -n "$assertions" ]]; then
                    debug_info+="${GREEN}ASSERTIONS:${NC}\n$assertions\n\n"
                fi
            fi
        fi
        
        debug_info+="${CYAN}╰────────────────────────────────────────────────${NC}"
        DEBUG_DETAILS+=("$debug_info")
    fi
}


# Exécution en mode simple (seulement si explicitement demandé)
if [[ $SIMPLE_MODE == "1" && $EXPLICIT_SIMPLE_MODE == "1" ]]; then
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}Exécution des tests en mode simple${NC}                        ${CYAN}│${NC}"
    if [[ $PAUSE_ON_FAIL == "1" ]]; then
        echo -e "${CYAN}│${NC} ${PURPLE}Pause automatique sur échec activée${NC}                      ${CYAN}│${NC}"
    fi
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Réinitialiser les compteurs
    TOTAL_TESTS_COUNT=0
    TOTAL_PASS_SCRIPTS=0
    TOTAL_FAIL_SCRIPTS=0
    FAILED_SCRIPTS=()
    FAILED_DETAILS=()
    
    for i in "${!tests[@]}"; do
        # Boucle pour gérer les retry avec --pause-on-fail
        while true; do
            run_test_simple "${tests[$i]}" $((i+1)) ${#tests[@]}
            exit_code=$?
            
            if [[ $exit_code -eq 0 ]]; then
                ((TOTAL_PASS_SCRIPTS++))
                break  # Test réussi, passer au suivant
            elif [[ $exit_code -eq 2 ]]; then
                # Code 2 signifie que l'utilisateur a demandé l'arrêt via ESC
                echo -e "\n${YELLOW}⏹️  Arrêt demandé par l'utilisateur${NC}"
                exit 1
            elif [[ $exit_code -eq 3 ]]; then
                # Code 3 signifie retry demandé
                echo -e "${CYAN}🔄 Relance en cours...${NC}"
                continue  # Relancer le même test
            else
                ((TOTAL_FAIL_SCRIPTS++))
                FAILED_SCRIPTS+=("${tests[$i]}")
                break  # Échec confirmé, passer au suivant
            fi
        done
    done
    
    # Afficher le résumé détaillé
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      RÉSUMÉ GLOBAL                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Scripts de test exécutés:${NC} $((TOTAL_PASS_SCRIPTS + TOTAL_FAIL_SCRIPTS))"
    echo -e "${GREEN}Scripts réussis:${NC} $TOTAL_PASS_SCRIPTS"
    echo -e "${RED}Scripts échoués:${NC} $TOTAL_FAIL_SCRIPTS"
    echo -e "${BLUE}Tests individuels exécutés:${NC} $TOTAL_TESTS_COUNT"
    echo ""
    
    # Si des tests ont échoué, afficher les détails
    if [[ $TOTAL_FAIL_SCRIPTS -gt 0 ]]; then
        echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                    DÉTAILS DES ÉCHECS                        ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
        
        for detail in "${FAILED_DETAILS[@]}"; do
            echo -e "$detail"
            echo ""
        done
        
        echo -e "${RED}❤️ Des tests ont échoué !${NC}"
        
        # Afficher les détails de debug si le mode debug est activé
        if [[ $DEBUG_MODE == "1" && ${#DEBUG_DETAILS[@]} -gt 0 ]]; then
            echo ""
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║${NC}                    ${YELLOW}DÉTAILS DE DEBUG${NC}                        ${CYAN}║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
            
            for detail in "${DEBUG_DETAILS[@]}"; do
                echo -e "$detail"
                echo ""
            done
        fi
        
        exit 1
    else
        echo -e "${GREEN}🎉 Tous les tests sont passés !${NC}"
        
        # En mode debug, afficher un message de confirmation mais pas les détails si tout va bien
        if [[ $DEBUG_MODE == "1" ]]; then
            echo -e "${CYAN}[DEBUG]${NC} Mode debug activé - aucun détail à afficher (tous les tests ont réussi)"
        fi
        
        exit 0
    fi
fi

# Exécution en mode --all (ancien comportement)
if [[ $AUTO_MODE == "1" ]]; then
    echo -e "\n${YELLOW}🔄 Mode automatique activé - Exécution de tous les tests...${NC}"
    
    # Réinitialiser les compteurs
    TOTAL_TESTS_COUNT=0
    TOTAL_PASS_SCRIPTS=0
    TOTAL_FAIL_SCRIPTS=0
    FAILED_SCRIPTS=()
    FAILED_DETAILS=()
    DEBUG_DETAILS=()
    
    for i in "${!tests[@]}"; do
        # Utiliser run_test_simple pour --pause-on-fail même en mode --all
        if [[ $PAUSE_ON_FAIL == "1" ]]; then
            # Boucle pour gérer les retry avec --pause-on-fail
            while true; do
                run_test_simple "${tests[$i]}" $((i+1)) ${#tests[@]}
                exit_code=$?
                
                if [[ $exit_code -eq 0 ]]; then
                    ((TOTAL_PASS_SCRIPTS++))
                    break  # Test réussi, passer au suivant
                elif [[ $exit_code -eq 2 ]]; then
                    # Code 2 signifie que l'utilisateur a demandé l'arrêt via ESC
                    echo -e "\n${YELLOW}⏹️  Arrêt demandé par l'utilisateur${NC}"
                    exit 1
                elif [[ $exit_code -eq 3 ]]; then
                    # Code 3 signifie retry demandé
                    echo -e "${CYAN}🔄 Relance en cours...${NC}"
                    continue  # Relancer le même test
                else
                    ((TOTAL_FAIL_SCRIPTS++))
                    FAILED_SCRIPTS+=("${tests[$i]}")
                    break  # Échec confirmé, passer au suivant
                fi
            done
        elif [[ $EXPLICIT_SIMPLE_MODE == "1" ]]; then
            run_test_simple "${tests[$i]}" $((i+1)) ${#tests[@]}
            exit_code=$?
            
            if [[ $exit_code -eq 0 ]]; then
                ((TOTAL_PASS_SCRIPTS++))
            elif [[ $exit_code -eq 2 ]]; then
                # Code 2 signifie que l'utilisateur a demandé l'arrêt via ESC
                echo -e "\n${YELLOW}⏹️  Arrêt demandé par l'utilisateur${NC}"
                exit 1
            else
                ((TOTAL_FAIL_SCRIPTS++))
                FAILED_SCRIPTS+=("${tests[$i]}")
            fi
        else
            # Mode --all classique avec interface complète
            temp_output=$(mktemp)
            
            # Capturer la sortie du test
            { run_test "${tests[$i]}" $((i+1)) ${#tests[@]}; } > "$temp_output" 2>&1
            exit_code=$?
            
            # Afficher la sortie
            cat "$temp_output"
            
            # Capturer les détails
            capture_test_details "${tests[$i]}" "$temp_output"
            capture_debug_details "${tests[$i]}" "$temp_output" $exit_code
            
            if [[ $exit_code -eq 0 ]]; then
                ((TOTAL_PASS_SCRIPTS++))
            else
                ((TOTAL_FAIL_SCRIPTS++))
                FAILED_SCRIPTS+=("${tests[$i]}")
                
                if [[ $exit_code -eq 1 ]]; then
                    # Arrêt demandé par l'utilisateur
                    echo -e "\n${YELLOW}⏹️  Arrêt demandé par l'utilisateur${NC}"
                    rm -f "$temp_output"
                    break
                fi
            fi
            
            rm -f "$temp_output"
        fi
    done
    
    # Afficher le résumé détaillé
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      RÉSUMÉ GLOBAL                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Scripts de test exécutés:${NC} $((TOTAL_PASS_SCRIPTS + TOTAL_FAIL_SCRIPTS))"
    echo -e "${GREEN}Scripts réussis:${NC} $TOTAL_PASS_SCRIPTS"
    echo -e "${RED}Scripts échoués:${NC} $TOTAL_FAIL_SCRIPTS"
    echo -e "${BLUE}Tests individuels exécutés:${NC} $TOTAL_TESTS_COUNT"
    echo ""
    
    # Si des tests ont échoué, afficher les détails
    if [[ $TOTAL_FAIL_SCRIPTS -gt 0 ]]; then
        echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                    DÉTAILS DES ÉCHECS                        ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
        
        for detail in "${FAILED_DETAILS[@]}"; do
            echo -e "$detail"
            echo ""
        done
        
        echo -e "${RED}❌ Des tests ont échoué !${NC}"
        exit 1
    else
        echo -e "${GREEN}🎉 Tous les tests sont passés !${NC}"
        exit 0
    fi
fi

# Menu principal
while true; do
    clear
    echo "=================================================="
    echo "     SUITE DE TESTS - COMMANDE MONITOR PSYSH     "
    echo "=================================================="
    echo ""
    echo "Choisissez une option:"
    echo ""
    echo "1) Exécuter tous les tests"
    echo "2) Choisir un test spécifique"
    echo "3) Tests basiques (01-05)"
    echo "4) Tests temps réel et debug (06-10)"
    echo "5) Tests services Symfony (11-15)"
    echo "6) Tests avancés PHP (16-20)"
    echo "7) 🔍 Tests de régression (bugs corrigés)"
    echo "0) Quitter"
    echo ""
    read -p "Votre choix: " choice

    case $choice in
        1)
            echo -e "\n${YELLOW}🔄 Exécution de tous les tests...${NC}"
            sleep 1
            for i in "${!tests[@]}"; do
                if ! run_test "${tests[$i]}" $((i+1)) ${#tests[@]}; then
                    echo -e "\n${YELLOW}⏹️  Arrêt demandé par l'utilisateur${NC}"
                    sleep 2
                    break
                fi
            done
            ;;
        2)
            clear
            echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║${NC}              ${YELLOW}LISTE DES TESTS DISPONIBLES${NC}              ${CYAN}║${NC}"
            echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            for i in "${!tests[@]}"; do
                printf "${GREEN}%2d)${NC} ${BLUE}%s${NC}\n" $((i+1)) "${tests[$i]}"
            done
            echo ""
            echo -e "${PURPLE}0) Retour au menu principal${NC}"
            echo ""
            read -p "Numéro du test: " test_num
            
            if [[ $test_num == "0" ]]; then
                continue
            elif [[ $test_num -ge 1 && $test_num -le ${#tests[@]} ]]; then
                run_test "${tests[$((test_num-1))]}" $test_num ${#tests[@]}
            else
                echo -e "${RED}Numéro invalide${NC}"
                sleep 2
            fi
            ;;
        3)
            echo -e "\n${YELLOW}📝 Exécution des tests basiques...${NC}"
            sleep 1
            for i in {0..4}; do
                if ! run_test "${tests[$i]}" $((i+1)) ${#tests[@]}; then
                    break
                fi
            done
            ;;
        4)
            echo -e "\n${YELLOW}⏱️  Exécution des tests temps réel...${NC}"
            sleep 1
            for i in {5..9}; do
                if ! run_test "${tests[$i]}" $((i+1)) ${#tests[@]}; then
                    break
                fi
            done
            ;;
        5)
            echo -e "\n${YELLOW}🔧 Exécution des tests Symfony...${NC}"
            sleep 1
            for i in {10..14}; do
                if ! run_test "${tests[$i]}" $((i+1)) ${#tests[@]}; then
                    break
                fi
            done
            ;;
        6)
            echo -e "\n${YELLOW}🚀 Exécution des tests avancés...${NC}"
            sleep 1
            for i in {15..19}; do
                if ! run_test "${tests[$i]}" $((i+1)) ${#tests[@]}; then
                    break
                fi
            done
            ;;
        7)
            echo -e "\n${YELLOW}🔍 Exécution des tests de régression...${NC}"
            echo -e "${CYAN}Vérification que les bugs corrigés ne reviennent pas${NC}"
            sleep 1
            # Exécuter les 3 derniers tests (tests de régression)
            for i in {20..22}; do
                if ! run_test "${tests[$i]}" $((i+1)) ${#tests[@]}; then
                    break
                fi
            done
            ;;
        0|q|Q)
            echo -e "\n${GREEN}👋 Au revoir!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Option invalide${NC}"
            sleep 2
            ;;
    esac
done
