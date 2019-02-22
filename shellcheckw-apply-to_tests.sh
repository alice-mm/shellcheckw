#! /usr/bin/env bash

declare -r SCRDIR=$(readlink -f -- "$(dirname "$0")")
declare -r TMPD=$(mktemp -d "${TMPDIR:-/tmp}"/shellcheckw-apply-to_test-XXXXX)

. "$SCRDIR"/shellcheckw-apply-to_functions.sh


set -evx


# list_all_files_from

(
    # Mock “find”.
    function find {
        printf '%q\n' "$@"
    }
    
    test "$(list_all_files_from 'foo' 'bar')" = "$(
        cat << '_EXPECTED_OUT_'
foo
bar
-type
f
-not
-name
mvnw
-not
-name
gradlew
\(
\(
-path
\*/.git/\*
-o
-path
\*/node_modules/\*
\)
-prune
-o
-print0
\)
_EXPECTED_OUT_
    )"
) # Dismiss “find” mock.


# is_shell_script

# Empty with script extensions.
# Should be true.
for filename in foo.{sh,bash,ksh,fish,zsh,csh}
do
    path=${TMPD}/${filename}
    > "$path"
    is_shell_script "$path"
done

# Empty with random extensions.
# Should be false.
for filename in foo foo.{pdf,java,class,osef,plop,c,TXT}
do
    path=${TMPD}/${filename}
    > "$path"
    is_shell_script "$path" && false
done


# All done!

set +evx

printf '%s: OK.\n' "$(basename "$0")"

exit 0
