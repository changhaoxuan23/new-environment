#!/bin/bash

package="krb5"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/krb5/krb5.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
cd src
autoreconf --verbose
cd ..
mkdir build
cd build
../src/configure --prefix="${stow_directory}/${package}"
make --jobs=8 --output-sync

# find and link libraries installed by us since the testing script will clear our LD_LIBRARY_PATH
libraries_to_link=(
  libedit.so.0
  libpython3.13.so.1.0
)
for library in "${libraries_to_link[@]}";do
  find "${target_directory}/lib" -name "${library}" -exec ln -svf '{}' lib/ ';'
done
make check

for library in "${libraries_to_link[@]}";do
  rm lib/"${library}"
done

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install
