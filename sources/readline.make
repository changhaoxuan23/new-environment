#!/bin/bash

package="readline"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://git.savannah.gnu.org/git/readline.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}" \
             --enable-multibyte \
             --enable-shared \
             --enable-static \
             --disable-install-examples
make -j
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install