#!/bin/bash

package="gawk"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.build"
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://git.savannah.gnu.org/r/gawk.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
./bootstrap.sh
if [ -f Makefile ];then
  make distclean
fi
./configure --prefix="${stow_directory}/${package}"
make -j
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install