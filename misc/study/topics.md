- Writing your first bash script
    - Check OS of current machine?
    - Check network connection?

- Conditionals
    - Main rant 
        - exit codes
        - `true`/`false`
        - C
        - `./hello.c`
    - `if`/`elif`/`else`
    - `case`
    - Side rant (POSIX)?
        - `[[ ... ]]` vs `[ ... ]`
        - `==` vs `=`
          ```sh
          # POSIX
          [ $var = 'hello' ] # literal match
          [ $var = *.md ]    # at least it supports pattern matching
          ```

- Getting user input
    - `read`
    - CLI args (`$@`, `$*`, `$1`...)
    - `getopts`?

- Redirection
    - Files
    - File Descriptors (`stdin` [0], `stdout` [1], `stderr` [2])
    - FIFOs/Named Pipes (`mkfifo`)

- Regex / Pattern Matching
    - `=~`
    - `"${BASH_REMATCH[0]}"`: Whole match
    - `"${BASH_REMATCH[1]}"`: Capture group(s)
    - `[[ $var == *.md ]]`: Pattern matching


- Content transformations
    - After/with regex
    - `sed`
        - `-i` / `-i.bak`
        - `-E`
        - Multiple expressions `-e`
    - `awk`
        - `BEGIN`
        - `/pattern/ { print $0 }`
    - `perl`
        - Smaller runtime footprint than `sed` and `awk`
        - `-i` / `-i.bak`
        - `s/old/new/`
        - `tr/a-z/A-Z/`
    - `tr`

- Parameter expansions
    - ```bash
      "${VAR//old/new}"
      "${VAR##prefix}"
      "${VAR%%suffix}"
      ```
    - Parameter tranformations
      ```bash
      "${VAR,,}"
      "${VAR@L}" # same thing (POSIX-compliant?)
      "${VAR^^}"
      "${VAR@U}" # same thing (POSIX-compliant?)
      ```

- Using arrays 
    - `${ARR[@]}`
    - `${ARR[*]}`
    - `${ARR[0]}`
    - POSIX doesn't have arrays.

- Associative arrays?
    - ```bash
      declare -A DICT
      DICT=(
          [KeyOne]='ValueOne'
          [KeyTwo]='ValueTwo'
      )
      ```

- Process Substitution
    - `<(cmd)`
    - Pretend to be a file

- Command Grouping 
    - `{ ... }` / `( ... )`
    - Sharing output

- Error handling
    - `trap`

- Debugging
    - `set -x`
    - `printf` / `echo`

- Backgrounding processes
    - Combining with FIFOs?

- Bash Programmable Completion
    - `complete -A command <smth>`

