#!/bin/bash

# Utilitaires d'affichage pour les tests
# Contient des fonctions pour l'affichage des messages en couleur et des icônes

# Déterminer le chemin vers config.sh
DISPLAY_UTILS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DISPLAY_UTILS_DIR/../config.sh"

# =================== FONCTIONS D'AFFICHAGE DE BASE ===================

print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

print_success() {
    print_colored "$COLOR_SUCCESS" "${ICON_SUCCESS} $1"
}

print_error() {
    print_colored "$COLOR_ERROR" "${ICON_ERROR} $1"
}

print_warning() {
    print_colored "$COLOR_WARNING" "${ICON_WARNING} $1"
}

print_info() {
    print_colored "$COLOR_INFO" "${ICON_INFO} $1"
}

print_debug() {
    if [[ "$DEBUG_MODE" == "1" ]]; then
        print_colored "$COLOR_DEBUG" "${ICON_DEBUG} $1"
    fi
}

print_header() {
    print_colored "$COLOR_HEADER" "${BOLD}$1${NC}"
}

# =================== FONCTIONS D'AFFICHAGE AVANCÉES ===================

# Affichage d'un titre de test avec bordure
show_test_header() {
    local test_file="$1"
    local test_num="$2"
    local total="$3"
    
    if [[ "$QUIET_MODE" != "1" ]]; then
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}${ICON_TEST} TEST ${test_num}/${total}${NC} : ${GREEN}$test_file${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi
}

# Affichage de résumé avec bordure
show_summary_header() {
    local title="$1"
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                      ${BOLD}${title}${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Affichage d'une section dans un test
show_test_section() {
    local section_title="$1"
    echo -e "${BLUE}${ICON_FILE} $section_title:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Affichage d'une ligne de séparation
show_separator() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Affichage du progrès d'un test (mode simple)
show_test_progress() {
    local test_file="$1"
    local test_num="$2"
    local total="$3"
    local status="$4"  # "running", "success", "failure"
    
    case "$status" in
        "running")
            echo -ne "${BLUE}Test $test_num/$total${NC}: ${test_file} ... "
            ;;
        "success")
            echo -e "${COLOR_SUCCESS}${ICON_SUCCESS} SUCCESS${NC}"
            ;;
        "failure")
            echo -e "${COLOR_ERROR}${ICON_ERROR} FAIL${NC}"
            ;;
    esac
}

# =================== FONCTIONS DE DEBUG ===================

# Affichage d'informations de debug avec structure
show_debug_info() {
    local title="$1"
    local content="$2"
    
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}                           ${YELLOW}$title${NC}                               ${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo "$content"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
}

# Affichage d'une étape de debug
show_debug_step() {
    local step_name="$1"
    local details="$2"
    
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo -e "${COLOR_DEBUG}${ICON_DEBUG} DEBUG STEP: $step_name${NC}"
        if [[ -n "$details" ]]; then
            echo "$details" | sed 's/^/   │ /'
        fi
        echo ""
    fi
}

# =================== FONCTIONS DE FORMATAGE ===================

# Formater une liste à puces
format_bullet_list() {
    while IFS= read -r line; do
        echo -e "   ${BLUE}•${NC} $line"
    done
}

# Formater du code avec indentation
format_code_block() {
    local code="$1"
    echo "$code" | while IFS= read -r line; do
        echo -e "    ${CYAN}$line${NC}"
    done
}

# Formater des statistiques
format_stats() {
    local label="$1"
    local value="$2"
    local color="${3:-$COLOR_INFO}"
    
    printf "${color}%-20s${NC}: %s\n" "$label" "$value"
}

# =================== FONCTIONS D'ATTENTE ===================

# Attendre une action utilisateur avec message personnalisé
wait_for_user_action() {
    local message="$1"
    local show_options="${2:-true}"
    
    echo ""
    # --pause-on-fail override AUTO_MODE pour les pauses
    if [[ "$AUTO_MODE" == "1" && "$PAUSE_ON_FAIL" != "1" ]]; then
        print_colored "$PURPLE" "$message (AUTO MODE: continuing automatically)"
        sleep 1
        return 0
    fi
    
    if [[ "$show_options" == "true" ]]; then
        print_colored "$PURPLE" "$message"
        echo -e "${COLOR_INFO}  [ENTRÉE]${NC} Continuer  ${COLOR_WARNING}[ESC]${NC} Arrêter"
    else
        print_colored "$PURPLE" "$message"
    fi
    
    read -s -n 1 key
    if [[ $key == $'\e' ]]; then
        return 1  # Escape pressed
    fi
    return 0  # Enter or other key pressed
}

# =================== FONCTIONS D'INTERFACE ===================

# Afficher un menu simple
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo -e "${COLOR_HEADER}${BOLD}$title${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
        echo -e "${COLOR_INFO}$(($i + 1)))${NC} ${options[$i]}"
    done
    echo ""
}

# Afficher l'aide pour les options
show_options_help() {
    cat << EOF
${COLOR_HEADER}${BOLD}Options disponibles:${NC}

${COLOR_INFO}  --all${NC}              Exécuter tous les tests en mode automatique
${COLOR_INFO}  --simple${NC}           Mode simple avec progression minimale
${COLOR_INFO}  --pause-on-fail${NC}    Met en pause automatiquement sur échec
${COLOR_INFO}  --debug${NC}            Mode debug avec informations détaillées
${COLOR_INFO}  --quiet${NC}            Mode silencieux (minimum d'affichage)
${COLOR_INFO}  --dry-run${NC}          Simulation sans exécution réelle
${COLOR_INFO}  --performance${NC}      Affiche les métriques de performance
${COLOR_INFO}  --save-logs${NC}        Sauvegarde des logs détaillés
${COLOR_INFO}  --help${NC}             Afficher cette aide

${COLOR_HEADER}${BOLD}Exemples:${NC}
${COLOR_SUCCESS}  ./run.sh${NC}                           # Mode interactif normal
${COLOR_SUCCESS}  ./run.sh --all${NC}                     # Tous les tests, mode automatique
${COLOR_SUCCESS}  ./run.sh --simple${NC}                  # Tous les tests, affichage minimal
${COLOR_SUCCESS}  ./run.sh --simple --pause-on-fail${NC}  # Affichage minimal avec pause sur échec
${COLOR_SUCCESS}  ./run.sh --debug --performance${NC}     # Mode debug avec métriques
EOF
}

