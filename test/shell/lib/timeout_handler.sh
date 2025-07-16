#!/bin/bash

# =============================================================================
# TIMEOUT HANDLER - Gestion portable des timeouts
# =============================================================================
# Ce module détecte automatiquement la meilleure méthode pour gérer les timeouts
# selon le système d'exploitation et les outils disponibles

# Variables globales pour le timeout
TIMEOUT_METHOD=""
TIMEOUT_AVAILABLE=false

# =============================================================================
# DÉTECTION DES MÉTHODES DE TIMEOUT DISPONIBLES
# =============================================================================

# Fonction pour détecter la méthode de timeout optimale
detect_timeout_method() {
    local method=""
    
    # 1. Tester la commande timeout (GNU coreutils)
    if command -v timeout >/dev/null 2>&1; then
        # Tester si c'est GNU timeout (supporte --preserve-status)
        if timeout --help 2>&1 | grep -q "preserve-status" 2>/dev/null; then
            method="gnu_timeout"
        else
            # Probablement BSD timeout (macOS) ou autre implémentation
            method="bsd_timeout"
        fi
    
    # 2. Tester gtimeout (GNU timeout sur macOS via Homebrew)
    elif command -v gtimeout >/dev/null 2>&1; then
        method="gnu_gtimeout"
    
    # 3. Fallback vers perl (disponible sur la plupart des systèmes)
    elif command -v perl >/dev/null 2>&1; then
        method="perl_timeout"
    
    # 4. Fallback vers python (si disponible)
    elif command -v python3 >/dev/null 2>&1; then
        method="python_timeout"
    elif command -v python >/dev/null 2>&1; then
        method="python_timeout"
    
    # 5. Fallback vers bash avec signaux (méthode basique)
    else
        method="bash_timeout"
    fi
    
    TIMEOUT_METHOD="$method"
    TIMEOUT_AVAILABLE=true
    
    # Debug info
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo -e "${CYAN}[DEBUG] Méthode de timeout détectée: $method${NC}" >&2
    fi
}

# =============================================================================
# IMPLÉMENTATIONS DES DIFFÉRENTES MÉTHODES DE TIMEOUT
# =============================================================================

# Méthode 1: GNU timeout (Linux et autres systèmes GNU)
run_with_gnu_timeout() {
    local timeout_duration="$1"
    shift
    timeout --preserve-status "$timeout_duration" "$@"
}

# Méthode 2: BSD timeout (macOS système)
run_with_bsd_timeout() {
    local timeout_duration="$1"
    shift
    timeout "$timeout_duration" "$@"
}

# Méthode 3: GNU gtimeout (macOS avec Homebrew)
run_with_gnu_gtimeout() {
    local timeout_duration="$1"
    shift
    gtimeout --preserve-status "$timeout_duration" "$@"
}

# Méthode 4: Perl timeout (très portable)
run_with_perl_timeout() {
    local timeout_duration="$1"
    shift
    local temp_script=$(mktemp)
    
    cat > "$temp_script" << 'EOF'
#!/usr/bin/perl
use strict;
use warnings;
use POSIX ":sys_wait_h";

my $timeout = shift @ARGV;
my $pid = fork();

if ($pid == 0) {
    # Processus enfant - exécuter la commande
    exec @ARGV;
    exit 1;
} elsif ($pid > 0) {
    # Processus parent - gérer le timeout
    my $start_time = time();
    
    while (time() - $start_time < $timeout) {
        my $kid = waitpid($pid, WNOHANG);
        if ($kid > 0) {
            # Processus terminé
            my $exit_code = $? >> 8;
            unlink $0;
            exit $exit_code;
        }
        sleep 0.1;
    }
    
    # Timeout atteint
    kill 'TERM', $pid;
    sleep 1;
    kill 'KILL', $pid;
    waitpid($pid, 0);
    unlink $0;
    exit 124;  # Code d'erreur standard pour timeout
} else {
    die "Fork failed: $!";
}
EOF
    
    chmod +x "$temp_script"
    "$temp_script" "$timeout_duration" "$@"
    local exit_code=$?
    rm -f "$temp_script"
    return $exit_code
}

# Méthode 5: Python timeout
run_with_python_timeout() {
    local timeout_duration="$1"
    shift
    local temp_script=$(mktemp)
    
    cat > "$temp_script" << 'EOF'
#!/usr/bin/env python3
import sys
import subprocess
import signal
import time

def timeout_handler(signum, frame):
    raise TimeoutError("Command timed out")

def run_with_timeout(timeout_duration, command):
    try:
        # Configurer le gestionnaire de signal
        signal.signal(signal.SIGALRM, timeout_handler)
        signal.alarm(int(float(timeout_duration)))
        
        # Exécuter la commande
        result = subprocess.run(command, capture_output=False)
        
        # Annuler l'alarme
        signal.alarm(0)
        
        return result.returncode
        
    except TimeoutError:
        return 124  # Code d'erreur standard pour timeout
    except Exception as e:
        return 1

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(1)
    
    timeout_duration = sys.argv[1]
    command = sys.argv[2:]
    
    exit_code = run_with_timeout(timeout_duration, command)
    sys.exit(exit_code)
EOF
    
    # Déterminer quelle version de Python utiliser
    local python_cmd="python3"
    if ! command -v python3 >/dev/null 2>&1; then
        python_cmd="python"
    fi
    
    chmod +x "$temp_script"
    "$python_cmd" "$temp_script" "$timeout_duration" "$@"
    local exit_code=$?
    rm -f "$temp_script"
    return $exit_code
}

