#!/usr/bin/bash
# shellcheck disable=SC2120

#export PATH=/bin:/usr/bin
declare -i VERBOSE

declare REMOTE_USER
declare DEFAULT_USER='kolkhis'
declare DESTINATION_FILE='/var/chroot/destinations.txt'


# TODO(perf): Make destination(s) an array 
#   - Associative array?
#       [hostname]=192.168.4.11


declare -a DESTINATIONS
declare DESTINATION=192.168.4.11
declare ENDPOINT

declare LOGFILE='/var/log/bastion.log'

declare PROMPT_STRING="
Welcome!
Select one of the following:
 
1. Connect to a pre-configured destination host
2. Enter custom destination
3. Exit
 
> "

# TODO(perf): 
#   - [x] Read from an SSH config for list of available connections
#       - Format - `host user@hostname`
#       - Parse with perl, awk, grep
#   - Problem: This script does not have access to those parsing programs.  
#       - Solution:
#           - Parse in setup script and read from file for choices.
# TODO(feat): 
#   - [ ] Read from destinations.txt for choices to give to user


debug() {
    [[ $VERBOSE -gt 0 ]] && printf "[\x1b[33mDEBUG\x1b[0m]: %s\n" "$*"
}

err() {
    printf "[ \033[31mERROR\033[0m ]: " 
}

log-entry() {
    [[ $# -gt 0 ]] && printf "[%s]: %s\n" "$(date +%D-%T)" "$*" >> "$LOGFILE"
}

go-to-destination() {
    log-entry "User attempting to connect to ${REMOTE_USER:-$DEFAULT_USER}@$DESTINATION"
    if ! ping -c 1 "$DESTINATION"; then
        err; printf "Destination host is unresponsive!\n" && return 1
        log-entry "Server unreachable: $DESTINATION"
    fi

    ssh "${REMOTE_USER:-$DEFAULT_USER}@${DESTINATION}" || {
        err; printf "Failed to SSH to %s as %s!\n" "$DESTINATION" "${REMOTE_USER:-$DEFAULT_USER}"
        log-entry "SSH command failed for ${REMOTE_USER}@${DESTINATION}"
        return 1
    }
    return 0
}

# TODO(perf): 
#   - [ ] Handle this failure gracefully and only present user with options that exist.  
#   - [ ] Do not display this error message to jailed user
#       - Redirect stderr to logfile not readable by jailed user?

parse-destinations(){ 
    [[ -f "$DESTINATION_FILE" ]] || return 1
    mapfile -t DESTINATIONS < "$DESTINATION_FILE" || return 1
    [[ "${#DESTINATION[@]}" -gt 0 ]] && printf "Gathered list of destinations.\n" ||
        printf "Could not gather list of destinations. Enter manually or exit.\n"
    declare destination_prompt
    destination_prompt="Pick a destination (select by hostname, first column): $(printf "\n"; printf "%s\n" "${DESTINATIONS[@]}")"
    printf "%s\n" "$destination_prompt"
    return 0
}

parse-destinations || {
    err; printf >&2 "Failed to parse destinations file: %s\n" "$DESTINATION_FILE"
}


get-user-input(){
    [[ -n $1 ]] && PROMPT_STRING=$1
    local INPUT
    read -r -n 2 -t 20 -p "$PROMPT_STRING" INPUT

    if [[ -n $INPUT ]]; then
        case $INPUT in
            1)
                # TODO(perf):
                #   - This case will call get-user-input with a new PROMPT_STRING and
                #     will carry over to the [^0-9] case to connect to a destination in
                #     ${DESTINATIONS[@]}
                printf "Connect to a pre-configured host:\n"
                [[ ${#DESTINATIONS[@]} -gt 0 ]] || err "No destinations to read from!" && exit 1
                local new_prompt
                new_prompt=
                # get-user-input "$(printf "%s\n" "${DESTINATIONS[@]")"
                return 0
                ;;
            2)
                read -r -p "Enter SSH destination (user@ip): " ENDPOINT

                # POSIX-comliant:
                # REMOTE_USER="$(printf "%s" "$ENDPOINT" | cut -d '@' -f 1)"
                # DESTINATION="$(printf "%s" "$ENDPOINT" | cut -d '@' -f 2)"

                REMOTE_USER="${ENDPOINT%%@*}"
                DESTINATION="${ENDPOINT##*@}"

                # TODO(perf): Check if user was specified, along with @. If not, use
                # default user and handle @
                [[ $REMOTE_USER == "$DESTINATION" ]] &&
                    printf "No user given. Using %s.\n" "${REMOTE_USER:=$DEFAULT_USER}"

                debug "Going to '$DESTINATION' as '$REMOTE_USER'"
                log-entry "Custom location provided: ${REMOTE_USER}@${DESTINATION}"
                go-to-destination || {
                    printf "Failed to connect!\n"
                    log-entry "Call to go-to-destination failed with ${REMOTE_USER}@${DESTINATION}"
                    return 1
                }
                return 0
                ;;

            3)
                printf "Leaving now.\n"
                return 0
                ;;

            [^0-9])
                : "This should be a destination in" "${DESTINATIONS[@]}"
                debug "User entered input: $INPUT"
                if [[ "${DESTINATIONS[*]}" =~ $INPUT ]]; then
                    # TODO: Extract the correct destination based on input
                    debug "User input matched in destinations: $INPUT"
                    for d in "${DESTINATIONS[@]}"; do
                        if grep -qi "$INPUT" <<< "$d"; then
                            DESTINATION="${d##* }"
                            debug "Destination extracted: $DESTINATION"
                        fi
                    done
                fi
                return 1
                ;;

            *)
                printf "Unknown input. Goodbye.\n"
                return 1
                ;;

        esac

    fi

}

while [[ -n $1 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=1
            shift;
            ;;
        *)
            printf "Unknown argument: %s\n" "$1"
            shift;
            ;;
    esac
done

# - If trying to connect to unresponsive host, kick back to input prompt
#   - Tried: 
#       - While loop w/ continue and 'CONNECTED' flag (locale error)
#       - For loop w/ attempts and connected flag (kicks back to jump box prompt after exiting destination)

get-user-input || {
    printf "Failed to connect!" # && continue
    log-entry "Failed connection to ${REMOTE_USER}@${DESTINATION}"
}

log-entry "Exiting bastion program."

exit 0

