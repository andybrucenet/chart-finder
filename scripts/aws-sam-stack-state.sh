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
source "$the_aws_sam_stack_state_root_dir"/.local/local.env 'source-only' || exit $?

exec "$the_aws_sam_stack_state_root_dir/scripts/aws-run-cmd.sh" \
  aws cloudformation list-stacks --no-cli-pager |
    jq '.StackSummaries
        | map(select(.StackName == "'"$CF_LOCAL_ENV_ID"'"))
        | sort_by((.LastUpdatedTime // .CreationTime))
        | reverse
        | .[0]'

