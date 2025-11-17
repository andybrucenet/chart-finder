#!/bin/bash
# cond-copy.sh, ABr
# Conditionally copy source to dest

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_cond_copy_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
the_cond_copy_root_dir="$( realpath "$the_cond_copy_script_dir"/../../.. )"
source "$the_cond_copy_root_dir"/scripts/cf-env-vars.sh 'source-only' || exit $?

# do the copy
the_src="$1"
the_dst="$2"

# validate
[ ! -s "$the_src" ] && echo "MISSING_SRC '$the_src'" && exit 2

# create dst dir
the_dst_dir="`dirname "$the_dst"`"
[ ! -d "$the_dst_dir" ] && mkdir -p "$the_dst_dir"
[ ! -d "$the_dst_dir" ] && "INVALID_DST_DIR '$the_dst_dir'" && exit 2

# if not exists - straight copy
if [ ! -s "$the_dst" ] ; then
  /bin/cp "$the_src" "$the_dst"
else
  # if newer - overwrite
  if [ "$the_src" -nt "$the_dst" ] ; then
    /bin/cp "$the_src" "$the_dst"
  else
    # already exists
    true
  fi
fi

