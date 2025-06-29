#!/bin/bash
# shellcheck disable=SC2154,SC2016























printf "Parameter Expansion.\n"




























































printf "Parameter expansion is a feature of bash.\n"
printf "That means it's not technically POSIX-compliant.\n"

printf "It's a way to modify values in-place.\n"

printf "What does that mean?"
printf "When you're using that variable, you can modify it without an extra line.\n"















































































printf "The syntax is as follows:\n"

${variable<operator><args>}

printf "You must call the variable with braces { } -- parameter expansion is not available otherwise.\n"

printf "There are a few operators that are available, each with their own functionality.\n"













































printf "Let's look at an example.\n"

    declare name="connor"

printf "Let's make the first letter uppercase.\n"

    printf "Name: %s\n" "${name^}"
    # output: Connor

printf "The ^ makes the first letter uppercase.\n"
printf "This is a bashism.\n"

printf "Other shells will use the syntax:\n"

    printf "Name: %s\n" "${name@u}"
    # output: Connor

printf "We can also make the entire string uppercase if we want.\n"

    printf "Name: %s\n" "${name^^}"
    # output: CONNOR

printf "Or we can use the <operator><argument> syntax:\n"

    printf "Name: %s\n" "${name@U}"
    # output: CONNOR






























































# Extension -- specifying a pattern
printf "We can also specify a pattern for letters to capitalize.\n"

    declare name="connor"
    printf "%s\n" "${name^[cn]}"
    # Output:
    # Connor

printf "Here, the ^ is non-greedy.\n"
printf "It will only captilize the first match it finds of the pattern.\n"
printf "We can make it greedy by using the ^^ operator.\n"

    printf "%s\n" "${name^^[cn]}"
    # Output:
    # CoNNor

printf "Notice we're using a set [...] here.\n"
printf "Bash expects a pattern here (e.g., pattern matching), we can can use character classes too.\n"

    printf "%s\n" "${name^^[[:alpha:]]}"
    printf "%s\n" "${name^^[a-zA-Z_]}"
    # Output:
    # CONNOR

printf "That one just matches any alphabet character, same as [a-zA-Z].\n"

# POSIX character classes:
# alnum alpha ascii blank cntrl digit graph lower print punct space  upper word xdigit

printf "There's also a , operator to do something similar to the ^ operator.\n"
printf "The only difference is that it makes the variable lowercase instead of uppercase.\n"

printf "The same rules apply. You apparently can NOT use patterns for this one.\n"

printf "The syntax:\n"

    declare name="CONNOR"
    printf "%s\n" "${name,}"
    printf "%s\n" "${name,,}"           
    printf "%s\n" "${name,,[A-Z]}"     
    printf "%s\n" "${name,,[[:alpha:]]}"  # Works as intended
































printf "So that's one way to use parameter expansion.\n"
printf "We can use parameter expansions in a lot of other ways too.\n"

printf "For example, if we want to perform a substitution on a string without using 'sed' or 'perl'\n"

    declare my_string="remove the word word"

    printf "%s\n" "${my_string/word/}"
    # Output: remove the word

printf "This removes the first occurrence of the word 'word'\n"
printf "If we wanted to remove *all* of the occurrences of 'word', we would do this:\n"

    printf "%s\n" "${my_string//word/}"
    # Output: remove the

printf "This is extremely useful and can save you an external call to sed or perl.\n"
















































printf "Another way to use parameter expansions is to trim suffixes and prefixes.\n"

printf "Say we have an absolute path to a file, but we want to strip out the path for just the filename.\n"

    declare my_file="/home/kolkhis/notes/mkdocs.yml"
    printf "%s\n" "${my_file##*/}"
    # Output: mkdocs.yml

printf "As you can see, this uses a *pattern* (or *glob*) to match characters.\n"

