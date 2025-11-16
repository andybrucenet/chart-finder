#!/bin/bash
# cf-env-vars.sh, ABr
#
# Set / display a specific ChartFinder environment var.
# Called by itself - loads all CF variables including .local/local.env vars
# Called with a parameter - prints those derived variable names.

##############################################################
# options
CF_ENV_VARS_OPTION_REBUILD_ALL="${CF_ENV_VARS_OPTION_REBUILD_ALL:-0}"
CF_ENV_VARS_OPTION_REBUILD_BACKEND="${CF_ENV_VARS_OPTION_REBUILD_BACKEND:-0}"
CF_ENV_VARS_OPTION_REBUILD_FRONTEND="${CF_ENV_VARS_OPTION_REBUILD_FRONTEND:-0}"
#
# implied vars
if [ x"$CF_ENV_VARS_OPTION_REBUILD_ALL" = x1 ] ; then
  CF_ENV_VARS_OPTION_REBUILD_BACKEND=1
  CF_ENV_VARS_OPTION_REBUILD_FRONTEND=1
fi

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_cf_env_vars_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_cf_env_vars_root_dir="$( realpath "$the_cf_env_vars_script_dir"/.. )"
source "$the_cf_env_vars_root_dir/scripts/lcl-os-checks.sh" 'source-only' || exit $?
lcl_dot_local_settings_source "$the_cf_env_vars_root_dir" || exit $?

##############################################################
# vars
#
# name of Directory.Build.props and local cache to hold extracted values
the_cf_env_vars_msbuild_props_name='Directory.Build.props'
the_cf_env_vars_msbuild_props_src_path="$the_cf_env_vars_root_dir/$the_cf_env_vars_msbuild_props_name"
the_cf_env_vars_msbuild_props_dst_path="$the_cf_env_vars_root_dir/$g_DOT_LOCAL_DIR_NAME/$the_cf_env_vars_msbuild_props_name"
the_cf_env_vars_msbuild_props_cached="$the_cf_env_vars_root_dir/$g_DOT_LOCAL_DIR_NAME/state/msbuild-props.sh"
#
# name of frontend/version.json and local cache to hold extracted values
the_cf_env_vars_frontend_version_src_fname='version.json'
the_cf_env_vars_frontend_version_src_path="$the_cf_env_vars_root_dir/frontend/$the_cf_env_vars_frontend_version_src_fname"
the_cf_env_vars_frontend_version_dst_path="$the_cf_env_vars_root_dir/$g_DOT_LOCAL_DIR_NAME/state/frontend-version.sh"

