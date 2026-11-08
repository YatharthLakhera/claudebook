#!/usr/bin/env bash
# claudebook security review launcher (PostToolUse, asyncRewake).
# Exit 0 = nothing to report. Exit 2 = findings on stderr (wakes the session).
[ -n "${CLAUDEBOOK_SECURITY_REVIEW:-}" ] && exit 0   # never recurse from reviewer runs
PY=$(command -v python3 || true)
[ -z "$PY" ] && exit 0
exec "$PY" -I "$(dirname "$0")/security_review.py" "$@"
