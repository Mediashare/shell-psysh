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

# Fonction pour générer une stack trace shell en analysant l'exécution
generate_shell_stack_trace() {
    local temp_output=$1
    local main_test_file=$2
    
    echo -e "   ${PURPLE}📂 Fichiers impliqués dans l'exécution:${NC}"
    
    # 1. Fichier de test principal
    echo -e "   ${CYAN}├─ ${main_test_file}${NC} (Point d'entrée)"
    
    # 2. Chercher les sources/includes dans les logs
    local sourced_files=$(grep -E "(source|\.|Loading|Sourcing)" "$temp_output" | grep -E "\.sh|\.bash" | head -5)
    if [[ -n "$sourced_files" ]]; then
        echo "$sourced_files" | while IFS= read -r line; do
            local file_path=$(echo "$line" | sed -E 's/.*([a-zA-Z0-9_\/\.-]*\.sh).*/\1/')
            if [[ -n "$file_path" && "$file_path" != "$line" ]]; then
                echo -e "   ${CYAN}├─ $file_path${NC} (Sourcé/Inclus)"
            fi
        done
    fi
    
    # 3. Analyser la structure des fichiers shell réellement utilisés
    echo -e "\n   ${PURPLE}🔍 Analyse des fichiers shell détectés:${NC}"
    
    # Analyser le fichier de test principal
    if [[ -f "$main_test_file" ]]; then
        analyze_shell_file "$main_test_file" "$temp_output"
    fi
    
    # Analyser les fichiers lib/ si détectés
    local lib_files=$(find "$(dirname "$main_test_file")/../../lib" -name "*.sh" 2>/dev/null | head -3)
    if [[ -n "$lib_files" ]]; then
        echo "$lib_files" | while IFS= read -r lib_file; do
            if [[ -f "$lib_file" ]]; then
                analyze_shell_file "$lib_file" "$temp_output"
            fi
        done
    fi
    
    # 4. Chercher des traces spécifiques dans les logs debug
    echo -e "\n   ${PURPLE}🎯 Trace d'exécution basée sur les logs:${NC}"
    local debug_traces=$(grep -n -E "(\[DEBUG\]|Etape [0-9]+|test_execute|monitor|phpunit:assert)" "$temp_output" | head -10)
    if [[ -n "$debug_traces" ]]; then
        echo "$debug_traces" | while IFS= read -r trace_line; do
            local line_num=$(echo "$trace_line" | cut -d: -f1)
            local content=$(echo "$trace_line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
            echo -e "   ${YELLOW}   Line $line_num: ${NC}$content"
        done
    fi
}

# Fonction pour analyser un fichier shell spécifique
analyze_shell_file() {
    local file_path=$1
    local temp_output=$2
    local file_name=$(basename "$file_path")
    
    echo -e "   ${BLUE}📄 $file_name${NC}"
    
    # Chercher les fonctions définies dans ce fichier
    if [[ -f "$file_path" ]]; then
        local functions=$(grep -n "^[a-zA-Z_][a-zA-Z0-9_]*()" "$file_path" | head -5)
        if [[ -n "$functions" ]]; then
            echo "$functions" | while IFS= read -r func_line; do
                local line_num=$(echo "$func_line" | cut -d: -f1)
                local func_name=$(echo "$func_line" | cut -d: -f2 | sed 's/()[[:space:]]*{.*//' | sed 's/^[[:space:]]*//')
                
                # Vérifier si cette fonction apparaît dans les logs
                if grep -q "$func_name" "$temp_output" 2>/dev/null; then
                    echo -e "   ${GREEN}   ✓ $func_name() [ligne $line_num] - UTILISÉE${NC}"
                else
                    echo -e "   ${CYAN}   - $func_name() [ligne $line_num]${NC}"
                fi
            done
        fi
        
        # Chercher les appels source/include
        local includes=$(grep -n "^[[:space:]]*source\|^[[:space:]]*\." "$file_path" | head -3)
        if [[ -n "$includes" ]]; then
            echo -e "   ${CYAN}   📥 Inclusions détectées:${NC}"
            echo "$includes" | while IFS= read -r inc_line; do
                local line_num=$(echo "$inc_line" | cut -d: -f1)
                local inc_file=$(echo "$inc_line" | cut -d: -f2- | sed 's/.*["\047]\([^"\047]*\)["\047].*/\1/' | sed 's/.*[[:space:]]\([^[:space:]]*\)$/\1/')
                echo -e "   ${CYAN}     → ligne $line_num: $inc_file${NC}"
            done
        fi
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
    ./$test_file > "$temp_output" 2>&1
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
        [[ "$total_steps" =~ ^[0-9]+$ ]] || total_steps=0
        [[ "$passed_steps" =~ ^[0-9]+$ ]] || passed_steps=0
        [[ "$failed_steps" =~ ^[0-9]+$ ]] || failed_steps=0
        
        # Update to reflect accurate step stats
        step_stats=" (${passed_steps}/${failed_steps}/${total_steps} étapes)"
        # Fix exit status determination if there are failed steps
        if [[ $failed_steps -gt 0 ]]; then
            exit_code=1
        fi
    fi
    
    # Mode debug: afficher les détails complets du test
    if [[ $DEBUG_MODE == "1" && $exit_code -ne 0 ]]; then
        echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}                           ${YELLOW}MODE DEBUG ACTIVÉ${NC}                               ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} Fichier: ${GREEN}$test_file${NC} (Exit: ${RED}$exit_code${NC})                        ${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
        
        if [[ -f "$temp_output" ]]; then
            # Extraire les étapes qui ont échoué avec leur contexte complet
            echo -e "\n${RED}📋 ÉTAPES EN ÉCHEC:${NC}"
            grep -B2 -A10 "❌ FAIL:" "$temp_output" | while IFS= read -r line; do
                if [[ "$line" =~ ^❌\ FAIL: ]]; then
                    echo -e "   ${RED}● ${line#❌ FAIL: }${NC}"
                elif [[ "$line" =~ ^\>\>\>\ Étape ]]; then
                    echo -e "   ${BLUE}📌 ${line}${NC}"
                elif [[ "$line" =~ ^Code\ monitor: ]]; then
                    echo -e "   ${CYAN}📝 INPUT:${NC} ${line#Code monitor: }"
                elif [[ "$line" =~ ^Sortie\ du\ test: ]]; then
                    echo -e "   ${GREEN}📤 OUTPUT:${NC} ${line#Sortie du test: }"
                elif [[ "$line" =~ ^Résultat\ attendu: ]]; then
                    echo -e "   ${YELLOW}🎯 EXPECTED:${NC} ${line#Résultat attendu: }"
                elif [[ "$line" =~ ^Résultat\ obtenu: ]]; then
                    echo -e "   ${RED}❌ ACTUAL:${NC} ${line#Résultat obtenu: }"
                elif [[ "$line" =~ ^Pattern\ d.erreur: ]]; then
                    echo -e "   ${PURPLE}🔍 ERROR PATTERN:${NC} ${line#Pattern d\'erreur: }"
                fi
            done
            
            echo ""
            echo -e "${BLUE}🔧 COMMANDES EXÉCUTÉES:${NC}"
            grep -E "(\$PSYSH_CMD|echo \"Étape|phpunit:)" "$temp_output" | tail -5 | while IFS= read -r line; do
                if [[ "$line" =~ ^echo\ \"Étape ]]; then
                    echo -e "   ${CYAN}🏷️  ${line}${NC}"
                else
                    echo -e "   ${BLUE}⚡ ${line}${NC}"
                fi
            done
            
            # Afficher les erreurs système ou PHP si présentes avec leur contexte
            echo ""
            echo -e "${RED}🚨 ERREURS DÉTECTÉES lors de l'exécution de ${YELLOW}$(basename "$test_file")${RED}:${NC}"
            
            # Générer une stack trace shell si possible
            echo -e "\n${BLUE}🔍 STACK TRACE - Chemin d'exécution:${NC}"
            generate_shell_stack_trace "$temp_output" "$test_file"
            local has_errors=false
            local error_num=1
            while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    # Extraire le numéro de ligne et le contenu de l'erreur
                    local output_line_num=$(echo "$line" | cut -d: -f1)
                    local error_content=$(echo "$line" | cut -d: -f2-)
                    
                    # Déterminer le type d'erreur
                    local error_type="SHELL"
                    local error_source="Script shell"
                    if [[ "$error_content" =~ (syntax\ error|Parse\ error|Fatal\ error|Call\ to\ undefined) ]]; then
                        error_type="PHP"
                        error_source="Code PHP exécuté"
                    fi
                    
                    echo -e "   ${RED}💥 [#$error_num] ${error_source} (ligne de sortie $output_line_num):${NC}"
                    echo -e "   ${RED}   ${error_content}${NC}"
                    
                    # Chercher la commande qui a causé cette erreur
                    local safe_pattern=$(echo "$error_content" | sed 's/.*RuntimeException/RuntimeException/' | sed 's/\[/\\[/g' | sed 's/\]/\\]/g' | sed 's/"/\\"/g')
                    
                    # Afficher le contexte autour de l'erreur dans la sortie
                    local start_line=$((output_line_num - 3))
                    local end_line=$((output_line_num + 3))
                    if [[ $start_line -lt 1 ]]; then start_line=1; fi
                    
                    local error_context=$(sed -n "${start_line},${end_line}p" "$temp_output" 2>/dev/null | nl -v$start_line -w3 -s': ')
                    if [[ -n "$error_context" ]]; then
                        echo -e "   ${CYAN}🔍 Contexte de sortie (lignes $start_line-$end_line):${NC}"
                        echo "$error_context" | while IFS= read -r context_line; do
                            if echo "$context_line" | grep -q "$output_line_num:"; then
                                echo -e "      ${RED}→ $context_line${NC}"  # Ligne d'erreur en rouge
                            else
                                echo -e "      $context_line"
                            fi
                        done
                    fi
                    
                    # Chercher et afficher la commande PHP qui a causé l'erreur
                    if [[ "$error_type" == "PHP" ]]; then
                        # Rechercher la dernière commande monitor ou phpunit avant l'erreur
                        local php_command=$(sed -n "1,${output_line_num}p" "$temp_output" | grep -E "(monitor|phpunit:assert)" | tail -1)
                        if [[ -n "$php_command" ]]; then
                            # Extraire juste le code PHP
                            local clean_php=$(echo "$php_command" | sed -E 's/.*(monitor|phpunit:assert)[[:space:]]*[\"'\'']([^\"'\'']*)[\"\''].*/\2/' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                            if [[ -n "$clean_php" && "$clean_php" != "$php_command" ]]; then
                                echo -e "   ${YELLOW}📝 Code PHP qui a échoué: ${NC}${CYAN}$clean_php${NC}"
                            fi
                        fi
                        
                        # Chercher l'étape de test correspondante
                        local test_step=$(sed -n "1,${output_line_num}p" "$temp_output" | grep -E ">>> Étape [0-9]+:" | tail -1)
                        if [[ -n "$test_step" ]]; then
                            echo -e "   ${BLUE}📋 $test_step${NC}"
                        fi
                    else
                        # Pour les erreurs shell, chercher la commande associée
                        local associated_command=$(grep -B 3 -A 1 -F "$safe_pattern" "$temp_output" 2>/dev/null | grep -E "(\\[DEBUG\\] Command:|Command:|monitor|phpunit:)" | head -1 | sed 's/.*Command: //' | sed 's/\\[DEBUG\\] Etape [0-9]\\* - //' || echo "")
                        if [[ -n "$associated_command" ]]; then
                            echo -e "   ${YELLOW}📝 Commande associée: ${associated_command}${NC}"
                        fi
                    fi
                    
                    echo ""  # Ligne vide entre les erreurs
                    has_errors=true
                    ((error_num++))
                fi
            done < <(grep -n -E "(RuntimeException|PARSE ERROR|Fatal error|Warning:|Notice:|Error:|command not found|No such file)" "$temp_output" | head -3)
            
            if [[ "$has_errors" == "false" ]]; then
                echo -e "   ${GREEN}✓ Aucune erreur système détectée${NC}"
            fi
            
            # Afficher un résumé des comparaisons d'assertions
            echo ""
            echo -e "${PURPLE}🧪 RÉSUMÉ DES ASSERTIONS:${NC}"
            local test_count=$(grep -c ">>> Étape\|>>> Test" "$temp_output" 2>/dev/null || echo "0")
            local fail_count=$(grep -c "❌ FAIL:" "$temp_output" 2>/dev/null || echo "0")
            local pass_count=$(grep -c "✅ PASS:" "$temp_output" 2>/dev/null || echo "0")
            local warning_count=$(grep -c "⚠️" "$temp_output" 2>/dev/null || echo "0")
            
            # Remove any potential newlines from the variables
            test_count=${test_count//[[:space:]]/}
            fail_count=${fail_count//[[:space:]]/}
            pass_count=${pass_count//[[:space:]]/}
            warning_count=${warning_count//[[:space:]]/}
            
            # Ensure we have valid numeric values (default to 0 if empty or invalid)
            [[ "$test_count" =~ ^[0-9]+$ ]] || test_count=0
            [[ "$fail_count" =~ ^[0-9]+$ ]] || fail_count=0
            [[ "$pass_count" =~ ^[0-9]+$ ]] || pass_count=0
            [[ "$warning_count" =~ ^[0-9]+$ ]] || warning_count=0
            echo -e "   ${CYAN}📊 Total étapes: ${test_count} | ✅ Réussies: ${pass_count} | ❌ Échouées: ${fail_count}${NC}"
            
            if [[ $warning_count -gt 0 ]]; then
                echo -e "   ${YELLOW}⚠️  Avertissements détectés: ${warning_count}${NC}"
            fi
            
            # Alerte de cohérence dans le debug
            if [[ $exit_code -eq 0 && $fail_count -gt 0 ]]; then
                echo -e "   ${RED}🚨 INCOHÉRENCE: Test marqué SUCCESS mais contient des échecs!${NC}"
            elif [[ $exit_code -ne 0 && $pass_count -gt 0 && $fail_count -eq 0 ]]; then
                echo -e "   ${YELLOW}🤔 SUSPECT: Test marqué FAIL mais toutes les étapes ont réussi${NC}"
            fi
            
            # Si c'est un test PHPUnit, afficher les infos spécifiques
            if [[ "$test_file" == *"phpunit"* ]]; then
                echo ""
                echo -e "${GREEN}🧪 CONTEXTE PHPUNIT:${NC}"
                grep -E "(phpunit:|Generating|Creating|File created)" "$temp_output" | tail -3 | while IFS= read -r line; do
                    echo -e "   ${GREEN}📝 ${line}${NC}"
                done
            fi
        fi
        
        echo -e "\n${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
    
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
                    # Mode debug: affichage structuré et détaillé
                    echo -e "${CYAN}🔍 ANALYSE DÉTAILLÉE DE L'ÉCHEC:${NC}"
                    echo ""
                    
                    # 1. Étapes en échec avec contexte complet
                    echo -e "${YELLOW}📋 ÉTAPES QUI ONT ÉCHOUÉ:${NC}"
                    grep -B3 -A8 "❌ FAIL:" "$temp_output" | head -30 | while IFS= read -r line; do
                        if [[ "$line" =~ ^❌\ FAIL: ]]; then
                            echo -e "   ${RED}🚫 ${line#❌ FAIL: }${NC}"
                        elif [[ "$line" =~ ^\>\>\>\ (Test|Étape) ]]; then
                            echo -e "   ${BLUE}📍 ${line}${NC}"
                        elif [[ "$line" =~ ^Code\ monitor: ]]; then
                            echo -e "   ${CYAN}📥 INPUT: ${line#Code monitor: }${NC}"
                        elif [[ "$line" =~ ^Sortie\ du\ test: ]]; then
                            echo -e "   ${GREEN}📤 OUTPUT: ${line#Sortie du test: }${NC}"
                        elif [[ "$line" =~ ^Résultat\ attendu: ]]; then
                            echo -e "   ${YELLOW}🎯 EXPECTED: ${line#Résultat attendu: }${NC}"
                        elif [[ "$line" =~ ^Résultat\ obtenu: ]]; then
                            echo -e "   ${RED}❌ ACTUAL: ${line#Résultat obtenu: }${NC}"
                        elif [[ "$line" =~ ^Pattern ]]; then
                            echo -e "   ${PURPLE}🔍 ${line}${NC}"
                        elif [[ "$line" =~ ^-- ]]; then
                            echo "   ────────────────────────────────────────"
                        fi
                    done
                    
                    echo ""
                    echo -e "${BLUE}⚡ DERNIÈRES COMMANDES:${NC}"
                    
                    # Capturer les commandes avec leurs outputs et étapes
                    local cmd_output_temp=$(mktemp)
                    grep -E "(\[DEBUG\] Etape|\[DEBUG\] Command:|\[DEBUG\] Output:|>>> Étape)" "$temp_output" | tail -15 > "$cmd_output_temp"
                    
                    # Afficher les commandes avec leurs outputs de façon structurée
                    local current_step=""
                    while IFS= read -r line; do
                        if echo "$line" | grep -q "\[DEBUG\] Etape [0-9]"; then
                            current_step=$(echo "$line" | sed -E 's/.*\[DEBUG\] Etape ([0-9]+).*/\1/')
                            echo -e "   ${PURPLE}📋 Etape $current_step: ${line##*\ -\ }${NC}"
                        elif echo "$line" | grep -q "\[DEBUG\] Command:"; then
                            command_text=$(echo "$line" | sed 's/.*\[DEBUG\] Command: //')
                            echo -e "   ${CYAN}   ⚡ Commande: ${command_text}${NC}"
                        elif echo "$line" | grep -q "\[DEBUG\] Output:"; then
                            output_text=$(echo "$line" | sed 's/.*\[DEBUG\] Output: //')
                            echo -e "   ${GREEN}   📤 Sortie: ${output_text}${NC}"
                        elif [[ "$line" =~ ^\>\>\>\ Étape\ ([0-9]+): ]]; then
                            echo -e "   ${BLUE}📍 ${line}${NC}"
                        fi
                    done < "$cmd_output_temp"
                    
                    # Fallback si pas de lignes DEBUG trouvées
                    if [[ ! -s "$cmd_output_temp" ]]; then
                        echo -e "   ${YELLOW}⚠️  Pas de logs DEBUG disponibles${NC}"
                        grep -E "(\$PSYSH_CMD|echo \"Étape|phpunit:|monitor)" "$temp_output" | tail -4 | while IFS= read -r line; do
                            echo -e "   ${CYAN}🔧 ${line}${NC}"
                        done
                    fi
                    
                    rm -f "$cmd_output_temp"
                    
                    echo ""
                    echo -e "${RED}🚨 ERREURS SYSTÈME dans ${YELLOW}$(basename "$test_file")${RED}:${NC}"
                    local system_errors=$(grep -n -E "(RuntimeException|PARSE ERROR|Fatal error|Warning:|command not found|No such file)" "$temp_output" | head -5)
                    if [[ -n "$system_errors" ]]; then
                        echo "$system_errors" | while IFS= read -r line; do
                            if echo "$line" | grep -q "^[[:space:]]*[0-9]"; then
                                local line_num=$(echo "$line" | cut -d: -f1)
                                local error_content=$(echo "$line" | cut -d: -f2-)
                                
                                echo -e "   ${RED}💥 [Ligne $line_num] ${error_content}${NC}"
                                
                                # Chercher la commande qui a causé cette erreur (safer approach)
                                local safe_error_content=$(echo "$error_content" | sed 's/\[/\\[/g' | sed 's/\]/\\]/g' | sed 's/"/\\"/g')
                                
                                # Afficher les lignes avant et après pour plus de contexte
                                local start_line=$((line_num - 2))
                                local end_line=$((line_num + 2))
                                if [[ $start_line -lt 1 ]]; then start_line=1; fi
                                
                                local context=$(sed -n "${start_line},${end_line}p" "$temp_output" 2>/dev/null | nl -v$start_line -w3 -s': ')
                                if [[ -n "$context" ]]; then
                                    echo -e "   ${CYAN}🔍 Contexte (lignes $start_line-$end_line):${NC}"
                                    echo "$context" | while IFS= read -r context_line; do
                                        if echo "$context_line" | grep -q "$line_num:"; then
                                            echo -e "      ${RED}→ $context_line${NC}"  # Ligne d'erreur en rouge
                                        else
                                            echo -e "      $context_line"
                                        fi
                                    done
                                fi
                                
                                local associated_command=$(grep -B 2 -A 2 -F "$safe_error_content" "$temp_output" 2>/dev/null | grep -E "(\\[DEBUG\\] Command:|Command:|monitor|phpunit:)" | head -1 | sed 's/.*Command: //' | sed 's/\\[DEBUG\\] Etape [0-9]\\* - //' || echo "")
                                
                                if [[ -n "$associated_command" ]]; then
                                    echo -e "   ${YELLOW}   📝 Input: ${associated_command}${NC}"
                                fi
                                
                                echo ""  # Ligne vide entre les erreurs
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
    env AUTO_MODE="$AUTO_MODE" SIMPLE_MODE="$SIMPLE_MODE" ./$test_file
    
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