##############################################################
# functions
#
# load json property from frontend/version.json (slow)
function cf_env_vars_frontend_version_prop_read {
  local prop="$1"
  cat "$the_cf_env_vars_frontend_version_src_path" | jq -r ".$prop"
}
#
# load from cached Directory.Build.props (slow)
function cf_env_vars_msbuild_prop_read {
  local prop="$1"
  python3 - <<'PY' "$prop" "$the_cf_env_vars_msbuild_props_dst_path"
import sys
from xml.etree import ElementTree as ET

prop_name, path = sys.argv[1:]
tree = ET.parse(path)

for elem in tree.getroot().iter():
  if elem.tag.endswith(prop_name):
    value = (elem.text or '').strip()
    if value:
      print(value)
      sys.exit(0)

sys.exit(1)
PY
}
#
# does msbuild props require cache?
function cf_env_vars_msbuild_props_is_cached {
  if [ ! -s "$the_cf_env_vars_msbuild_props_dst_path" ] ; then
    # Directory.Build.props missing
    return 1
  fi
  if [ ! -s "$the_cf_env_vars_msbuild_props_cached" ] ; then
    # derived env vars missing
    return 1
  fi
  if [ "$the_cf_env_vars_msbuild_props_src_path" -nt "$the_cf_env_vars_msbuild_props_dst_path" ] ; then
    # not cached (change in source)
    return 1
  fi
  if [ "$the_cf_env_vars_msbuild_props_src_path" -nt "$the_cf_env_vars_msbuild_props_cached" ] ; then
    # not cached (source newer than derived env vars)
    return 1
  fi

  # cached
  return 0
}
#
# auto-cache msbuild props
function cf_env_vars_msbuild_props_auto_cache {
  if cf_env_vars_msbuild_props_is_cached ; then
    # no cache necessary
    return 0
  fi

  # copy to cached file (stop on failure)
  /bin/cp "$the_cf_env_vars_msbuild_props_src_path" "$the_cf_env_vars_msbuild_props_dst_path" || return $?

  # load everything to cache
  local l_CF_BACKEND_VERSION_FULL="`cf_env_vars_msbuild_prop_read ChartFinderVersion | dos2unix`"
  local l_CF_BACKEND_VERSION_MAJOR="`echo "$l_CF_BACKEND_VERSION_FULL" | awk -F'.' '{print $1}'`"
  local l_CF_BACKEND_VERSION_MINOR="`echo "$l_CF_BACKEND_VERSION_FULL" | awk -F'.' '{print $2}'`"
  local l_CF_BACKEND_VERSION_RELEASE="`echo "$l_CF_BACKEND_VERSION_FULL" | awk -F'.' '{print $3}'`"
  local l_CF_BACKEND_VERSION_GLOBAL_RELEASE="`echo "$l_CF_BACKEND_VERSION_FULL" | awk -F'.' '{print $4}'`"
  cat >"$the_cf_env_vars_msbuild_props_cached" <<EOF
#!/bin/bash
# auto-cached $the_cf_env_vars_msbuild_props_name
#
# hold auto-synchronized env vars extracted from msbuild properties for backend.
# note: all variables can be overridden from command line
#
# globals
[ x"\$CF_GLOBAL_COMPANY" = x ] && export CF_GLOBAL_COMPANY="`cf_env_vars_msbuild_prop_read Company | dos2unix`"
[ x"\$CF_GLOBAL_PRODUCT" = x ] && export CF_GLOBAL_PRODUCT="`cf_env_vars_msbuild_prop_read Product | dos2unix`"
#
# backend version
[ x"\$CF_BACKEND_VERSION_FULL" = x ] && export CF_BACKEND_VERSION_FULL="$l_CF_BACKEND_VERSION_FULL"
[ x"\$CF_BACKEND_VERSION_MAJOR" = x ] && export CF_BACKEND_VERSION_MAJOR="$l_CF_BACKEND_VERSION_MAJOR"
[ x"\$CF_BACKEND_VERSION_MINOR" = x ] && export CF_BACKEND_VERSION_MINOR="$l_CF_BACKEND_VERSION_MINOR"
[ x"\$CF_BACKEND_VERSION_RELEASE" = x ] && export CF_BACKEND_VERSION_RELEASE="$l_CF_BACKEND_VERSION_RELEASE"
[ x"\$CF_BACKEND_VERSION_GLOBAL_RELEASE" = x ] && export CF_BACKEND_VERSION_GLOBAL_RELEASE="$l_CF_BACKEND_VERSION_GLOBAL_RELEASE"
[ x"\$CF_BACKEND_VERSION_FULL_NUMERIC" = x ] && export CF_BACKEND_VERSION_FULL_NUMERIC="$l_CF_BACKEND_VERSION_MAJOR$l_CF_BACKEND_VERSION_MINOR$l_CF_BACKEND_VERSION_RELEASE$l_CF_BACKEND_VERSION_GLOBAL_RELEASE"
[ x"\$CF_BACKEND_VERSION_SHORT" = x ] && export CF_BACKEND_VERSION_SHORT="$l_CF_BACKEND_VERSION_MAJOR.$l_CF_BACKEND_VERSION_MINOR.$l_CF_BACKEND_VERSION_RELEASE"
[ x"\$CF_BACKEND_VERSION_SHORT_NUMERIC" = x ] && export CF_BACKEND_VERSION_SHORT_NUMERIC="$l_CF_BACKEND_VERSION_MAJOR$l_CF_BACKEND_VERSION_MINOR$l_CF_BACKEND_VERSION_RELEASE"
[ x"\$CF_BACKEND_BUILD_NUMBER" = x ] && export CF_BACKEND_BUILD_NUMBER="`cf_env_vars_msbuild_prop_read ChartFinderBackendBuildNumber | dos2unix`"
#
# indicate no error
true
EOF
  chmod +x "$the_cf_env_vars_msbuild_props_cached" || return $?
  return 0
}
#
# does front version props require cache?
function cf_env_vars_frontend_version_is_cached {
  if [ ! -s "$the_cf_env_vars_frontend_version_dst_path" ] ; then
    # cache file missing
    return 1
  fi
  if [ "$the_cf_env_vars_frontend_version_src_path" -nt "$the_cf_env_vars_frontend_version_dst_path" ] ; then
    # not cached (change in source)
    return 1
  fi

  # cached
  return 0
}
#
# auto-cache msbuild props
function cf_env_vars_frontend_version_auto_cache {
  if cf_env_vars_frontend_version_is_cached ; then
    # no cache necessary
    return 0
  fi

  # load everything to cache
  local l_CF_FRONTEND_VERSION_FULL="`cf_env_vars_frontend_version_prop_read version | dos2unix`"
  local l_CF_FRONTEND_VERSION_MAJOR="`echo "$l_CF_FRONTEND_VERSION_FULL" | awk -F'.' '{print $1}'`"
  local l_CF_FRONTEND_VERSION_MINOR="`echo "$l_CF_FRONTEND_VERSION_FULL" | awk -F'.' '{print $2}'`"
  local l_CF_FRONTEND_VERSION_RELEASE="`echo "$l_CF_FRONTEND_VERSION_FULL" | awk -F'.' '{print $3}'`"
  local l_CF_FRONTEND_VERSION_GLOBAL_RELEASE="`echo "$l_CF_FRONTEND_VERSION_FULL" | awk -F'.' '{print $4}'`"
  cat >"$the_cf_env_vars_frontend_version_dst_path" <<EOF
#!/bin/bash
# auto-cached $the_cf_env_vars_frontend_version_src_path
#
# hold auto-synchronized env vars extracted from msbuild properties for frontend.
# note: all variables can be overridden from command line

# frontend version
[ x"\$CF_FRONTEND_VERSION_FULL" = x ] && export CF_FRONTEND_VERSION_FULL="$l_CF_FRONTEND_VERSION_FULL"
[ x"\$CF_FRONTEND_VERSION_MAJOR" = x ] && export CF_FRONTEND_VERSION_MAJOR="$l_CF_FRONTEND_VERSION_MAJOR"
[ x"\$CF_FRONTEND_VERSION_MINOR" = x ] && export CF_FRONTEND_VERSION_MINOR="$l_CF_FRONTEND_VERSION_MINOR"
[ x"\$CF_FRONTEND_VERSION_RELEASE" = x ] && export CF_FRONTEND_VERSION_RELEASE="$l_CF_FRONTEND_VERSION_RELEASE"
[ x"\$CF_FRONTEND_VERSION_GLOBAL_RELEASE" = x ] && export CF_FRONTEND_VERSION_GLOBAL_RELEASE="$l_CF_FRONTEND_VERSION_GLOBAL_RELEASE"
[ x"\$CF_FRONTEND_VERSION_FULL_NUMERIC" = x ] && export CF_FRONTEND_VERSION_FULL_NUMERIC="$l_CF_FRONTEND_VERSION_MAJOR$l_CF_FRONTEND_VERSION_MINOR$l_CF_FRONTEND_VERSION_RELEASE$l_CF_FRONTEND_VERSION_GLOBAL_RELEASE"
[ x"\$CF_FRONTEND_VERSION_SHORT" = x ] && export CF_FRONTEND_VERSION_SHORT="$l_CF_FRONTEND_VERSION_MAJOR.$l_CF_FRONTEND_VERSION_MINOR.$l_CF_FRONTEND_VERSION_RELEASE"
[ x"\$CF_FRONTEND_VERSION_SHORT_NUMERIC" = x ] && export CF_FRONTEND_VERSION_SHORT_NUMERIC="$l_CF_FRONTEND_VERSION_MAJOR$l_CF_FRONTEND_VERSION_MINOR$l_CF_FRONTEND_VERSION_RELEASE"
[ x"\$CF_FRONTEND_BUILD_NUMBER" = x ] && export CF_FRONTEND_BUILD_NUMBER="`cf_env_vars_frontend_version_prop_read buildNumber | dos2unix`"
[ x"\$CF_FRONTEND_BUILD_COMMENT" = x ] && export CF_FRONTEND_BUILD_COMMENT="`cf_env_vars_frontend_version_prop_read comment | dos2unix`"
[ x"\$CF_FRONTEND_BUILD_BRANCH" = x ] && export CF_FRONTEND_BUILD_BRANCH="`cf_env_vars_frontend_version_prop_read branch | dos2unix`"
[ x"\$CF_FRONTEND_INFORMATIONAL_VERSION" = x ] && export CF_FRONTEND_INFORMATIONAL_VERSION="`cf_env_vars_frontend_version_prop_read informationalVersion | dos2unix`"
#
# indicate no error
true
EOF
  chmod +x "$the_cf_env_vars_frontend_version_dst_path" || return $?
  return 0
}

