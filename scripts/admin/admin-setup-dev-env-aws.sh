#!/bin/bash
# admin-setup-dev-env-aws.sh, ABr
#
# AWS Admin script to run against a provided ".local" folder. Creates per-dev
# infrastructure (artifact bucket, IAM policy/role) using hydrated config.

##############################################################
# the single argument is required
ADMIN_SETUP_DEV_ENV_AWS_OPTION_LOCAL_DIR="${1:-}"

##############################################################
# locate script source directory and source OS tools
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
THE_ADMIN_SETUP_DEV_ENV_AWS_SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
THE_ADMIN_SETUP_DEV_ENV_AWS_ROOT_DIR="$( realpath "$THE_ADMIN_SETUP_DEV_ENV_AWS_SCRIPT_DIR"/../.. )"
source "$THE_ADMIN_SETUP_DEV_ENV_AWS_ROOT_DIR"/scripts/lcl-os-checks.sh 'source-only' || exit $?

##############################################################
# tmp is problematic on cygwin
THE_ADMIN_SETUP_DEV_ENV_AWS_TMP_DIR="$(lcl_os_tmp_dir)"
THE_ADMIN_SETUP_DEV_ENV_AWS_TMP_PREFIX='admin-setup-dev-env-aws-'
THE_ADMIN_SETUP_DEV_ENV_AWS_RUN_DIR=$(mktemp -d "${THE_ADMIN_SETUP_DEV_ENV_AWS_TMP_DIR}/${THE_ADMIN_SETUP_DEV_ENV_AWS_TMP_PREFIX}run-XXXX")
if [ ! -d "$THE_ADMIN_SETUP_DEV_ENV_AWS_RUN_DIR" ]; then
  echo 'ERROR: FAILED_TO_CREATE_TMP_DIR' >&2
  exit 1
fi

cleanup_tmp_files() {
  rm -rf "$THE_ADMIN_SETUP_DEV_ENV_AWS_RUN_DIR" 2>/dev/null || true
}

trap cleanup_tmp_files EXIT

make_tmp_file() {
  local suffix="$1"
  local tmp_file
  tmp_file=$(mktemp "${THE_ADMIN_SETUP_DEV_ENV_AWS_RUN_DIR}/${suffix}-XXXX.json")
  local rc=$?
  if [ $rc -ne 0 ] || [ ! -f "$tmp_file" ]; then
    echo "ERROR: FAILED_TO_CREATE_TMP_FILE suffix=$suffix" >&2
    exit ${rc:-1}
  fi
  printf '%s' "$tmp_file"
}

##############################################################
# helper functions
require_tool() {
  local tool="$1"
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: MISSING_REQUIRED_TOOL $tool" >&2; exit 1; }
}

assert_var_set() {
  local var_name="$1"
  if [ -z "${!var_name:-}" ]; then
    echo "ERROR: REQUIRED_VAR_NOT_SET $var_name" >&2
    exit 1
  fi
}

run_cmd() {
  echo "+ $*"
  "$@"
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "ERROR: COMMAND_FAILED rc=$rc cmd='$*'" >&2
    exit $rc
  fi
}

##############################################################
# program start

echo '**AWS: ONE TIME ADMIN SETUP...'
echo ''

[ -n "$ADMIN_SETUP_DEV_ENV_AWS_OPTION_LOCAL_DIR" ] || { echo 'ERROR: LOCAL_DIR_REQUIRED' >&2; exit 1; }
[ -d "$ADMIN_SETUP_DEV_ENV_AWS_OPTION_LOCAL_DIR" ] || { echo "ERROR: INVALID_DIR:'$ADMIN_SETUP_DEV_ENV_AWS_OPTION_LOCAL_DIR'" >&2; exit 1; }

LOCAL_ENV_PATH="$ADMIN_SETUP_DEV_ENV_AWS_OPTION_LOCAL_DIR/local.env"
[ -s "$LOCAL_ENV_PATH" ] || { echo "ERROR: MISSING_LOCAL_ENV:'$LOCAL_ENV_PATH'" >&2; exit 1; }

source "$LOCAL_ENV_PATH" 'source-only' || { echo 'ERROR: FAILED_TO_SOURCE_LOCAL_ENV' >&2; exit 1; }

