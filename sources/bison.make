#!/bin/bash

package="bison"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
  if [ -n "${source_tar}" ];then
    stable-remove-directory "${stow_directory}/${source_tar}"
  fi
  stable-remove-directory "${stow_directory}/${package}.build"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
source_tar="$(curl --fail --silent 'https://ftp.gnu.org/gnu/bison/?C=M;O=D' | grep -Po 'href="bison[^"]+?.xz"' | sed -E 's|href="(.+)"|\1|' | head -n 1)"
cd "${stow_directory}"
wget --no-netrc --https-only "https://ftp.gnu.org/gnu/bison/${source_tar}"
new_version="${source_tar:6:-7}"

# version check
if ! check-semantic-version;then exit;fi

# build
tar xvf "${source_tar}"
mv "${source_tar::-7}" "${package}.build"
cd "${package}.build"
stable-remove-directory build
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}" \
             --enable-threads=posix
make -j
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install