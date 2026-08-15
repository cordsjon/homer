#!/bin/bash
# start-homer.sh — resolve homer's port from portmgr, then serve dist/.
#
# A plist's ProgramArguments is a static array (launchd does no shell
# expansion), so the port cannot be substituted there. Fetching it at start
# time has to happen in a wrapper like this one.
#
# portmgr (http://127.0.0.1:9000) is the single source of truth for port
# assignments across the workspace — never hardcode a port here. The fallback
# below exists only so a portmgr outage degrades to "homer still serves on its
# last known port" instead of "homer is down"; it is not a second source of
# truth.
set -euo pipefail

cd /Users/jcords-macmini/projects-local/homer

PORTMGR_URL="${PORTMGR_URL:-http://127.0.0.1:9000}"
FALLBACK_PORT=9102

PORT=$(curl -s --max-time 5 "${PORTMGR_URL}/allocations" 2>/dev/null \
  | python3 -c 'import sys, json; print(json.load(sys.stdin)["allocations"]["homer"])' 2>/dev/null) || PORT=""

if [ -z "$PORT" ]; then
  echo "start-homer: portmgr unreachable or has no 'homer' allocation — falling back to ${FALLBACK_PORT}" >&2
  PORT="$FALLBACK_PORT"
else
  echo "start-homer: portmgr allocated port ${PORT}" >&2
fi

exec /opt/homebrew/bin/npx http-server dist -p "$PORT" -c-1
