#!/bin/bash

# =============================================================================
# NOUVELLE VERSION AVEC GESTION AVANCÉE DES TAGS
# =============================================================================

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

# Exemple d'utilisation avec la nouvelle syntaxe
example_new_tag_system() {
    test_session_sync "Test avec système de tags avancé" \
        --step '$var_psysh = 42' --tag "psysh" --tag "psysh_1" --tag "psysh_2" --tag "workflow" --expect "42" \
        --step "bin/console --interactive" --shell --tag "workflow" --tag "command_interactive" \
        --step "echo 'test'" --tag "workflow" --no-expect "variable not found" \
        --step "echo 'back to psysh'" --psysh --tag "workflow" --expect "back to psysh" \
        --step '$var_psysh = 99' --tag "workflow" --expect "99" \
        --step "echo $var_psysh" --tag "psysh" --expect "42" \
        --step '$var_psysh = 1' --tag "psysh" --tag "psysh_1" --expect "1" \
        --step '$var_psysh = 2' --tag "psysh" --tag "psysh_2" --expect "2" \
        --step "echo $var_psysh" --tag "psysh" --expect "2" \
        --step "echo $var_psysh" --tag "psysh_1" --expect "1" \
        --step "echo $var_psysh" --tag "psysh_2" --expect "2" \
        --step "echo $var_psysh" --tag "workflow" --expect "99" \
        --step '$var_psysh = 24' --tag "psysh" --expect "24" \
        --step "echo $var_psysh + 20" --tag "psysh_1" --expect "21" \
        --step '$var = "AZE"' --tag "command_interactive" --description "dans session bin/console -i" \
        --step "echo $var" --tag "psysh" --no-expect "AZE" \
        --step "echo $var_psysh + 1" --tag "psysh" --expect "25" \
        --step "echo $var" --tag "command_interactive" --expect "AZE" \
        --step "echo $var_psysh" --tag "command_interactive" --no-expect "24" --description "bin/console n'a pas accès aux variables psysh"
}

echo "Nouvelle version avec système de tags créée dans test_session_sync_new.sh"
echo "Les modifications incluent :"
echo "- Support des tags multiples par étape"
echo "- Options --shell et --psysh pour forcer le contexte"
echo "- Option --no-expect pour vérifier l'absence de résultats"
echo "- Gestion avancée des sessions par tag"
echo "- Persistance des variables selon les règles naturelles"
