#!/bin/bash
# aws-sam-preflight.sh, ABr
#
# Run a local SAM build + validate cycle to catch template issues before deploy.

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_aws_sam_preflight_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_aws_sam_preflight_root_dir="$( realpath "$the_aws_sam_preflight_script_dir"/.. )"
source "$the_aws_sam_preflight_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_aws_sam_preflight_root_dir" || exit $?

the_template_path="$the_aws_sam_preflight_root_dir/.local/infra/aws/serverless.template"
the_build_dir="$the_aws_sam_preflight_root_dir/.aws-sam/build"

if ! command -v sam >/dev/null 2>&1 ; then
  echo "ERROR: sam CLI is not installed or not on PATH." >&2
  exit 1
fi

# ensure SAM commands run from repo root so build artifacts stay under <repo>/.aws-sam
the_prev_dir="$(pwd)"
cd "$the_aws_sam_preflight_root_dir" >/dev/null 2>&1 || {
  echo "ERROR: unable to change directory to '$the_aws_sam_preflight_root_dir'" >&2
  exit 1
}
trap 'cd "$the_prev_dir" >/dev/null 2>&1' EXIT

echo 'AWS SAM PREFLIGHT BUILD (updates all SAM files locally prior to deploy)...'
echo ''

# update configs
echo 'SYNC CONFIGS...'
"$the_aws_sam_preflight_root_dir/scripts/sync-configs.sh" || exit $?
echo ''


# run the build
echo 'AWS SAM BUILD...'
set -x
"$the_aws_sam_preflight_root_dir/scripts/aws-run-cmd.sh" sam build \
  --template-file "$the_template_path" \
  --build-dir "$the_build_dir" \
  --build-in-source \
  --cached \
  --parallel \
  "$@" || exit $?
set +x
echo ''

# run the validate
echo 'AWS SAM VALIDATE...'
set -x
"$the_aws_sam_preflight_root_dir/scripts/aws-run-cmd.sh" sam validate \
  --template-file "$the_build_dir"/template.yaml \
  --config-env "$CF_LOCAL_BILLING_ENV" \
  --lint || exit $?
set +x
echo ''

echo 'AWS SAM PREFLIGHT SUCCESSFUL - You may now deploy the SAM stack.'
