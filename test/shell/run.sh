#!/bin/bash

# Script pour exécuter les tests PsySH Enhanced
# Supporte plusieurs types de commandes et modes d'exécution

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Obtenir le répertoire du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
        local total_steps=$(grep -c ">>> Étape\|>>> Test" "$temp_output" 2>/dev/null || echo "0")
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
        
        if [[ $total_steps -gt 0 ]]; then
            step_stats=" (${passed_steps}/${total_steps} étapes)"
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
            
            # Afficher les erreurs système ou PHP si présentes
            echo ""
            echo -e "${RED}🚨 ERREURS DÉTECTÉES:${NC}"
            local has_errors=false
            while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    echo -e "   ${RED}💥 ${line}${NC}"
                    has_errors=true
                fi
            done < <(grep -E "(RuntimeException|PARSE ERROR|Fatal error|Warning:|Notice:|Error:|command not found|No such file)" "$temp_output" | head -3)
            
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
            local total_steps=$(grep -c ">>> Étape\|>>> Test" "$temp_output" 2>/dev/null || echo "0")
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
                    grep -E "(\$PSYSH_CMD|echo \"Étape|phpunit:)" "$temp_output" | tail -4 | while IFS= read -r line; do
                        echo -e "   ${CYAN}🔧 ${line}${NC}"
                    done
                    
                    echo ""
                    echo -e "${RED}🚨 ERREURS SYSTÈME:${NC}"
                    local system_errors=$(grep -E "(RuntimeException|PARSE ERROR|Fatal error|Warning:|command not found|No such file)" "$temp_output" | head -2)
                    if [[ -n "$system_errors" ]]; then
                        echo "$system_errors" | while IFS= read -r line; do
                            echo -e "   ${RED}💥 ${line}${NC}"
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
        if [[ $AUTO_MODE != "1" ]]; then
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
        if grep -q ">>> Test [0-9]*:" "$test_file"; then
            grep ">>> Test [0-9]*:" "$test_file" | head -5 | while read -r line; do
                test_name=$(echo "$line" | sed 's/.*>>> Test [0-9]*: //' | sed 's/\"//')
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
    if [[ "$summary" =~ ([0-9]+).*tests.*échoués.*sur.*([0-9]+) ]]; then
        local failed_count=${BASH_REMATCH[1]}
        local total_count=${BASH_REMATCH[2]}
        TOTAL_TESTS_COUNT=$((TOTAL_TESTS_COUNT + total_count))
        
        # Extraire les détails des échecs
        local fail_details=$(grep -B 3 -A 3 "❌ FAIL:" "$temp_output" | grep -E "(❌ FAIL:|Résultat attendu:|Résultat obtenu:|Pattern d'erreur)" | head -20)
        FAILED_DETAILS+=("\n${YELLOW}$test_file:${NC}\n$fail_details")
        return 0
    elif [[ "$summary" =~ \(([0-9]+)/([0-9]+)\) ]]; then
        local total_count=${BASH_REMATCH[2]}
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
