#!/bin/bash

# Configuration globale pour les tests shell PsySH
# Ce fichier centralise toutes les variables d'environnement et configurations

# =================== COULEURS ===================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export BOLD='\033[1m'
export DIM='\033[2m'
export NC='\033[0m' # No Color

# Couleurs d'état
export COLOR_SUCCESS="$GREEN"
export COLOR_ERROR="$RED"
export COLOR_WARNING="$YELLOW"
export COLOR_INFO="$BLUE"
export COLOR_DEBUG="$CYAN"
export COLOR_HEADER="$PURPLE"

# =================== VARIABLES GLOBALES ===================
# Répertoires
export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
export TEST_LIB_DIR="$SCRIPT_DIR/lib"
export TEST_COMMAND_DIR="$SCRIPT_DIR/Command"
export TEST_TEMP_DIR="$SCRIPT_DIR/.temp"

# Configuration des tests
export DEFAULT_TIMEOUT=30
export MAX_OUTPUT_LINES=5000
export DEBUG_PSYSH=${DEBUG_PSYSH:-0}
export VERBOSE_TESTS=${VERBOSE_TESTS:-0}

# Modes d'exécution (valeurs par défaut)
export AUTO_MODE=${AUTO_MODE:-0}
export SIMPLE_MODE=${SIMPLE_MODE:-0}
export PAUSE_ON_FAIL=${PAUSE_ON_FAIL:-0}
export DEBUG_MODE=${DEBUG_MODE:-0}
export QUIET_MODE=${QUIET_MODE:-0}
export DRY_RUN_MODE=${DRY_RUN_MODE:-0}

# Flags booléens pour contrôle fin
export EXPLICIT_SIMPLE_MODE=0
export SHOW_PERFORMANCE_METRICS=${SHOW_PERFORMANCE_METRICS:-0}
export SAVE_DETAILED_LOGS=${SAVE_DETAILED_LOGS:-0}

# =================== ICÔNES ET EMOJIS ===================
export ICON_SUCCESS="✅"
export ICON_ERROR="❌"
export ICON_WARNING="⚠️"
export ICON_INFO="ℹ️"
export ICON_DEBUG="🔍"
export ICON_TEST="🧪"
export ICON_ROCKET="🚀"
export ICON_PAUSE="⏸️"
export ICON_PLAY="▶️"
export ICON_STOP="⏹️"
export ICON_RETRY="🔄"
export ICON_SKIP="⏭️"
export ICON_FOLDER="📂"
export ICON_FILE="📄"
export ICON_CODE="💻"
export ICON_PERFORMANCE="⚡"
export ICON_MEMORY="💾"
export ICON_TIME="⏱️"
export ICON_CHART="📊"

# =================== CONFIGURATION PHPUNIT ===================
export PHPUNIT_CONFIG_FILE="$PROJECT_ROOT/phpunit.xml"
export PHPUNIT_BOOTSTRAP="$PROJECT_ROOT/vendor/autoload.php"
export PSYSH_BINARY="$PROJECT_ROOT/bin/psysh"

# =================== CONFIGURATION DE DEBUG ===================
export DEBUG_SHOW_COMMANDS=${DEBUG_SHOW_COMMANDS:-0}
export DEBUG_SHOW_OUTPUT=${DEBUG_SHOW_OUTPUT:-1}
export DEBUG_SHOW_TIMING=${DEBUG_SHOW_TIMING:-0}
export DEBUG_SAVE_OUTPUTS=${DEBUG_SAVE_OUTPUTS:-0}

# =================== STATISTIQUES GLOBALES ===================
# Variables pour le comptage global (réinitialisées par run.sh)
export TOTAL_TESTS_COUNT=0
export TOTAL_PASS_SCRIPTS=0
export TOTAL_FAIL_SCRIPTS=0
export TOTAL_SKIPPED_SCRIPTS=0
export TOTAL_EXECUTION_TIME=0

# =================== FONCTIONS D'INITIALISATION ===================

# Fonction pour créer les répertoires nécessaires
init_test_environment() {
    # Créer le répertoire temporaire s'il n'existe pas
    if [[ ! -d "$TEST_TEMP_DIR" ]]; then
        mkdir -p "$TEST_TEMP_DIR"
    fi
    
    # Vérifier que psysh est disponible
    if [[ ! -f "$PSYSH_BINARY" ]]; then
        echo -e "${COLOR_ERROR}Erreur: psysh binary non trouvé à $PSYSH_BINARY${NC}" >&2
        return 1
    fi
    
    # Créer le fichier de log de session si nécessaire
    if [[ "$SAVE_DETAILED_LOGS" == "1" ]]; then
        export SESSION_LOG_FILE="$TEST_TEMP_DIR/session_$(date +%Y%m%d_%H%M%S).log"
        touch "$SESSION_LOG_FILE"
    fi
    
    return 0
}

# Fonction pour nettoyer l'environnement de test
cleanup_test_environment() {
    # Nettoyer les fichiers temporaires (sauf si DEBUG_SAVE_OUTPUTS=1)
    if [[ "$DEBUG_SAVE_OUTPUTS" != "1" && -d "$TEST_TEMP_DIR" ]]; then
        find "$TEST_TEMP_DIR" -name "*.tmp" -mtime +1 -delete 2>/dev/null || true
    fi
}

# Fonction pour valider la configuration
validate_config() {
    local errors=0
    
    # Vérifier les répertoires essentiels
    for dir in "$PROJECT_ROOT" "$TEST_LIB_DIR" "$TEST_COMMAND_DIR"; do
        if [[ ! -d "$dir" ]]; then
            echo -e "${COLOR_ERROR}Erreur: Répertoire manquant: $dir${NC}" >&2
            ((errors++))
        fi
    done
    
    # Vérifier les fichiers essentiels
    if [[ ! -f "$PSYSH_BINARY" ]]; then
        echo -e "${COLOR_ERROR}Erreur: Binary psysh manquant: $PSYSH_BINARY${NC}" >&2
        ((errors++))
    fi
    
    return $errors
}

# =================== FONCTIONS UTILITAIRES ===================

# Fonction pour afficher la configuration actuelle (mode debug)
show_config() {
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo -e "${COLOR_DEBUG}=== CONFIGURATION DEBUG ===${NC}"
        echo -e "${COLOR_INFO}PROJECT_ROOT:${NC} $PROJECT_ROOT"
        echo -e "${COLOR_INFO}PSYSH_BINARY:${NC} $PSYSH_BINARY"
        echo -e "${COLOR_INFO}Modes actifs:${NC}"
        [[ "$AUTO_MODE" == "1" ]] && echo -e "  - ${COLOR_SUCCESS}AUTO_MODE${NC}"
        [[ "$SIMPLE_MODE" == "1" ]] && echo -e "  - ${COLOR_SUCCESS}SIMPLE_MODE${NC}"
        [[ "$PAUSE_ON_FAIL" == "1" ]] && echo -e "  - ${COLOR_SUCCESS}PAUSE_ON_FAIL${NC}"
        [[ "$DEBUG_MODE" == "1" ]] && echo -e "  - ${COLOR_SUCCESS}DEBUG_MODE${NC}"
        [[ "$QUIET_MODE" == "1" ]] && echo -e "  - ${COLOR_SUCCESS}QUIET_MODE${NC}"
        echo -e "${COLOR_DEBUG}=========================${NC}"
        echo ""
    fi
}

# Fonction pour initialiser automatiquement l'environnement au sourcing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Le fichier est sourcé, initialiser automatiquement
    init_test_environment
fi
