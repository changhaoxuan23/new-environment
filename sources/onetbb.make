#!/bin/bash

package="onetbb"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/oneapi-src/oneTBB.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
CC=clang CXX=clang++ LDFLAGS="-Wl,--undefined-version ${LDFLAGS}" \
cmake -S . \
      -B build \
	    -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}"

cmake --build build

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip

# install to final place
version="${new_version}"
full-install