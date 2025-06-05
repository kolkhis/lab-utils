#!/usr/bin/rbash
# shellcheck disable=SC2120

declare -i VERBOSE

declare REMOTE_USER
declare DEFAULT_USER='kolkhis'
declare DESTINATION_FILE='/destinations.txt'


# TODO(perf): Make destination(s) an array 
#   - Associative array?
#       [hostname]=192.168.4.11


declare -a DESTINATION_LIST
declare DESTINATION
declare ENDPOINT

declare LOGFILE='/var/log/bastion.log'

declare PROMPT_STRING="

Select one of the following:
 
1. Enter custom destination
2. Exit
 
> "

debug() {
    [[ $VERBOSE -gt 0 ]] || return 1
    [[ $# -gt 0 ]] && printf "[\x1b[33m DEBUG \x1b[0m]: %s\n" "$*"  && return 0
    printf "[\x1b[33mDEBUG\x1b[0m]: " 
}

err() {
    [[ $# -gt 0 ]] && printf "[ \033[31mERROR\033[0m ]: %s\n" "$*"  && return 0
    printf "[ \033[31mERROR\033[0m ]: " 
}

# log-entry() {
#     # TODO(logging): Sort out redirection for logging -- logger? rsyslog?
#     [[ $# -gt 0 ]] && printf "[%s]: %s\n" "$(date +%D-%T)" "$*" >> "$LOGFILE"
# }

parse-destinations(){ 
    mapfile -t DESTINATION_LIST < "$DESTINATION_FILE" && printf "Mapped destination file.\n"
    { [[ "${#DESTINATION_LIST[@]}" -gt 0 ]] && printf "Gathered list of destinations.\n"; } # ||
        { printf "Could not gather list of destinations. Enter manually or exit.\n" && return 1; }

    PROMPT_STRING=$(
        printf "\nEnter a destination (by name) from the list below:\n"
        for line in "${DESTINATION_LIST[@]}"; do
            # TODO(sec): Don't display user@hostname after debugging stage?
            printf "%-3s %-18s %s\n" "-" "${line%% *}" "${line##* }" 
        done
    )

    return 0
}

go-to-destination() {
#    log-entry "User attempting to connect to ${REMOTE_USER:-$DEFAULT_USER}@$DESTINATION"
    if ! ping -c 1 "${DESTINATION##*@}"; then
        err; printf "Destination host %s is unresponsive!\n" "${DESTINATION}" && return 1
        # log-entry "Server unreachable: $DESTINATION"
    fi

    if ! [[ $DESTINATION =~ @ ]]; then DESTINATION="${REMOTE_USER:-$DEFAULT_USER}@${DESTINATION}"; fi

    ssh "$DESTINATION" # || {
        # err; printf "Failed to SSH to %s as %s!\n" "$DESTINATION" "${REMOTE_USER:-$DEFAULT_USER}"
        # # log-entry "SSH command failed for ${REMOTE_USER}@${DESTINATION}"
        # return 1
    # }
    
    return 0
}


get-user-input(){
    [[ -n $1 ]] && PROMPT_STRING=$1
    local INPUT=
    read -r -n 11 -t 30 -p "$PROMPT_STRING

> " INPUT

    if [[ -n $INPUT ]]; then
        case $INPUT in

            1)
                read -r -p "Enter SSH destination (user@ip): " ENDPOINT
                REMOTE_USER="${ENDPOINT%%@*}"
                DESTINATION="${ENDPOINT##*@}"

                [[ $REMOTE_USER == "$DESTINATION" ]] &&
                    printf "No user given. Using %s.\n" "${REMOTE_USER:=$DEFAULT_USER}" &&
                    DESTINATION="${REMOTE_USER}@${DESTINATION}"

                # debug "Going to '$DESTINATION' as '$REMOTE_USER'"
                # log-entry "Custom location provided: ${REMOTE_USER}@${DESTINATION}"
                # go-to-destination || {
                #     printf "Failed to connect!\n"
                #     # log-entry "Call to go-to-destination failed with ${REMOTE_USER}@${DESTINATION}"
                #     return 1
                # }
                return 0
                ;;

            2)
                printf "Leaving now.\n"
                return 0
                ;;

            [[:alpha:]]*)
                : "This should be a destination in" "${DESTINATION_LIST[@]}"
                debug "User entered input: $INPUT"

                if [[ ${DESTINATION_LIST[*]} =~ ${INPUT} ]]; then
                    debug "User input matched in destinations: $INPUT"
                    for d in "${DESTINATION_LIST[@]}"; do
                        if [[ $INPUT == "${d%% *}" ]]; then 
                            DESTINATION="${d##* }"
                            # go-to-destination
                            return 0
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


printf "\x1b[2J\x1b[H"

parse-destinations || {
    err; printf >&2 "Failed to parse destinations file: %s\n" "$DESTINATION_FILE"
}

# TODO(perf): Break go-to-destination out of get-user-input
get-user-input || {
    err; printf "Bad user input!\n" # && continue
    # log-entry "Failed connection to ${REMOTE_USER}@${DESTINATION}"
}

{ [[ -n $DESTINATION ]] && go-to-destination; } || {
    err; printf >&2 "Destination empty or unreachable!\n" && exit 1
}

# log-entry "Exiting bastion program."
printf "Exiting.\n"

exit 0

