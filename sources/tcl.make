#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
  # stable-remove-directory "${stow_directory}/${package}.build"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="tcl"

# prepare source
cd "${stow_directory}"
wget --no-netrc --https-only --continue "https://sourceforge.net/projects/tcl/files/latest/download"
unzip download
# rm -f 'sqlite.tar.gz?r=release'
source_directory="$(ls -1 | grep ^tcl)"
new_version="$(echo -n "${source_directory}" | tail -c +4)"
mv "${source_directory}" "${package}.build"

# version check
if ! check-semantic-version;then exit;fi

# build
cd "${stow_directory}/${package}.build/unix"
stable-remove-directory build
mkdir build
cd build

../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}" \
             --enable-threads \
             --enable-shared \
             --enable-64bit
make -j
make test
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package