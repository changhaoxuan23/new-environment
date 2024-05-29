#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  rm -rf "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="eigen"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://gitlab.com/libeigen/eigen.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git pull --rebase
new_version="$(git rev-parse HEAD)"

# version check
if [ -z "${SKIP_VERSION_CHECK}" ] && [ -f "${stow_directory}/${package}.version" ];then
  old_version="$(cat "${stow_directory}/${package}.version")"
  if [ "${new_version}" = "${old_version}" ];then
    printf -- '%s: already up to date\n' "${package}"
    exit
  fi
fi

# build: eigen does not need to be built

# install to final place
remove-old-package
mkdir --mode=0755 "${stow_directory}/${package}"
mkdir --mode=0755 "${stow_directory}/${package}/include"
cp -r Eigen "${stow_directory}/${package}/include/"
version="${new_version}"
install-new-package