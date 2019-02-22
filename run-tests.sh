#! /usr/bin/env bash

set -e

declare -r SCRDIR=$(readlink -f -- "$(dirname "$0")")

cd "$SCRDIR"

./shellcheckw_tests.sh
./shellcheckw-apply-to_tests.sh


# All done!

set +e

printf '%s: OK.\n' "$(basename "$0")"

exit 0
