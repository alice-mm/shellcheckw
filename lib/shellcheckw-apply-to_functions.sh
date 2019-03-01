#! /usr/bin/env bash

#####
# Alice M.
# www.alicem.net
# github.com/alice-mm/shellcheckw
#####


# Any file standing below a directory
# bearing one of these names will be ignored.
unset -v IGNORED_DIRS
declare -r IGNORED_DIRS=(
    .git
    node_modules
)

# If the basename of a file is one of those,
# the file will not be checked.
unset -v IGNORED_FILES
declare -A IGNORED_FILES
for name in mvnw gradlew
do
    IGNORED_FILES[$name]=1
done


# $1    Path to a file.
# Exits with 0 status iff the given file looks like a shell script.
#
# This checks file type first, and then looks for a shebang just in case.
# The extension can also be trusted, even if it's kinda dumb. At least this
# will recognized as shell scripts the files that only contain function
# definitions and tend to lack a shebang.
function is_shell_script {
    : ${1:?No path given.}
    
    file --brief "$1" | grep -q 'sh script' ||
    grep -q '^#!.*sh\b' "$1" ||
    grep -q '\.[^.]*sh$' <<< "$1"
}


# Find files from the given starting points.
# Ignore items specified via IGNORED_DIRS and IGNORED_FILES.
#
# $@    Starting points for “find”.
# stdout → null-separated list of normal, nonignored files.
function list_all_files_from {
    local one_ignored_dir
    local one_ignored_file
    local find_args
    local first=1
    local need_parentheses
    
    find_args+=(
        # Starting from...
        "$@"
        # Find “normal” files.
        -type f
    )
    
    # Ignore files by basename.
    for one_ignored_file in "${!IGNORED_FILES[@]}"
    do
        find_args+=(
            -not -name "$one_ignored_file"
        )
    done
    
    find_args+=(
        # This will be closed right after the “-print0”.
        '('
    )
    
    # Prune ignored directories.
    if [ ${#IGNORED_DIRS[@]} -gt 1 ]
    then
        # Need parentheses around the ignored paths list!
        need_parentheses=1
        find_args+=( '(' )
    fi
    
    for one_ignored_dir in "${IGNORED_DIRS[@]}"
    do
        if [ "$first" ]
        then
            unset -v first
        else
            find_args+=( -o )
        fi
        
        find_args+=(
            -path "*/${one_ignored_dir}/*"
        )
    done
    
    if [ "$need_parentheses" ]
    then
        find_args+=( ')' )
    fi
    
    find_args+=(
        # Dismiss ignored directories; print if not ignored!
        -prune -o -print0
        ')'
    )
    
    find "${find_args[@]}"
}