printf "The ## is the operator for stripping prefixes.\n"
printf "Like the last one, we can use a single # to match only the first occurence.\n"

    declare my_file="/home/kolkhis/notes/mkdocs.yml"
    printf "%s\n" "${my_file#/*/}"
    # Output: kolkhis/notes/mkdocs.yml

printf "This has many other uses than just for filenames.\n"

printf "If we just wanted the file extension:\n"

    declare my_file="/home/kolkhis/notes/mkdocs.yml"
    printf "%s\n" "${my_file##*.}"
    # Output: yml

printf "Now we know what type of file it is.\n"





























































printf "Similarly, we can use the % operator to strip out suffixes.\n" ""

    declare my_file="/home/kolkhis/notes/mkdocs.yml"
    printf "%s\n" "${my_file%.yml}"
    # Output: /home/kolkhis/notes/mkdocs

printf "We could also use it to strip out the filename to see the directory structure.\n"

    declare my_file="/home/kolkhis/notes/mkdocs.yml"
    printf "%s\n" "${my_file%/*}"
    # Output: /home/kolkhis/notes

printf "This can be good for validating that a file is where it should be.\n"


























































# Default values
printf "We can also use parameter expansion to set default values for variables.\n"
printf "I personally use this one *a lot*.\n"

printf "Let's create an empty variable.\n"

    declare my_var
    printf "%s\n" "${my_var}"

printf "Let's use a default value for it.\n"

    printf "%s\n" "${my_var:-Hello world}"
    # Output: Hello world
    printf "%s\n" "${my_var}"
    # Output: 

printf "This will use the default value that was given for that printf call.\n"
printf "However, the variable will remain empty.\n"

printf "We can use another operator to both use *and* assign the variable a default value.\n"

    printf "%s\n" "${my_var:=Hello world}"
    # Output: Hello world
    printf "%s\n" "${my_var}"
    # Output: Hello world


















































# Default values (cont)
printf "We can also use the :+ operator if we want to use an alternate value if a variable IS set.\n"

    declare my_var=
    printf "%s\n" "${my_var}"
    # Output: 

    printf "%s\n" "${my_var:+Hello! }"
    # Output:

    declare my_var="Hi"
    printf "%s\n" "${my_var}"
    # Output: 
    # Hi

    printf "%s\n" "${my_var:+Hello! }"
    # Output:
    # Hello! 


printf "So, this only uses the alternate value if the variable IS set and NOT null.\n"


































# Length
printf "We can use a 'type' of parameter expansion to get the length of a variable.\n"

printf "You may have seen this one before.\n"

    declare a_string="Hello, world!"
    printf "Length of a_string: %s\n" "${#a_string}"
    # Output: Length of a_string: 13

printf "This can also be used to get the number of elements in an array.\n"

    declare -a my_arr=( "one" "two" "three" )
    printf "Number of elements: %s\n" "${#my_arr[@]}"
    # Output: Number of elements: 3


