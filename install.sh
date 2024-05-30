#!/bin/bash
set -e
if [ $# -ne 2 ];then
  printf -- '\x1b[1;31mError: Invalid usage\x1b[0m\n'
  printf -- 'Usage: install.sh <export-directory> <install-directory>\n'
  printf -- '  <export-directory>  is the directory to be used by everyone on the same machine, like /\n'
  printf -- '  <install-directory> is where packages are actually installed and managed by you\n'
  exit 1
fi
ensure_directory(){
  if [ ! -e "$1" ];then
    if ! mkdir --mode=755 --parents "$1";then
      printf -- '\x1b[1;31mError: failed to mkdir %s\x1b[0m\n' "$1"
      return 1
    fi
    return 0
  fi
  if [ ! -d "$1" ];then
    printf -- '\x1b[1;31mError: %s exists and is not a directory\x1b[0m\n' "$1"
    return 1
  fi
  if [ ! -w "$1" ];then
    printf -- '\x1b[1;31mError: %s exists you have no write permission to it\x1b[0m\n' "$1"
    return 1
  fi
  return 0
}
source_directory="$(dirname "$0")"
export_directory="$1"
install_directory="$2"
ensure_directory "${export_directory}" || exit 1
ensure_directory "${install_directory}" || exit 1
export_directory="$(realpath --canonicalize-existing "${export_directory}")"
install_directory="$(realpath --canonicalize-existing "${install_directory}")"
rm --force --recursive "${install_directory}/scripts"
cp --recursive --no-dereference "${source_directory}/sources" "${install_directory}/scripts"
cp --force "${source_directory}/activator" "${export_directory}/README"
sed -E --in-place "s|__\{\{export_directory\}\}__|${export_directory}|g" \
                  "${install_directory}/scripts/common/prepare-execution-environment" \
                  "${install_directory}/scripts/meta/install.sh" \
                  "${export_directory}/README"
sed -E --in-place "s|__\{\{install_directory\}\}__|${install_directory}|g" \
                  "${export_directory}/README"
chmod 555 "${export_directory}/README"
chmod 500 "${install_directory}/scripts/"*.make \
          "${install_directory}/scripts/common/"* \
          "${install_directory}/scripts/meta/"*
install --directory --mode=1777 "${export_directory}/.meta"
printf -- '\x1b[1;32mDone. You can now run scripts to install packages\x1b[0m\n'