# handle msbuild cache
[ x"$CF_ENV_VARS_OPTION_REBUILD_BACKEND" = x1 ] && rm -f "$the_cf_env_vars_msbuild_props_dst_path"
cf_env_vars_msbuild_props_auto_cache || exit $?
source "$the_cf_env_vars_msbuild_props_cached" || exit $?

# handle msbuild cache
[ x"$CF_ENV_VARS_OPTION_REBUILD_FRONTEND" = x1 ] && rm -f "$the_cf_env_vars_frontend_version_dst_path"
cf_env_vars_frontend_version_auto_cache || exit $?
source "$the_cf_env_vars_frontend_version_dst_path" || exit $?

# git branch is *always* dynamic (and we may need to separate from "last compiled git branch")
[ x"\$CF_GLOBAL_BRANCH" = x ] && export CF_GLOBAL_BRANCH="`lcl_git_branch`"

# show any variables?
the_cf_env_vars_just_export=1
if [ x"$1" != x ] ; then
  if [ x"$1" != x'source-only' ] ; then
    the_cf_env_vars_just_export=0
  fi
fi
if [ $the_cf_env_vars_just_export -eq 1 ] ; then
  # no error
  true
else
  # echo all desired vars
  for the_cf_env_vars_i in "$@" ; do
    echo "${!the_cf_env_vars_i}"
  done
fi