printf "A common use case:\n"

    declare -a my_arr=( "one" "two" "three" )
    for i in ${#my_arr[@]}; do
        printf "Index: %s\nElement: %s\n" "${i}" "${my_arr["$i"]}"
    done


























































printf "Parameter expansions can also be performed on every element in an array.\n"
printf "Let's look at the same one:\n"

    declare -a my_arr=("one" "two" "three")
    printf "%s\n" "${my_arr[@]^}"
    printf "%s\n" "${my_arr[@]@u}"
    printf "%s\n" "${my_arr[@]@U}"

    printf "%s\n" "one" "two" "three" # same thing
    # Output:
    #   One
    #   Two
    #   Three

printf "Since [@] expands the array into all its separate elements, the expansion will be performed on each one.\n"

printf "If we wanted to combine the array into a single string and capitalize the first letter:\n"

    declare -a my_arr=("one" "two" "three")
    printf "%s\n" "${my_arr[*]^}"
    # Output:
    #   One two three
    printf "%s\n" "${my_arr[*]@u}"

printf "This can be done with *any* array and *any* parameter expansion.\n"






































































# Overview of operators

printf "--------------- Parameter Transformations ---------------\n"
cat <<- 'EOC'

Parameter Transformation Operators (on single variables) 
${var@U} - Convert everythings to uppercase.
${var^^} - Convert everythings to uppercase.
${var@u} - Capitalizes the first character.
${var^} - Capitalizes the first character.
${var@L} - Converts everything to lowercase.
${var,,} - Convert everythings to lowercase.
${var,} - Converts first character to lowercase.
${var@Q} - Quotes the value, making it safe to reuse as input.
${var@E} - Expands escape sequences (like $'...' syntax).
${var@P} - Expand as a prompt string (PS1).
${var@A} - Returns an assignment statement to recreate the variable with its attributes.
${var@K} - Produces a quoted version of the value, displaying arrays as key-value pairs.
${var@a} - Returns the variable's attribute flags (like readonly, exported).

Using transformations on arrays:
${@^} - Converts the first character of each parameter to uppercase.
${*^} - Converts the first character of the combined string to uppercase
${@^^} - Converts all characters to uppercase, as separate items
${*^^} - Converts all characters to uppercase as one string
${@,} - Lowercases the first character of each parameter
${*,} - Lowercases only the first character of the combined string
Using the letters (requires the @):
${@@Q} - Quotes each parameter individually
${*@Q} - Quotes the entire combined string
${@@A} - Returns an assignment statement to recreate the array.
${*@A} - Returns an assignment statement to recreate the string.

Arrays tl;dr: 
    $@ / ${@} applies to each individually
    $* / ${*} combines and applies to the combined string.
[@] and [*] will only use values in dictionaries. Use ${!arr[@|*]} to use keys.

EOC


declare arg
{ 
    [[ -z $1 ]] && printf "No arguments found for examples. Exiting.\n" && exit 0; 
} || {
    : "${arg:=$1}"
}


printf -- "--------------- First Argument ---------------\n"
printf '${arg@L} - lowercase: %s\n' "${arg@L}"
printf '${arg@Q} - quoted: %s\n' "${arg@Q}"
printf '${arg@K} - quoted, key/value: %s\n' "${arg@K}"
printf '${arg@a} - attributes: %s\n' "${arg@a}"
printf '${arg@u} - TitleCase: %s\n' "${arg@u}"
printf '${arg@U} - Uppercase: %s\n' "${arg@U}"
printf -- "------------- Array of Arguments -------------\n"
printf '${@^} - Capitalize each parameter: %s\n' "${@^}"
printf '${*^} - Capitalize only the first letter of the combined string: %s\n' "${*^}"
printf '${@^^} - Uppercase each parameter completely: %s\n' "${@^^}"
printf '${*^^} - Uppercase the entire combined string: %s\n' "${*^^}"
printf '${@,} - Lowercase the first character of each parameter: %s\n' "${@,}"
printf '${*,} - Lowercase only the first character of the combined string: %s\n' "${*,}"
printf '${@,,} - Lowercase all characters of each parameter: %s\n' "${@,}"
printf '${*,,} - Lowercase all characters of the combined string: %s\n' "${*,}"
printf '${@@Q} - Quote each parameter individually: %s\n' "${@@Q}"
printf '${*@Q} - Quote the entire combined string: %s\n' "${*@Q}"
printf '${*@Q} - Quote the entire combined string: %s\n' "${*@Q}"
printf '${@@A} - Return an array that contains statements to recreate each variable: %s\n' "${@@A}"
printf '${*@A} - Return an assignment statement to recreate the variables: %s\n' "${*@A}"




























































# Talk about ${!arr[@]} (array keys)
printf 'We can use the ${!var[@]} or ${!var[*]} syntax to get the list the keys of an array.\n'

declare -a my_arr=("one" "two" "three")

for n in "${!my_arr[@]}"; do
    printf "Index: %s\n" "$n"
    printf "Value: %s\n" "${my_arr[$n]}"
done


printf "This one prints the keys of the array.\n"

    printf "%s\n" "${!my_arr[@]}"
    # Output: 
    # 0
    # 1
    # 2

printf "The keys of a regular array will just be the indices.\n"
printf "The keys of an associative array will be the keys.\n"


declare -A ass_arr=( [one]="Hello" [two]="World" [three]="Hi again" )

    printf "%s\n" "${!ass_arr[@]}"
    # Output:
    # two
    # three
    # one

printf "Bash doesn't maintain the order of the elements in associative arrays.\n"


























# Getting Variable Names
printf "You can also use parameter expansion to get a list of variable names that match a pattern.\n"

printf "For example:\n"

    declare some_var="Hello, world"
    declare some_other_var="Goodbye, world"

    printf "%s\n" "${!some@}"
    # Output:
    # some_other_var
    # some_var

    printf "%s\n" "${!some*}"
    # Output:
    # some_other_var some_var

printf "The result is either an array (with @) or a single string (with *).\n"


cat << 'EOF'
This syntax expands to a list of variable names that begin with the 'prefix' that we specify.
If * is used (e.g., `"${!some*}"`)
    The result is a single string, with names joined by the first character of $IFS (often a space).
If @ is used (e.g., `"${!some@}"`):
    The result is each name as a separate word — meaning if quoted ("${!prefix@}"), each name is its own item.
EOF

printf "This could be useful to clean up variables.\n"

    declare var_one=1; declare var_two=2; declare var_three=3
    printf "%s\n" "${var_one}"; printf "%s\n" "${var_two}"; printf "%s\n" "${var_three}"
    # Output:
    # 1
    # 2
    # 3

    unset "${!var_@}" # Unsets all 3 of those variabes
    printf "%s\n" "${var_one}"; printf "%s\n" "${var_two}"; printf "%s\n" "${var_three}"
    # Output:
    #

printf 'This ${!...} syntax behaves differently when used with arrays (as we just saw).\n'












































# Erroring 
printf "We can also use parameter expansion to set errors in case values are missing.\n"

printf "For example, say we need a 'NAMESPACE' variable to be set for a script to work.\n"
printf "We want to exit the script with an error if that variable is *not* set.\n"

    declare NAMESPACE=
    "${NAMESPACE:?The NAMESPACE variable is either not set or null}"
    # Will trigger error (value is null, but it is set)

printf "This will check NAMESPACE, and check if it is either not *set* or it is *null*.\n"


printf "If it's either null or unset, the error will trigger and the message will be output.\n"
printf "Now, we can also only check if the variable is unset and allow null values.\n"

    declare NAMESPACE=
    "${NAMESPACE?The NAMESPACE variable is not set!}"
    # Will NOT trigger error (value is null, but it is set)

printf "We just removed the colon (:) from :? \n"
printf "This will only error out if the variable doesn't exist.\n"

printf "This colon rule also works with :-, :=, and :+  \n"





























































# Slicing

printf "Like other programming languages, Bash supports string slicing.\n" 
printf "We can use parameter expansion for slicing (substring expansion).\n"
printf 'We use the ${var:offset:length} syntax.\n'

    declare my_var="Hello, world!"
    printf "%s\n" "${my_var:0:5}"
    # Output:
    # Hello

printf "This slices the first 5 characters out of the variable.\n"
printf "We start at offset (index) zero, and the length we want is 5.\n"
















































cat << EOF
CHALLENGE

If anyone wants a challenge this week:
Write a script that will take a file as an argument and display info about the file using parameter expansions. That means no calls out to `sed`, `perl`, `awk`, `basename`, etc.
File info should include:
- Full filename  
- File extension  
- Filename without the extension  
- File location  
- Parent directory name (not full path)  
EOF









