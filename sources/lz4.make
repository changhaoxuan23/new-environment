#!/bin/bash

package="lz4"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/lz4/lz4.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
cmake -S build/cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
    -DBUILD_STATIC_LIBS=On \
    -Wno-dev
cmake --build build

# check
rm -f passwd.lz4
build/lz4 /etc/passwd passwd.lz4
build/lz4 -d passwd.lz4 passwd
diff -q /etc/passwd passwd
rm passwd


# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip

# install to final place
version="${new_version}"
full-install