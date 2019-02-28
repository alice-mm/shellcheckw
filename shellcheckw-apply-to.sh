#! /usr/bin/env bash

#####
# Alice M.
# www.alicem.net
# github.com/alice-mm/shellcheckw
#####


unset -v GIT
declare -r GIT=(git)


# Names of constants that hold necessary programs.
unset -v DEPS
declare -r DEPS=(
    GIT
)

unset -v must_exit
for constname in "${DEPS[@]}"
do
    if ! type "${!constname}" &> /dev/null
    then
        printf '%s: The command %q mentioned by the configuration constant %q was not found. Please install this program or change the configuration of %q.\n' \
                "$(basename "$0")" "${!constname}" "$constname" "$(basename "$0")" >&2
        must_exit=1
    fi
done

if [ "$must_exit" ]
then
    exit 3
fi


function print_help {
    cat << _HELP_

  Usage:

    $(printf '%q' "$(basename "$0")") REVISION_A REVISION_B [path/to/project/]
    $(printf '%q' "$(basename "$0")") -p PATH...
    $(printf '%q' "$(basename "$0")") -h

  The first form checks scripts that were modified between the two given
  Git revisions (commits, branches...). You can explicitly give the path
  to a Git project so that the script will move to it before checking
  anything.
  
  The second form checks scripts found by searching recursively from the
  given paths. The paths can lead to nondirectory files themselves,
  in which case these files will be checked.

  The “-h” option prints this help message and exits.

_HELP_
}


SCRDIR=$(readlink -f -- "$(dirname "$0")")
readonly SCRDIR

# shellcheck source=shellcheckw-apply-to_functions.sh
. "$SCRDIR"/shellcheckw-apply-to_functions.sh || exit


unset -v CHECK_PATHS_MODE

OPTIND=1
while getopts 'hp' opt
do
    case "$opt" in
        h)
            print_help
            exit 0
            ;;
        
        p)
            declare -r CHECK_PATHS_MODE=1
            ;;
    esac
done
shift $((OPTIND - 1))


if [ $# -eq 0 ] || [ $# -lt 2 -a ! "$CHECK_PATHS_MODE" ]
then
    print_help
    exit 1
fi


if [ ! "$CHECK_PATHS_MODE" ] && [ "$3" ]
then
    # Move to project.
    cd "$3" ||
    exit
fi

if [ ! "$CHECK_PATHS_MODE" ]
then
    # Move to the root of the project so that paths make sense.
    cd "$("${GIT[@]}" rev-parse --show-toplevel)" ||
    exit
    
    printf '%s: Project: %q\n' "$(basename "$0")" "$(pwd)"
fi


unset -v ok_files not_ok_files
ok_files=()
not_ok_files=()

if [ "$CHECK_PATHS_MODE" ]
then
    # Empty, means “null byte” for “read”.
    sep_between_paths=''
else
    # Newline, just like the default value. Suits git diff output.
    sep_between_paths=$'\n'
fi

while read -rd "$sep_between_paths" path
do
    if [ ! "$CHECK_PATHS_MODE" ] && grep -qx '".*"' <<< "$path"
    then
        # Weird Git way to escape stuff! Need to process to get a usable path.
        # NB: Names like
        #   $'a \t b \n c'
        # are given as
        #   "a \t b \n c"
        # (Including the quotes.)
        # So printf's %b looks like the way to go to handle many weird cases.
        # We still have to replace \" with " ourselves, though.
        path=$(
            printf '%b' "$(
                sed '
                    s/^"//
                    s/"$//
                    s/\\"/"/g
                ' <<< "$path"
            )"
        )
    fi
    
    if [ ! -r "$path" ] || ! is_shell_script "$path"
    then
        # Skip!
        continue
    fi
    
    if "$SCRDIR"/shellcheckw "$path"
    then
        ok_files+=("$path")
    else
        not_ok_files+=("$path")
    fi
done < <(
    if [ "$CHECK_PATHS_MODE" ]
    then
        list_all_files_from "$@"
    else
        if ! "${GIT[@]}" diff --name-only "$1" "$2"
        then
            printf '%s: Git error. Check your arguments.\n' "$(basename "$0")" >&2
        fi
    fi
)

ok_list=$(
    if [ ${#ok_files[@]} -gt 0 ]
    then
        printf '%q\n' "${ok_files[@]}"
    fi
)

not_ok_list=$(
    if [ ${#not_ok_files[@]} -gt 0 ]
    then
        printf '%q\n' "${not_ok_files[@]}"
    fi
)

cat << _REPORT_


  === Final report ===

  Passed: $(printf '%4d' ${#ok_files[@]})
${ok_list}

  Failed: $(printf '%4d' ${#not_ok_files[@]})
${not_ok_list}

_REPORT_

# Final status:
test ${#not_ok_files[@]} -eq 0
