#!/bin/bash

DOCKER_AVAILABLE_DIR="/opt/docker/available"
DOCKER_ENABLED_DIR="/opt/docker/enabled"

# Vérifier si le dossier /opt/docker-enabled existe, sinon le créer
if [ ! -d "$DOCKER_ENABLED_DIR" ]; then
    mkdir -p "$DOCKER_ENABLED_DIR"
fi

enable_container() {
    container_name=$1
    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur à activer."
        return
    fi

    if [ -d "$DOCKER_AVAILABLE_DIR/$container_name" ]; then
        ln -s "$DOCKER_AVAILABLE_DIR/$container_name" "$DOCKER_ENABLED_DIR/"
        start_container "$container_name"
        echo "Le conteneur $container_name a été activé."
    else
        echo "Le conteneur $container_name n'existe pas dans $DOCKER_AVAILABLE_DIR."
    fi
}

disable_container() {
    container_name=$1
    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur à désactiver."
        return
    fi

    if [ -L "$DOCKER_ENABLED_DIR/$container_name" ]; then
        stop_container "$container_name"
        rm "$DOCKER_ENABLED_DIR/$container_name"
        echo "Le conteneur $container_name a été désactivé."
    else
        echo "Le conteneur $container_name n'est pas actif."
    fi
}

update_container() {
    container_name=$1
    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur à mettre à jour."
        return
    fi
    if [ "$1" == "all" ]; then
	cd "$DOCKER_ENABLED_DIR"
	for folder in */; do
	    folder=${folder%/}
	    update_container "$folder" || continue
	    done
    else
	if [ -L "$DOCKER_ENABLED_DIR/$container_name" ]; then
	    update_output_file=$(mktemp)
	    cd "$DOCKER_ENABLED_DIR/$container_name" && script -q "$update_output_file" -c "docker compose pull" # Keep the docker compose stylised output
	    update_wc=$(cat "$update_output_file" | wc -l)
	    if [ "$update_wc" -gt 23 ]; then
	        recreate_container "$container_name"
	        echo "Le conteneur $container_name a été mis à jour avec succès."
	    else
		echo "Le conteneur $container_name est à jour."
	    fi
	    rm "$update_output_file"
	else
	    echo "Le conteneur $container_name n'est pas actif."
	fi
    fi
}

start_container() {
    container_name=$1
    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur à démarrer."
        return
    fi

    if [ -L "$DOCKER_ENABLED_DIR/$container_name" ]; then
        cd "$DOCKER_ENABLED_DIR/$container_name" && docker compose up -d
        echo "Le conteneur $container_name a été démarré."
    else
        echo "Le conteneur $container_name n'est pas actif."
    fi
}

stop_container() {
    container_name=$1
    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur à arrêter."
        return
    fi

    if [ -L "$DOCKER_ENABLED_DIR/$container_name" ]; then
        cd "$DOCKER_ENABLED_DIR/$container_name" && docker compose down
        echo "Le conteneur $container_name a été arrêté."
    else
        echo "Le conteneur $container_name n'est pas actif."
    fi
}

restart_container() {
    container_name=$1
    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur à redémarrer."
        return
    fi

    if [ -L "$DOCKER_ENABLED_DIR/$container_name" ]; then
        cd "$DOCKER_ENABLED_DIR/$container_name" && docker compose restart
        echo "Le conteneur $container_name a été redémarré."
    else
        echo "Le conteneur $container_name n'est pas actif."
    fi
}


show_logs() {
    container_name=$1
    follow_logs=$2

    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur pour afficher les logs."
        return
    fi

    if [ "$follow_logs" = "-f" ]; then
        follow=true
    else
        follow=false
    fi

    if [ -L "$DOCKER_ENABLED_DIR/$container_name" ]; then
        cd "$DOCKER_ENABLED_DIR/$container_name" || exit 1
        if [ "$follow" = true ]; then
            docker compose logs -f
        else
            docker compose logs
        fi
        cd - > /dev/null || exit 1
    else
        echo "Le conteneur $container_name n'est pas actif."
    fi
}

list_containers() {
    filter_status=$1
    if [ "$filter_status" = "enabled" ]; then
        echo "Liste des conteneurs activés :"
        ls -l "$DOCKER_ENABLED_DIR" | awk '{print $NF}' | sed 's#.*/##'
    elif [ "$filter_status" = "disabled" ]; then
        echo "Liste des conteneurs désactivés :"
        ls "$DOCKER_AVAILABLE_DIR" | grep -v -f <(ls "$DOCKER_ENABLED_DIR" | sed 's#.*/##')
    else
        echo "Liste des conteneurs disponibles :"
        ls "$DOCKER_AVAILABLE_DIR"
    fi
}

