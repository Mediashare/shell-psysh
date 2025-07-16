#!/bin/bash

# =============================================================================
# SCRIPT DE MIGRATION VERS test_session_sync
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Statistiques
TOTAL_FILES=0
UPDATED_FILES=0
SKIPPED_FILES=0

echo -e "${BLUE}🔄 Migration vers test_session_sync...${NC}"

# Fonction pour traiter un fichier
process_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    # Déjà refactorisé ?
    if grep -q "test_session_sync" "$file"; then
        echo -e "${YELLOW}⏭️  Skipping $basename (already using test_session_sync)${NC}"
        ((SKIPPED_FILES++))
        return
    fi
    
    # Créer un backup si nécessaire
    if [[ ! -f "${file}.old" ]]; then
        cp "$file" "${file}.old"
    fi
    
    echo -e "${CYAN}🔄 Processing $basename...${NC}"
    
    # Variables pour construire le nouveau contenu
    local new_content=""
    local in_test_section=false
    
    # Analyser le fichier ligne par ligne
    while IFS= read -r line; do
        # Remplacer les imports
        if [[ "$line" =~ ^source.*loader\.sh ]]; then
            new_content+="# Charger test_session_sync\n"
            new_content+="source \"\$(dirname \"\$0\")/../../lib/func/test_session_sync_enhanced.sh\"\n"
            new_content+="source \"\$(dirname \"\$0\")/../../lib/func/loader.sh\"\n"
            continue
        fi
        
        # Détecter les anciens appels de test
        if [[ "$line" =~ test_execute|test_from_file|test_error_pattern|test_combined_commands ]]; then
            # Convertir en test_session_sync
            local converted_line=$(convert_test_call "$line")
            new_content+="$converted_line\n"
            continue
        fi
        
        # Garder les autres lignes
        new_content+="$line\n"
        
    done < "$file"
    
    # Écrire le nouveau contenu
    echo -e "$new_content" > "$file"
    
    echo -e "${GREEN}✅ $basename migré vers test_session_sync${NC}"
    ((UPDATED_FILES++))
}

# Fonction pour convertir un appel de test
convert_test_call() {
    local line="$1"
    
    # Extraire les paramètres de base
    if [[ "$line" =~ test_execute[[:space:]]+\"([^\"]+)\"[[:space:]]+\'([^\']+)\'[[:space:]]+\"([^\"]+)\" ]]; then
        local description="${BASH_REMATCH[1]}"
        local command="${BASH_REMATCH[2]}"
        local expected="${BASH_REMATCH[3]}"
        
        # Construire le nouvel appel
        echo "test_session_sync \"$description\" \\"
        echo "    --step \"$command\" \\"
        echo "    --expect \"$expected\" \\"
        echo "    --context monitor"
        
    elif [[ "$line" =~ test_from_file[[:space:]]+\"([^\"]+)\"[[:space:]]+\"([^\"]+)\"[[:space:]]+\"([^\"]+)\" ]]; then
        local description="${BASH_REMATCH[1]}"
        local file="${BASH_REMATCH[2]}"
        local expected="${BASH_REMATCH[3]}"
        
        echo "test_session_sync \"$description\" \\"
        echo "    --step \"cat $file\" \\"
        echo "    --expect \"$expected\" \\"
        echo "    --context shell"
        
    elif [[ "$line" =~ test_error_pattern[[:space:]]+\"([^\"]+)\"[[:space:]]+\'([^\']+)\'[[:space:]]+\"([^\"]+)\" ]]; then
        local description="${BASH_REMATCH[1]}"
        local command="${BASH_REMATCH[2]}"
        local expected="${BASH_REMATCH[3]}"
        
        echo "test_session_sync \"$description\" \\"
        echo "    --step \"$command\" \\"
        echo "    --expect \"$expected\" \\"
        echo "    --context monitor \\"
        echo "    --output-check error"
        
    else
        # Cas général - garder la ligne originale avec un commentaire
        echo "# TODO: Convertir manuellement - $line"
        echo "$line"
    fi
}

# Fonction principale
main() {
    # Vérifier que nous sommes dans le bon répertoire
    if [[ ! -d "./test/shell/Command" ]]; then
        echo -e "${RED}❌ Erreur: Répertoire test/shell/Command non trouvé${NC}"
        echo "Veuillez exécuter ce script depuis le répertoire racine du projet"
        exit 1
    fi
    
    # Trouver tous les fichiers .sh dans test/shell/Command
    mapfile -t test_files < <(find ./test/shell/Command -type f -name "*.sh" | sort)
    
    TOTAL_FILES=${#test_files[@]}
    echo -e "${BLUE}📁 Fichiers trouvés: $TOTAL_FILES${NC}"
    
    # Traiter chaque fichier
    for file in "${test_files[@]}"; do
        process_file "$file"
    done
    
    # Statistiques finales
    echo ""
    echo -e "${GREEN}📊 Migration terminée:${NC}"
    echo -e "${CYAN}   Total: $TOTAL_FILES fichiers${NC}"
    echo -e "${GREEN}   Migrés: $UPDATED_FILES fichiers${NC}"
    echo -e "${YELLOW}   Ignorés: $SKIPPED_FILES fichiers${NC}"
    
    if [[ $UPDATED_FILES -gt 0 ]]; then
        echo ""
        echo -e "${GREEN}✅ Migration réussie!${NC}"
        echo -e "${CYAN}💡 Les fichiers .old ont été conservés comme backup${NC}"
    fi
}

# Exécuter le script principal
main "$@"
