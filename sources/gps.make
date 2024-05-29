#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="gps"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://github.com/changhaoxuan23/gps.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
# git pull --rebase
git checkout v0.0.2
new_version="$(git rev-parse HEAD)"

# version check
if [ -z "${SKIP_VERSION_CHECK}" ] && [ -f "${stow_directory}/${package}.version" ];then
  old_version="$(cat "${stow_directory}/${package}.version")"
  if [ "${new_version}" = "${old_version}" ];then
    printf -- '%s: already up to date\n' "${package}"
    exit
  fi
fi

# build
#  find the latest CUDA toolkit available locally if not set
if [ -z "${CUDA_HOME}" ];then
  export CUDA_HOME="/usr/local/$(ls /usr/local | grep cuda- | sort --general-numeric-sort --reverse | head -n 1)"
fi
printf -- 'Using CUDA: %s\n' "${CUDA_HOME}"

make -j

# install to temporary directory
mkdir --parents --mode=0755 "${stow_directory}/${package}.new/bin"
cp $(make get-binaries) "${stow_directory}/${package}.new/bin/"

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new" "${stow_directory}/${package}"
version="${new_version}"
install-new-package