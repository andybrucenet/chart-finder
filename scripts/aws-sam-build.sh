#!/bin/bash
# aws-sam-build.sh ABr
#
# Build the ChartFinder SAM application with standard options.

set -euo pipefail

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_aws_sam_build_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_aws_sam_build_root_dir="$( realpath "$the_aws_sam_build_script_dir"/.. )"

the_template_path="$the_aws_sam_build_root_dir/.local/infra/aws/serverless.template"
the_build_dir="$the_aws_sam_build_root_dir/.aws-sam/build"

if ! command -v sam >/dev/null 2>&1 ; then
  echo "ERROR: sam CLI is not installed or not on PATH." >&2
  exit 1
fi

# run the build
echo 'AWS SAM BUILD...'
"$the_aws_sam_build_root_dir/scripts/aws-run-cmd.sh" sam build \
  --template-file "$the_template_path" \
  --build-dir "$the_build_dir" \
  --build-in-source \
  --cached \
  --parallel \
  "$@"
echo ''

# run the validate
echo 'AWS SAM VALIDATE...'
"$the_aws_sam_build_root_dir/scripts/aws-run-cmd.sh" sam validate \
  --template-file "$the_build_dir"/template.yaml \
  --config-env dev \
  --lint
