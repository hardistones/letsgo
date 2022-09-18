#!/usr/bin/env bash

source $HOME/.letsgo/res/letsgorc

THIS_SCRIPT=letsgo
LOGFILE=$LOGDIR/${THIS_SCRIPT}_$(date +%Y-%m-%d_%H-%M-%S).log

# https://askubuntu.com/questions/811439/bash-set-x-logs-to-file
# exec  1> >(tee -ia $LOGFILE)
# exec  2> >(tee -ia $LOGFILE >& 2)
# # truncate log file
# exec {FD}> $LOGFILE
# # append to log file
# # exec {FD}>> $LOGFILE
# export BASH_XTRACEFD="$FD"

set -euo pipefail

# PROJECT: the complete project path, provided by input
# PROJECT_NAME: directory name only
PROJECT=
PROJECT_NAME=
PROJECT_PARENT_DIR=
PROJECT_ALIAS=
NEW_PROJECT_ALIAS=
CREATE_PROJECT=false
SHOW_INFO=false
VALID_ALIAS='^[a-zA-Z0-9_-]+$'

trap cleanup EXIT


cleanup() {
    limit_log_files $THIS_SCRIPT
}


help_screen() {
    cat << EOF
Usage: $THIS_SCRIPT <options> PROJECT

Switch to the directory named by PROJECT.
Names unknown yet must be specified in absolute or relative path.

options:
  -a ALIAS, --alias ALIAS   Create an alias or mnemonic for the PROJECT.

  -c, --create              Create and switch to a directory named by PROJECT
                            in the current directory. Absolute or relative path
                            can also be specified. Paths with spaces must be quoted.

  -i, --info                Show info related to PROJECT.

  -t TYPE, --type TYPE      Set the type of project specifically.
                            Run '$THIS_SCRIPT --help-type' for more info.

  -h, --help                Show this help screen.

  --version                 Show version number.
EOF
    exit 0
}


parse_options() {
    [[ $# -eq 0 ]] && help_screen

    if ! options=$(getopt --name ERROR \
                          --shell bash \
                          --options a:chi \
                          --longoptions alias:,create,help,help-type,info,version \
                          -- "$@") ; then
        exit 2
    fi

    eval set -- "$options"

    while [[ $# -ne 0 ]]; do
        case $1 in
            -h|--help)
                help_screen
                ;;
            --help-type)
                help_type_screen
                ;;
            -a|--alias)
                NEW_PROJECT_ALIAS="$2"
                shift 2
                echo "create alias"
                ;;
            -c|--create)
                CREATE_PROJECT=true
                shift
                echo "create directory"
                ;;
            -i|--info)
                SHOW_INFO=true
                echo "show info"
                shift
                ;;
            --version)
                echo $VERSION_STR
                exit 0
                ;;
            --)
                shift
                PROJECT="$@"
                if [[ -z $PROJECT ]]; then
                    echo "ERROR: PROJECT argument is required."
                    exit 2
                fi
                break
                ;;
            *)
                echo "Unknown error."
                exit 2
        esac
    done
}


show_info() {
    cat << EOF

Project info
------------
Full name : $PROJECT_NAME
Alias     : $PROJECT_ALIAS
Location  : $PROJECT_PARENT_DIR
EOF
}


# $1 : project name or alias expression
find_in_memento() {
    echo
}


prepare_project_name() {
    # Aliases must be strictly have no spaces and other special characters,
    # since they are used as file extensions, when saving to memento.
    if [[ ! -z $NEW_PROJECT_ALIAS ]]; then
        if [[ ! $NEW_PROJECT_ALIAS =~ $VALID_ALIAS ]]; then
            echo "ERROR: Alias must not contain invalid characters."
            exit 2
        elif [[ ${#NEW_PROJECT_ALIAS} -gt $MAX_ALIAS_LENGTH ]]; then
            echo "ERROR: Alias cannot be more than $MAX_ALIAS_LENGTH characters."
            exit 2
        fi
    fi

    # When searching in memento, aliases must be processed first,
    # since they are the diffenrentiator between two same project names
    # in different directories.

    if ! find_in_memento "*.$PROJECT_ALIAS" && \
            ! find_in_memento "${PROJECT_NAME}*" ; then
        echo "handling unknown projects yet"
    fi

    PROJECT_NAME=$(basename "$PROJECT")
    if [[ -z $PROJECT_ALIAS ]]; then
        PROJECT_ALIAS=$PROJECT_NAME
    fi
    if [[ "$PROJECT" =~ / ]]; then
        PROJECT_PARENT_DIR=$(dirname "$PROJECT")
    fi
}


probably_python_project() {
    local dirfiles=$(ls "$@")
    local related_files="(pyproject.toml|poetry\..*|requirements.txt|.*\.py)"

    [[ "$dirfiles" =~ $related_files ]] && return 0
    return 1
}


switch_to_python_project() {
    # TODO: check for non-poetry project (only requirements.txt)
    cd $PROJECT_PARENT_DIR/$PROJECT_NAME
    poetry shell -q
}


# if there are other clean ups before switching
handle_pre_switch() {
    if probably_python_project "$(pwd)" ; then
        source deactivate > /dev/null 2>&1 || true
    fi
}


# Save the directory to the memento, and maybe other things.
handle_post_switch() {
    local extension=
    if [[ ! -z $PROJECT_ALIAS ]]; then
        extension=.$PROJECT_ALIAS
    fi
    echo "$(pwd)" > "$MEMENTO"/"$PROJECT_NAME"${extension}
}


switch() {
    handle_pre_switch
    if probably_python_project "$PROJECT_PARENT_DIR/$PROJECT_NAME" ; then
        switch_to_python_project
    else
        cd $PROJECT_PARENT_DIR/$PROJECT_NAME
    fi
    handle_post_switch
}


# main

parse_options "$@"
prepare_project_name

[[ $SHOW_INFO == true ]] && show_info && exit 0

echo
motivate
echo;echo
switch
