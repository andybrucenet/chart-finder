#!/bin/bash
# aws-run-cmd.sh ABr
#
# Invoke a command with local AWS variables exported

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_aws_run_cmd_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_aws_run_cmd_root_dir="$( realpath "$the_aws_run_cmd_script_dir"/.. )"

# source environment
if [ -s "$the_aws_run_cmd_root_dir/.local/local.env" ] ; then
  source "$the_aws_run_cmd_root_dir/.local/local.env" 'source-only' || exit $?
fi
#set | grep -e '^AWS_'

if [ "$1" = "--eval" ]; then
  shift
  cmd="$*"
  if [ -z "$cmd" ]; then
    echo "aws-run-cmd.sh: missing command for --eval" >&2
    exit 1
  fi
  exec "${SHELL:-/bin/bash}" -lc "$cmd"
fi

# run cmd
exec "$@"
