#!/bin/bash

# arrays
printf "Let's declare an array with 'declare -a'.\n"
declare -a MY_ARR

printf "Let's get some stuff into it.\n"

# defining array
MY_ARR=('one' 'two' 'three')

# accessing elements
printf "The first element: %s\n" "${MY_ARR[0]}"
printf "The second element: %s\n" "${MY_ARR[1]}"

# loop over array
printf "Let's just loop over it.\n"
for THING in "${MY_ARR[@]}"; do
    printf "Element: %s\n" "$THING"
done

printf "printf also works nicely with arrays: %s\n" "${MY_ARR[@]}"

# What about the default array?
printf 'The default array holds all arguments given to the script: $@\n'
printf "Let's loop over the cli args.\n"
for arg in "${@}"; do
    printf "Argument: %s\n" "$arg"
done


# Let's use a process substitution to read some filenames into an array
declare -a FILENAMES
IFS=$'\n' read -r -d '' -a FILENAMES < <(find . -name '*.md')
printf "File: %s\n" "${FILENAMES[@]}"




