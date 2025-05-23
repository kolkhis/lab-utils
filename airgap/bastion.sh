#!/usr/bin/rbash

# export PATH=/bin:/usr/bin
declare -i VERBOSE

declare DEFAULT_USER='kolkhis'

declare REMOTE_USER
declare DESTINATION=192.168.4.11
declare ENDPOINT

declare PROMPT_STRING="
Welcome!
Select one of the following:

1. Connect to DestinationHost
2. Enter custom destination
3. Exit

> "



# TODO(perf): 
#   - Read from an SSH config for list of available connections
#       - Format?
#           - Host?
#           - Hostname?
#           - User@Hostname?
#       - Parse with perl, awk, grep
#   - Problem: This script does not have access to those parsing programs.  
#       - Solution:
#           - Parse in setup script and read from file for choices.


debug(){
    [[ $VERBOSE -gt 0 ]] && printf "[\x1b[33mDEBUG\x1b[0m]: %s\n" "$*"
}

err() {
    printf "[ \033[31mERROR\033[0m ]: " 
}

# parse-ssh-file() {
#     # TODO: Finish this -- dynamically generate choices based on SSH config file.
#     # Must happen in setup? No access to parsing tools (sed, awk, perl)
#     local CONFIG_FILE=
#     { [[ -f ~/.ssh/config ]] && CONFIG_FILE="$HOME/.ssh/config"; } || 
#         { [[ -f /etc/ssh/ssh_config ]] && CONFIG_FILE="/etc/ssh/ssh_config"; }
#     debug "Using config file: $CONFIG_FILE"
# }

go-to-destination() {
    if ! ping -c 1 "$DESTINATION"; then
        err; printf "Destination host is unresponsive!\n" && return 1
    fi

    ssh "${REMOTE_USER:-$DEFAULT_USER}@${DESTINATION}" || {
        err; printf "Failed to SSH to %s as %s!\n" "$DESTINATION" "${REMOTE_USER:-$DEFAULT_USER}"
        return 1
    }
}

while [[ -n $1 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=1
            ;;
        *)
            ;;
    esac
done


# if [[ -f ~/.ssh/config ]] || [[ -f /etc/ssh/ssh_config ]]; then
#     parse-ssh-file
# fi

get-user-input(){
    local INPUT
    read -r -n 2 -t 20 -p "$PROMPT_STRING" INPUT

    if [[ -n $INPUT ]]; then

        case $INPUT in
            1)
                printf "Going to DestinationHost.\n"
                go-to-destination || {
                    printf "Failed to connect!\n" && return 1
                }
                return 0
                ;;
            2)
                read -r -p "Enter SSH destination (user@ip): " ENDPOINT
                REMOTE_USER="${ENDPOINT%%@*}"
                DESTINATION="${ENDPOINT##*@}"
                debug "Going to '$DESTINATION' as '$USER'"
                go-to-destination || {
                    printf "Failed to connect!\n" && return 1
                }
                ;;
            3)
                printf "Leaving now.\n"
                return 0
                ;;
            [^0-9])
                printf "You can only enter numbers.\n"
                return 1
                ;;
            *)
                printf "Unknown input. Goodbye.\n"
                return 1
                ;;
        esac

    fi

}


declare -i CONNECTED=0

# - If trying to connect to unresponsive host, kick back to input prompt
while [[ -z $CONNECTED ]]; do
    get-user-input || {
        printf "Failed to connect!" && continue
    }
    CONNECTED=1
done

exit 0



