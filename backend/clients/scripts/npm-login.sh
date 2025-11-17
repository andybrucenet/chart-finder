#!/bin/bash
# npm-login.sh, ABr
# Verify npm authentication; prompt user to login if needed.

set -euo pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function npm_login_main() {
  local i_mode="${1:-run}"
  if [ "$i_mode" = "source-only" ]; then
    return 0
  fi

  if npm whoami >/dev/null 2>&1; then
    echo "[npm-login] Already authenticated as $(npm whoami)"
  else
    echo "[npm-login] No active npm session. Run 'npm login' for the public registry." >&2
    npm login
  fi
}

npm_login_main "$@"
