#! /usr/bin/env bash

#####
# Alice M.
# www.alicem.net
# github.com/alice-mm/shellcheckw
#####

set -e

SCRDIR=$(readlink -f -- "$(dirname "$0")")
readonly SCRDIR

cd "$SCRDIR"

./shellcheckw_tests.sh
./shellcheckw-apply-to_tests.sh


# All done!

set +e

printf '%s: OK.\n' "$(basename "$0")"

exit 0