REQUIRED_VARS=(CF_LOCAL_ENV_ID CF_LOCAL_AWS_REGION CF_LOCAL_AWS_ACCOUNT_ID CF_LOCAL_AWS_ARTIFACT_BUCKET CF_LOCAL_USEREMAIL)
for var in "${REQUIRED_VARS[@]}"; do
  assert_var_set "$var"
done

require_tool aws

LOCAL_INFRA_AWS_DIR="$ADMIN_SETUP_DEV_ENV_AWS_OPTION_LOCAL_DIR/infra/aws"
if [ ! -d "$LOCAL_INFRA_AWS_DIR" ]; then
  echo "ERROR: MISSING_LOCAL_INFRA:'$LOCAL_INFRA_AWS_DIR'" >&2
  exit 1
fi
POLICY_DOC_PATH="$LOCAL_INFRA_AWS_DIR/iam/policies/codebuild-exec-permissions.json"
TRUST_DOC_PATH="$LOCAL_INFRA_AWS_DIR/iam/roles/codebuild-exec-trust.json"

[ -s "$POLICY_DOC_PATH" ] || { echo "ERROR: MISSING_POLICY_DOC:'$POLICY_DOC_PATH'" >&2; exit 1; }
[ -s "$TRUST_DOC_PATH" ] || { echo "ERROR: MISSING_TRUST_DOC:'$TRUST_DOC_PATH'" >&2; exit 1; }

echo "  CONFIG_DIR='$ADMIN_SETUP_DEV_ENV_AWS_OPTION_LOCAL_DIR'"
echo "  CF_LOCAL_ENV_ID='$CF_LOCAL_ENV_ID'"
echo "  CF_LOCAL_AWS_REGION='$CF_LOCAL_AWS_REGION'"
echo "  CF_LOCAL_AWS_ACCOUNT_ID='$CF_LOCAL_AWS_ACCOUNT_ID'"
echo "  CF_LOCAL_AWS_ARTIFACT_BUCKET='$CF_LOCAL_AWS_ARTIFACT_BUCKET'"
echo "  CF_LOCAL_USEREMAIL='$CF_LOCAL_USEREMAIL'"
echo ''

echo 'CONFIRM CALLER...'
run_cmd aws sts get-caller-identity
CALLER_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
CALLER_RC=$?
if [ $CALLER_RC -ne 0 ]; then
  echo "ERROR: FAILED_TO_DETECT_ACCOUNT rc=$CALLER_RC" >&2
  exit $CALLER_RC
fi
if [ "$CALLER_ACCOUNT" != "$CF_LOCAL_AWS_ACCOUNT_ID" ]; then
  echo "ERROR: ACCOUNT_MISMATCH caller=$CALLER_ACCOUNT expected=$CF_LOCAL_AWS_ACCOUNT_ID" >&2
  exit 1
fi
echo ''

PROJECT_TAG_VALUE='ChartFinder'
ENVIRONMENT_TAG_VALUE="$CF_LOCAL_ENV_ID"
OWNER_TAG_VALUE="$CF_LOCAL_USEREMAIL"

# ensure artifact bucket exists
ARTIFACT_BUCKET="$CF_LOCAL_AWS_ARTIFACT_BUCKET"
ARTIFACT_BUCKET_REGION="$CF_LOCAL_AWS_REGION"

echo "ARTIFACT BUCKET..."
if aws s3api head-bucket --bucket "$ARTIFACT_BUCKET" >/dev/null 2>&1; then
  echo "  EXISTS: s3://$ARTIFACT_BUCKET"
else
  echo "  CREATE: s3://$ARTIFACT_BUCKET"
  if [ "$ARTIFACT_BUCKET_REGION" = "us-east-1" ]; then
    run_cmd aws s3api create-bucket --bucket "$ARTIFACT_BUCKET"
  else
    run_cmd aws s3api create-bucket --bucket "$ARTIFACT_BUCKET" --create-bucket-configuration LocationConstraint="$ARTIFACT_BUCKET_REGION"
  fi
fi

run_cmd aws s3api put-bucket-versioning --bucket "$ARTIFACT_BUCKET" --versioning-configuration Status=Enabled

BUCKET_ENCRYPTION_FILE="$(make_tmp_file 'bucket-encryption')"
cat >"$BUCKET_ENCRYPTION_FILE" <<EOF
{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}
EOF
run_cmd aws s3api put-bucket-encryption --bucket "$ARTIFACT_BUCKET" --server-side-encryption-configuration file://"$BUCKET_ENCRYPTION_FILE"

