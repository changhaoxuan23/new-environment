#!/bin/bash

package="eigen"
scripts_directory="$(dirname "$0")"

cleanup(){
  rm -rf "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://gitlab.com/libeigen/eigen.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build: eigen does not need to be built

# install to final place
remove-old-package
mkdir --mode=0755 "${stow_directory}/${package}"
mkdir --mode=0755 "${stow_directory}/${package}/include"
cp -r Eigen "${stow_directory}/${package}/include/"
version="${new_version}"
install-new-package