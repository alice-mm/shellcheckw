#! /usr/bin/env bash

#####
# Alice M.
# www.alicem.net
# github.com/alice-mm/shellcheckw
#####

declare -r DEFAULT_SHEBANG='#! /usr/bin/env bash'


# $1    Shell script.
# Exits with 0 status iff the script has a shebang.
function has_shebang {
    : ${1:?No script.}
    
    grep -q '^#!.*\w' "$1"
}

# $1    Shell script.
# stdout → Edited version of the script to avoid false positives, etc.
function preprocess_script {
    : ${1:?No script.}
    
    if ! has_shebang "$1"
    then
        # Add default shebang to enable ShellCheck to say stuff.
        printf '%s\n\n' "$DEFAULT_SHEBANG"
    fi
    
    sed -r '
        # Avoid confusion between Unicode quotation marks
        # and ASCII ones.
        
        s/[“”‘’]/QUOTES/g
        
        
        # Hide (by commenting them out) lines with just
        # a no-op used for expansions:
        #
        #   : ${foo:?plop} "${bar:=patate}" ${gus:?}
        #       ↓
        #   #: ${foo:?plop} "${bar:=patate}" ${gus:?}
        
        s/^\s*(:|true|false)(\s+("?)\$\{\w+:[=?][^}]*\}\3)+\s*$/#&/
    ' "$1"
}
