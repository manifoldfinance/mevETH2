#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset
STDOUT_CAPTURE=$(mktemp)
_exit() {{
    EXIT_CODE=$?
    if [ "${{STDOUT_OUTPUT_FILE:-}}" ]; then
        cp -f "$STDOUT_CAPTURE" "$STDOUT_OUTPUT_FILE"
    fi
    if [ "$EXIT_CODE" != 0 ]; then
        cat "$STDOUT_CAPTURE"
    fi
    rm "$STDOUT_CAPTURE"
    exit $EXIT_CODE
}}
trap _exit EXIT
if [ "${{STDOUT_OUTPUT_FILE:-}}" ]; then
    STDOUT_OUTPUT_FILE="$PWD/$STDOUT_OUTPUT_FILE"
fi
{} $@ >>"$STDOUT_CAPTURE"    