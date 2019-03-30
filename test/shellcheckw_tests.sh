#! /usr/bin/env bash

#####
# Alice M.
# www.alicem.net
# github.com/alice-mm/shellcheckw
#####

SCRDIR=$(readlink -f -- "$(dirname "$0")")
readonly SCRDIR
TMPF=$(mktemp "${TMPDIR:-/tmp}"/shellcheckw_test-XXXXX)
readonly TMPF

# shellcheck source=../lib/shellcheckw_functions.sh
. "$SCRDIR"/../lib/shellcheckw_functions.sh


set -evx


# has_shebang

has_shebang <(
    cat << '_SH_'

plop
plup
#! ok
plap

_SH_
)

has_shebang <(
    cat << '_SH_'
plup
#!
_SH_
) && false

has_shebang <(
    cat << '_SH_'
plup
#! /bin/bash
_SH_
)

has_shebang <(
    cat << '_SH_'
plup
 #! /bin/bash
_SH_
) && false

has_shebang <(
    cat << '_SH_'
plup
plop #! /bin/bash
_SH_
) && false


# preprocess_script


> "$TMPF"
test "$(preprocess_script "$TMPF")" = "$(
    cat << '_SH_'
#! /usr/bin/env bash

_SH_
)"

cat > "$TMPF" << '_SH_'
plop
plup
_SH_
test "$(preprocess_script "$TMPF")" = "$(
    cat << '_SH_'
#! /usr/bin/env bash

plop
plup
_SH_
)"

cat > "$TMPF" << '_SH_'
#! /usr/bin/env bash
plop
plup
_SH_
test "$(preprocess_script "$TMPF")" = "$(
    cat << '_SH_'
#! /usr/bin/env bash
plop
plup
_SH_
)"

cat > "$TMPF" << '_SH_'
#! /usr/bin/env bash


plop

plup
_SH_
test "$(preprocess_script "$TMPF")" = "$(
    cat << '_SH_'
#! /usr/bin/env bash


plop

plup
_SH_
)"

# With Unicode quotation marks.
# Should replace them with text.
cat > "$TMPF" << '_SH_'
#! foo
foo “bar” plop ”_“ poulou bla‘’bla
_SH_
test "$(preprocess_script "$TMPF")" = "$(
    cat << '_SH_'
#! foo
foo QUOTESbarQUOTES plop QUOTES_QUOTES poulou blaQUOTESQUOTESbla
_SH_
)"


# All done!

set +evx

printf '%s: OK.\n' "$(basename "$0")"

exit 0
