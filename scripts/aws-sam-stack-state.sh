#!/bin/bash
# aws-sam-stack-state.sh ABr
#
# Show the state of the current (last) AWS stack

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_aws_sam_stack_state_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_aws_sam_stack_state_root_dir="$( realpath "$the_aws_sam_stack_state_script_dir"/.. )"
source "$the_aws_sam_stack_state_root_dir"/scripts/lcl-os-checks.sh 'source-only' || exit $?
lcl_dot_local_settings_source "$the_aws_sam_stack_state_root_dir" || exit $?

the_aws_sam_stack_state_args=(
  aws cloudformation describe-stacks
  --stack-name "$CF_LOCAL_ENV_ID"
  --no-cli-pager
)

exec "$the_aws_sam_stack_state_root_dir/scripts/cf-run-cmd.sh" "${the_aws_sam_stack_state_args[@]}" |
  jq '.Stacks[0]'
