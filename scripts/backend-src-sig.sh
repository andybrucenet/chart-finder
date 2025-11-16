#!/bin/bash
# backend-src-sig.sh
# Compute backend source signature and auto-bump build number when it changes.

# locate script source directory
the_backend_src_sig_source="${BASH_SOURCE[0]}"
while [ -h "$the_backend_src_sig_source" ]; do
  the_backend_src_sig_dir="$( cd -P "$( dirname "$the_backend_src_sig_source" )" >/dev/null 2>&1 && pwd )"
  the_backend_src_sig_source="$(readlink "$the_backend_src_sig_source")"
  [[ $the_backend_src_sig_source != /* ]] && the_backend_src_sig_source="$the_backend_src_sig_dir/$the_backend_src_sig_source"
done
the_backend_src_sig_script_dir="$( cd -P "$( dirname "$the_backend_src_sig_source" )" >/dev/null 2>&1 && pwd )"
the_backend_src_sig_root_dir="$( realpath "$the_backend_src_sig_script_dir"/.. )"
source "$the_backend_src_sig_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_backend_src_sig_root_dir" || exit $?
#
# also source in all the local build version settings - we need them for 'sam deploy'
source "$the_backend_src_sig_root_dir/scripts/cf-env-vars.sh" 'source-only' || exit $?

# get state directory
state_dir="$the_backend_src_sig_root_dir/$g_DOT_LOCAL_DIR_NAME/state"
[ ! -d "$state_dir" ] && mkdir -p "$state_dir"
[ ! -d "$state_dir" ] && echo "MISSING_DIR: $state_dir" && exit 2

# get the signature
sig_cur=$(find "$the_backend_src_sig_root_dir/src/backend" "$the_backend_src_sig_root_dir/src/common" \
  -type f \( -name '*.cs' -o -name '*appsettings*.json' \) \
  ! -path '*/bin/*' ! -path '*/obj/*' \
  -exec ls -la {} \; | sort | shasum -a 256 | awk '{print $1}')
echo "Backend Src Signature (CURRENT) : $sig_cur"

# get prev value
sig_file="$state_dir/backend-source.sig"
sig_prev=''
[ -s "$sig_file" ] && sig_prev="`cat "$sig_file"`"
echo "Backend Src Signature (PREVIOUS): $sig_prev"

# identical?
if [ x"$sig_cur" = x"$sig_prev" ] ; then
  echo '  IDENTICAL'
  exit 0
fi

# update
default_build_number="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "  UPDATE: BUILD_NUMBER ($default_build_number)..."
CHARTFINDER_BACKEND_BUILD_NUMBER="$default_build_number" "$the_backend_src_sig_root_dir/scripts/update-version.sh" backend-batch || exit $?
echo '  UPDATE: SIGNATURE...'
echo "$sig_cur" >"$sig_file" || exit $?
echo '  OK'
