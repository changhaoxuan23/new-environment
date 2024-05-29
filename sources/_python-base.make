#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

script_name="$(basename "$0")"
if [ "${script_name:$((${#script_name}-5))}" != '.make' ] || [ "${script_name::7}" != 'python-' ];then
  echo 'Invalid file name'
  exit 1
fi

package="${script_name::-5}"

check-uninstall "$@"

# install to temporary directory
python3 -m pip install --no-deps \
                       --prefix "${stow_directory}/${package}.new" \
                       --no-warn-script-location \
                       --isolated \
                       --no-cache-dir \
                       "${package:7}"

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new" "${stow_directory}/${package}"
version="${new_version}"
install-new-package