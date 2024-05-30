#!/bin/bash

package="gps"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/changhaoxuan23/gps.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
#  find the latest CUDA toolkit available locally if not set
if [ -z "${CUDAToolkit_ROOT}" ];then
  CUDAToolkit_ROOT="/usr/local/$(ls /usr/local | grep cuda- | sort --general-numeric-sort --reverse | head -n 1)"
  export CUDAToolkit_ROOT
fi
printf -- 'Using CUDA: %s\n' "${CUDAToolkit_ROOT}"

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
      -G Ninja -B build -S .
cmake --build build

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip

# install to final place
version="${new_version}"
full-install