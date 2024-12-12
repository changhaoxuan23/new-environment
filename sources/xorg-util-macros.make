#!/bin/bash

package="xorg-util-macros"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://gitlab.freedesktop.org/xorg/util/macros.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
NOCONFIGURE=1 ./autogen.sh
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}"
make --jobs=8 --output-sync

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install
install -Dm644 ../COPYING "${stow_directory}/${package}.new/${stow_directory}/${package}/share/licenses/${package}/COPYING"

# install to final place
version="${new_version}"
full-install