#!/usr/bin/rbash

# TODO(perf): 
#   - Read from an SSH config for list of available connections
#       - Format?
#           - Host?
#           - Hostname?
#           - User@Hostname?
#       - Parse with perl, awk, grep

# export PATH=/bin:/usr/bin

declare FREE_USER=kolkhis
declare DESTINATION=192.168.4.11

declare INPUT
read -r -n 2 -t 20 -p "Welcome!
Select one of the following:

1. Connect to DestinationHost
2. Exit

> " INPUT

if [[ -n $INPUT ]]; then
    case $INPUT in
        1)
            printf "Going to DestinationHost.\n"
            ssh "${FREE_USER}@${DESTINATION}"
            exit 0
            ;;
        2)
            printf "Leaving now.\n"
            exit 0
            ;;
        [^0-9])
            printf "You can only enter numbers.\n"
            exit 1
            ;;
        *)
            printf "Unknown input. Goodbye.\n"
            exit 1
            ;;
    esac
fi

exit 0