BUCKET_TAGS_FILE="$(make_tmp_file 'bucket-tags')"
cat >"$BUCKET_TAGS_FILE" <<EOF
{
  "TagSet": [
    { "Key": "Project", "Value": "$PROJECT_TAG_VALUE" },
    { "Key": "Environment", "Value": "$ENVIRONMENT_TAG_VALUE" },
    { "Key": "Owner", "Value": "$OWNER_TAG_VALUE" }
  ]
}
EOF
run_cmd aws s3api put-bucket-tagging --bucket "$ARTIFACT_BUCKET" --tagging file://"$BUCKET_TAGS_FILE"
echo ''

# IAM policy management
POLICY_NAME="${CF_LOCAL_ENV_ID}-codebuild-exec-policy"
POLICY_ARN="arn:aws:iam::${CF_LOCAL_AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

echo "IAM POLICY ($POLICY_NAME)..."
if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  echo '  UPDATE POLICY VERSION'
  run_cmd aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document file://"$POLICY_DOC_PATH" --set-as-default
  STALE_VERSIONS=$(aws iam list-policy-versions --policy-arn "$POLICY_ARN" --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text)
  STALE_RC=$?
  if [ $STALE_RC -ne 0 ]; then
    echo "ERROR: FAILED_TO_LIST_POLICY_VERSIONS rc=$STALE_RC" >&2
    exit $STALE_RC
  fi
  if [ "$STALE_VERSIONS" = "None" ]; then
    STALE_VERSIONS=""
  fi
  read -r -a POLICY_VERSION_LIST <<<"$STALE_VERSIONS"
  while [ "${#POLICY_VERSION_LIST[@]}" -gt 4 ]; do
    VERSION_TO_DELETE="${POLICY_VERSION_LIST[0]}"
    echo "  DELETE POLICY VERSION $VERSION_TO_DELETE"
    run_cmd aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$VERSION_TO_DELETE"
    POLICY_VERSION_LIST=("${POLICY_VERSION_LIST[@]:1}")
  done
else
  echo '  CREATE POLICY'
  run_cmd aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file://"$POLICY_DOC_PATH" \
    --tags Key=Project,Value="$PROJECT_TAG_VALUE" Key=Environment,Value="$ENVIRONMENT_TAG_VALUE" Key=Owner,Value="$OWNER_TAG_VALUE"
fi
echo ''

# IAM role management
ROLE_NAME="${CF_LOCAL_ENV_ID}-codebuild-exec-role"
ROLE_ARN="arn:aws:iam::${CF_LOCAL_AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

echo "IAM ROLE ($ROLE_NAME)..."
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo '  UPDATE TRUST POLICY'
  run_cmd aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document file://"$TRUST_DOC_PATH"
  echo '  TAG ROLE'
  run_cmd aws iam tag-role --role-name "$ROLE_NAME" --tags Key=Project,Value="$PROJECT_TAG_VALUE" Key=Environment,Value="$ENVIRONMENT_TAG_VALUE" Key=Owner,Value="$OWNER_TAG_VALUE"
else
  echo '  CREATE ROLE'
  run_cmd aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://"$TRUST_DOC_PATH" \
    --tags Key=Project,Value="$PROJECT_TAG_VALUE" Key=Environment,Value="$ENVIRONMENT_TAG_VALUE" Key=Owner,Value="$OWNER_TAG_VALUE"
fi

ATTACHED=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[?PolicyArn==`'"$POLICY_ARN"'`].PolicyArn' --output text)
ATTACHED_RC=$?
if [ $ATTACHED_RC -ne 0 ]; then
  echo "ERROR: FAILED_TO_LIST_ATTACHED_POLICIES rc=$ATTACHED_RC" >&2
  exit $ATTACHED_RC
fi
if [ "$ATTACHED" = "None" ]; then
  ATTACHED=""
fi
if [ -z "$ATTACHED" ]; then
  echo '  ATTACH POLICY'
  run_cmd aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
else
  echo '  POLICY ALREADY ATTACHED'
fi
echo ''

echo 'SUMMARY'
echo "  Artifact bucket: s3://$ARTIFACT_BUCKET"
echo "  IAM policy: $POLICY_ARN"
echo "  IAM role:   $ROLE_ARN"

# cleanup handled by trap
