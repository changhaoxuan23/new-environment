#!/bin/bash

package="zstd"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/facebook/zstd.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# 
export CFLAGS+=' -ffat-lto-objects'
export CXXFLAGS+=' -ffat-lto-objects'
cmake -S build/cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
    -DZSTD_ZLIB_SUPPORT=ON \
    -DZSTD_LZMA_SUPPORT=ON \
    -DZSTD_LZ4_SUPPORT=ON \
    -DZSTD_BUILD_CONTRIB=ON \
    -DZSTD_BUILD_STATIC=ON \
    -DZSTD_BUILD_TESTS=ON \
    -DZSTD_PROGRAMS_LINK_SHARED=ON
cmake --build build

# check
LD_LIBRARY_PATH="$(pwd)/build/lib" ctest -VV --test-dir build

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip

# install to final place
version="${new_version}"
full-install