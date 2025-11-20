#!/bin/bash
# cf-run-cmd.sh ABr
#
# Invoke a command with local ChartFinder variables exported

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_cf_run_cmd_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_cf_run_cmd_root_dir="$( realpath "$the_cf_run_cmd_script_dir"/.. )"
source "$the_cf_run_cmd_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?
#set | grep -e '^CF_'

if [ "$1" = "--eval" ]; then
  shift
  cmd="$*"
  if [ -z "$cmd" ]; then
    echo "cf-run-cmd.sh: missing command for --eval" >&2
    exit 1
  fi
  exec "${SHELL:-/bin/bash}" -lc "$cmd"
fi

# run cmd
exec "$@"
