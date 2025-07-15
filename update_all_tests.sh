#!/bin/bash

# Chemin du fichier de synchronisation à utiliser
SYNC_SCRIPT="../../lib/func/test_session_sync_enhanced.sh"

# Fonction pour remplacer les appels de test dans un fichier
update_test_file() {
  local file="$1"
  echo "Mise à jour du fichier : $file"
  sed -i '' -e 's|\<test_execute\>|test_session_sync|g' "$file"
  sed -i '' -e 's|SCRIPT_DIR="$( cd "$( dirname \"${BASH_SOURCE[0]}\" )" && pwd )"|source "$SYNC_SCRIPT"|g' "$file"
}

# Trouver tous les fichiers de test et les mettre à jour
find ./test/shell/Command -type f -name "*.sh" | while read -r file; do
  update_test_file "$file"
done

echo "Tous les fichiers ont été mis à jour."
