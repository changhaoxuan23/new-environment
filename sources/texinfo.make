#!/bin/bash

package="texinfo"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

scripts_directory="$(new-environment-get-install-directory)/scripts"
source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://git.savannah.gnu.org/git/texinfo.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
./autogen.sh
stable-remove-directory build
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}"
make --jobs=8 --output-sync
make check

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install