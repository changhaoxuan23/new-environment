#!/bin/bash

package="jq"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/jqlang/jq.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build-directory
git submodule update --init
autoreconf -i
mkdir build-directory
cd build-directory
../configure --prefix="${stow_directory}/${package}" \
             --with-oniguruma=builtin
make --jobs=8 --output-sync

# we need to link the executable before running test since we are building in a separate directory
ln -svf build-directory/jq ../jq
make check

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install
