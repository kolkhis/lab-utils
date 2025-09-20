# Topics for ProLUG Bash Study Group
- [x] Writing your first bash script
    - Check OS of current machine?
    - Check network connection?
    - Done in [./first-script]

- [x] Conditionals
    - Main rant 
        - exit codes
        - `true`/`false`
        - C
        - `./examples/hello.c`
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
    * Challenge: Write a script that takes one argument (via `read` or `$1`) and utilizes 
      conditionals (`if`/`else`, `case`) to perform different actions based on the value.  
        * Bonus points: Use conditional operators to print error messages if commands fail (hint: `||`).  
        * For instance, maybe a script that prints something out in a certain color based on the argument.

    - Done in [./conditionals]

- [x] Getting user input
    - `read`
    - CLI args (`$@`, `$*`, `$1`...)
    - Argument parsing
        - `while [[ -n $1 ]]` or `[[ -n $1 && $1 =~ ^- ]]`
        - `getopts`?

- Reading from a file

- [x] Redirection
    - Pipelines (`|`)
    - Redirecting to/from Files (`> file`, `< file`)
        - Process substitution?
    - File Descriptors (`stdin` [0], `stdout` [1], `stderr` [2])
        - Duplicating file descriptors (`2>&1`)
            - Outputting to file descriptors (`>&2`)
        - Closing/silencing file descriptors (`2>&-`)
        - Redirecting for the whole file using `exec` (`exec 2>error.log`)
    - Order of redirection
        - Attach file descriptors after redirecting.  
        - Accidental truncating (`sed 's/old/new/' file > file`) 
        - `man://bash`, type `/order of redirections`
    - FIFOs/Named Pipes (`mkfifo`) (save for another time?)
    - Challenge: Write an install script that takes a list of programs from a file.  
        - Bonus points: Add error handling that directs error messages to a 
          logfile.  


- [x] Regex / Pattern Matching (Partially done)
    - `=~`
        - Sets `[...]`
            - Negated sets `[^...]`
        - Character classes
            - Perl/Vim classes
            - POSIX classes
        - Capture groups
        - Quantifiers
    - Pattern Matching (`==`)
        - Sets
        - Character classes
    - `"${BASH_REMATCH[0]}"`: Whole match
    - `"${BASH_REMATCH[1]}"`: Capture group(s)
    - `[[ $var == *.md ]]`: Pattern matching


- [ ] Content transformations
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
    - `cut`

- [x] Parameter expansions
    - ```bash
      "${VAR//old/new}"
      "${VAR##prefix}"
      "${VAR%%suffix}"
      ```
    - Parameter tranformations
      ```bash
      "${VAR,,}"
      "${VAR@L}" # same thing
      "${VAR^^}"
      "${VAR@U}" # same thing
      ```

- [ ] Using arrays 
    - `${ARR[@]}`
    - `${ARR[*]}`
    - `${ARR[0]}`
    - POSIX doesn't have arrays.

    - [ ] Associative arrays?
      ```bash
      declare -A DICT
      DICT=(
          [KeyOne]='ValueOne'
          [KeyTwo]='ValueTwo'
      )
      ```

- [x] Process Substitution
    - `<(cmd)`
    - Pretend to be a file

- [ ] Command Grouping 
    - `{ ... }` / `( ... )`
    - Sharing output

- [ ] Error handling
    - `trap`

- [ ] Debugging
    - `set -x`
    - `printf` / `echo`

- [ ] Backgrounding processes
    - Combining with FIFOs?

- [ ] Bash Programmable Completion
    - `complete -A command <smth>`

- Cron? Less "bash" and more "linux in general"
    - Cron daily runs at 3:14 AM every morning on a linux system.  

- [ ] Terminal configuration and customization (e.g., ricing)



- [ ] PiHole install review
    - <https://github.com/pi-hole/pi-hole/blob/master/automated%20install/basic-install.sh>


## Script Ideas

- [x] File extension sorter
    - Take a directory, move files into subdirectories based on file extension
    - Done in [./examples/extension-sorter](./examples/extension-sorter)

- System info reporter

- File renamer 
    - Use regex to bulk rename files 