# Méthode 6: Bash timeout (fallback basique)
run_with_bash_timeout() {
    local timeout_duration="$1"
    shift
    
    # Lancer la commande en arrière-plan
    "$@" &
    local pid=$!
    
    # Fonction pour tuer le processus
    local timeout_occurred=false
    
    # Lancer un processus de timeout en arrière-plan
    (
        sleep "$timeout_duration"
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null
            sleep 1
            kill -KILL "$pid" 2>/dev/null
        fi
    ) &
    local timeout_pid=$!
    
    # Attendre que la commande se termine
    wait "$pid" 2>/dev/null
    local exit_code=$?
    
    # Tuer le processus de timeout s'il est encore actif
    kill "$timeout_pid" 2>/dev/null
    wait "$timeout_pid" 2>/dev/null
    
    return $exit_code
}

# =============================================================================
# FONCTION PRINCIPALE : run_with_timeout
# =============================================================================

# Fonction principale unifiée pour exécuter une commande avec timeout
# Usage: run_with_timeout <timeout_seconds> <command> [args...]
run_with_timeout() {
    local timeout_duration="$1"
    shift
    
    # Vérifier que le timeout est numérique
    if ! [[ "$timeout_duration" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "${RED}[ERROR] Timeout duration must be numeric: $timeout_duration${NC}" >&2
        return 1
    fi
    
    # Détecter la méthode si pas encore fait
    if [[ -z "$TIMEOUT_METHOD" ]]; then
        detect_timeout_method
    fi
    
    # Vérifier qu'une méthode est disponible
    if [[ "$TIMEOUT_AVAILABLE" != "true" ]]; then
        echo -e "${RED}[ERROR] No timeout method available${NC}" >&2
        return 1
    fi
    
    # Debug info
    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo -e "${CYAN}[DEBUG] Executing with timeout $timeout_duration using method: $TIMEOUT_METHOD${NC}" >&2
        echo -e "${CYAN}[DEBUG] Command: $*${NC}" >&2
    fi
    
    # Exécuter avec la méthode appropriée
    case "$TIMEOUT_METHOD" in
        "gnu_timeout")
            run_with_gnu_timeout "$timeout_duration" "$@"
            ;;
        "bsd_timeout")
            run_with_bsd_timeout "$timeout_duration" "$@"
            ;;
        "gnu_gtimeout")
            run_with_gnu_gtimeout "$timeout_duration" "$@"
            ;;
        "perl_timeout")
            run_with_perl_timeout "$timeout_duration" "$@"
            ;;
        "python_timeout")
            run_with_python_timeout "$timeout_duration" "$@"
            ;;
        "bash_timeout")
            run_with_bash_timeout "$timeout_duration" "$@"
            ;;
        *)
            echo -e "${RED}[ERROR] Unknown timeout method: $TIMEOUT_METHOD${NC}" >&2
            return 1
            ;;
    esac
}

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

# Fonction pour tester la méthode de timeout
test_timeout_method() {
    echo -e "${BLUE}Test de la méthode de timeout...${NC}"
    
    detect_timeout_method
    
    echo -e "${CYAN}Méthode détectée: $TIMEOUT_METHOD${NC}"
    
    # Test simple
    echo -e "${YELLOW}Test 1: Commande rapide (doit réussir)${NC}"
    if run_with_timeout 5 echo "Test réussi"; then
        echo -e "${GREEN}✅ Test 1 réussi${NC}"
    else
        echo -e "${RED}❌ Test 1 échoué${NC}"
    fi
    
    # Test avec timeout
    echo -e "${YELLOW}Test 2: Commande lente (doit timeout)${NC}"
    if run_with_timeout 2 sleep 5; then
        echo -e "${RED}❌ Test 2 échoué (pas de timeout)${NC}"
    else
        echo -e "${GREEN}✅ Test 2 réussi (timeout détecté)${NC}"
    fi
    
    echo -e "${BLUE}Test terminé${NC}"
}

# Fonction pour obtenir des informations sur le système
get_system_info() {
    echo -e "${BLUE}Informations système:${NC}"
    echo -e "${CYAN}OS: $(uname -s)${NC}"
    echo -e "${CYAN}Version: $(uname -r)${NC}"
    echo -e "${CYAN}Architecture: $(uname -m)${NC}"
    
    echo -e "${BLUE}Outils disponibles:${NC}"
    for tool in timeout gtimeout perl python python3 bash; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $tool: $(command -v "$tool")${NC}"
        else
            echo -e "${RED}❌ $tool: non disponible${NC}"
        fi
    done
}

# =============================================================================
# INITIALISATION AUTOMATIQUE
# =============================================================================

# Détecter automatiquement la méthode au chargement du module
detect_timeout_method

# Export des fonctions principales
export -f run_with_timeout test_timeout_method get_system_info detect_timeout_method
