#!/bin/bash

_docker_orchestrator() {
    local cur prev commands

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    commands="enable disable start stop logs list network edit restart recreate"

    if [[ ${cur} == * ]]; then
        case "${prev}" in
            enable | disable | start | stop | logs | restart | recreate)
                local containers
                containers=$(ls /opt/docker/available)
                COMPREPLY=( $(compgen -W "${containers}" -- ${cur}) )
                return 0
                ;;
            list)
                local list_opts
                list_opts="enabled disabled"
                COMPREPLY=( $(compgen -W "${list_opts}" -- ${cur}) )
                return 0
                ;;
            network)
                local networks
                networks=$(docker network ls --format "{{.Name}}")
                COMPREPLY=( $(compgen -W "${networks}" -- ${cur}) )
                return 0
                ;;
            edit)
                local edit_containers
                edit_containers=$(ls /opt/docker/available)
                COMPREPLY=( $(compgen -W "${edit_containers}" -- ${cur}) )
                return 0
                ;;
            *)
                ;;
        esac
    fi

    COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
    return 0
}

complete -F _docker_orchestrator docker-orchestrator