network_table() {
    network_name=$1
    if [ -z "$network_name" ]; then
        echo "Veuillez spécifier le nom du réseau Docker."
        return
    fi

    printf "%-30s%-30s%-20s\n" "Nom du Conteneur" "Adresse IP" "Ports Ouverts"
    printf "%-30s%-30s%-20s\n" "================" "============" "============"

    container_ids=$(docker network inspect --format='{{range $id, $container := .Containers}}{{$id}} {{end}}' "$network_name")
    for container_id in $container_ids; do
        container_name=$(docker ps --filter "id=$container_id" --format '{{.Names}}')
        ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{printf "%s " .IPAddress}}{{end}}' "$container_id")
        open_ports=$(docker port "$container_id" | awk '{print $3}' | paste -sd "," -)

        printf "%-30s%-30s%-20s\n" "$container_name" "$ip_address" "$open_ports"
    done
}

edit_container() {
    container_name=$1
    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur à éditer."
        return
    fi

    if [ -d "$DOCKER_AVAILABLE_DIR/$container_name" ]; then
        ${EDITOR:-nano} "$DOCKER_AVAILABLE_DIR/$container_name/docker-compose.yml"
    else
        echo "Le conteneur $container_name n'existe pas dans $DOCKER_AVAILABLE_DIR."
    fi
}


recreate_container() {
    container_name=$1
    if [ -z "$container_name" ]; then
        echo "Veuillez spécifier le nom du conteneur à recréer."
        return
    fi

    stop_container "$container_name"
    start_container "$container_name"
}

# Auto-complétion pour les noms de conteneurs disponibles
_autocomplete_containers() {
    local available_containers
    available_containers=$(ls "$DOCKER_AVAILABLE_DIR")
    COMPREPLY=($(compgen -W "$available_containers" -- "${COMP_WORDS[COMP_CWORD]}"))
}

# Fonctionnalité d'autocomplétion pour les commandes
_autocomplete_service_commands() {
    local commands=("enable" "disable" "start" "stop" "logs" "list" "network" "edit" "restart" "recreate")
    COMPREPLY=($(compgen -W "${commands[*]}" -- "${COMP_WORDS[COMP_CWORD]}"))
}

_autocomplete_list_arguments() {
    local list_args=("enabled" "disabled")
    COMPREPLY=($(compgen -W "${list_args[*]}" -- "${COMP_WORDS[COMP_CWORD]}"))
}

_autocomplete_networks() {
    local docker_networks
    docker_networks=$(docker network ls --format "{{.Name}}")
    COMPREPLY=($(compgen -W "$docker_networks" -- "${COMP_WORDS[COMP_CWORD]}"))
}

# Configuration de l'autocomplétion en fonction de la commande
_autocomplete() {
    case "${COMP_WORDS[1]}" in
        enable | disable | start | stop | logs | edit | restart | recreate | update)
            _autocomplete_containers
            ;;
        list)
            if [ "${#COMP_WORDS[@]}" -eq 2 ]; then
                _autocomplete_service_commands
            elif [ "${#COMP_WORDS[@]}" -eq 3 ]; then
                _autocomplete_list_arguments
            fi
            ;;
        network)
            if [ "${#COMP_WORDS[@]}" -eq 2 ]; then
                _autocomplete_networks
            fi
            ;;
        *)
            _autocomplete_service_commands
            ;;
    esac
}

# Définition de l'autocomplétion pour notre script
complete -F _autocomplete docker-orchestrator

# Gestion des commandes
case "$1" in
    enable)
        enable_container "$2"
        ;;
    disable)
        disable_container "$2"
        ;;
    start)
        start_container "$2"
        ;;
    stop)
        stop_container "$2"
        ;;
    logs)
        show_logs "$2" "$3"
        ;;
    list)
        list_containers "$2"
        ;;
    network)
        network_table "$2"
        ;;
    edit)
        edit_container "$2"
        ;;
    restart)
        restart_container "$2"
        ;;
    recreate)
        recreate_container "$2"
        ;;
    update)
        update_container "$2"
        ;;
    *)
        echo "Utilisation : docker-orchestrator {enable|disable|start|stop|logs|list|network|edit|restart|recreate|update} <nom_du_conteneur>"
        ;;
esac
