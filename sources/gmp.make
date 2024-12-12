#!/bin/bash

package="gmp"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
  rm -f stable-remove-directory "${stow_directory}/${source_tar}"
  stable-remove-directory "${stow_directory}/${package}.build"
}

scripts_directory="$(new-environment-get-install-directory)/scripts"
source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
_extension='.tar.xz'
source_tar="$(curl --fail --silent "https://ftp.gnu.org/gnu/${package}/?C=M;O=D" | grep -Po 'href="'"${package}"'[^"]+?'"${_extension}"'"' | sed -E 's|href="(.+)"|\1|' | head -n 1)"
cd "${stow_directory}"
wget --no-netrc --https-only "https://ftp.gnu.org/gnu/${package}/${source_tar}"
new_version="${source_tar:${#package}+1:-${#_extension}}"

# version check
if ! check-semantic-version;then exit;fi

# build
tar xvf "${source_tar}"
mv "${package}-${new_version}" "${package}.build"
cd "${package}.build"
stable-remove-directory build
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}"
make --jobs --output-sync
make check
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install