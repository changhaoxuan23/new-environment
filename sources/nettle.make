#!/bin/bash

package="nettle"
scripts_directory="$(dirname "$0")"
this_script="$(realpath --canonicalize-existing "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://git.lysator.liu.se/nettle/nettle.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
./.bootstrap
stable-remove-directory build
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --libdir="${stow_directory}/${package}/lib"
make -j

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install