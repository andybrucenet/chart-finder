#!/bin/bash
# sample-reusable.sh
# Demonstrates the reusable script pattern (main function + source-only guard).

# resolve directories
the_sample_reusable_source="${BASH_SOURCE[0]}"
while [ -h "$the_sample_reusable_source" ]; do
  the_sample_reusable_dir="$( cd -P "$( dirname "$the_sample_reusable_source" )" >/dev/null 2>&1 && pwd )"
  the_sample_reusable_source="$(readlink "$the_sample_reusable_source")"
  [[ $the_sample_reusable_source != /* ]] && the_sample_reusable_source="$the_sample_reusable_dir/$the_sample_reusable_source"
done
the_sample_reusable_script_dir="$( cd -P "$( dirname "$the_sample_reusable_source" )" >/dev/null 2>&1 && pwd )"
the_sample_reusable_root_dir="$( realpath "$the_sample_reusable_script_dir"/.. )"
#
# normally we load in environment
source "$the_sample_reusable_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

# rules:
# * never use tabs - always use 2 spaces for indent
# * global variables use "the_[script-name]_[var-function]"
# * global functions use "[script-name]_[function-name]"
# * always have a "[script-name]_main" which optionally executes with parameters
# * within functions:
#   * all variables defined with "local"
#   * input variables use "i_" prefix
#   * local variables use "l_" prefix
# * always end the script with a 'source-only' check and ensure that true is returned

# usage is helpful for any reusable script
sample_reusable_usage() {
  cat <<'USAGE'
Usage: ./scripts/sample-reusable.sh [command] [args]

Commands:
  status                 Print the detected repo root
  echo <message>         Echo the provided message
USAGE
}

# common logging is helpful
sample_reusable_log() {
  local i_message="$1"
  printf '[sample] %s\n' "$i_message"
}

sample_reusable_cmd_status() {
  sample_reusable_log "repo root: $the_sample_reusable_root_dir"
}

sample_reusable_cmd_echo() {
  local i_message="$1"
  if [ -z "$i_message" ]; then
    sample_reusable_log "ERROR: missing message for echo command"
    return 1
  fi
  sample_reusable_log "$i_message"
}

sample_reusable_main() {
  local l_cmd="${1:-}"
  shift $(( $# > 0 ? 1 : 0 ))

  case "$l_cmd" in
    status|'')
      sample_reusable_cmd_status
      ;;
    echo)
      sample_reusable_cmd_echo "$1"
      ;;
    --help|-h|help)
      sample_reusable_usage
      ;;
    *)
      sample_reusable_log "ERROR: unknown command '$l_cmd'"
      sample_reusable_usage
      return 1
      ;;
  esac
}

if [ "${1:-}" != "source-only" ]; then
  sample_reusable_main "$@"
else
  # no error
  true
fi
