#!/bin/bash

package="flex"
scripts_directory="$(dirname "$0")"

cleanup(){
  rm -f "${stow_directory}/${source_name}"
  stable-remove-directory "${stow_directory}/${package}.new"
  stable-remove-directory "${stow_directory}/${package}.build"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
new_version="$(curl --verbose --compressed --fail 'https://github.com/westes/flex/releases/latest' 2>&1 | grep 'location:' | sed -E 's|.+/v([^/]+)$|\1|' | tr -d '\n\r')"
if [ -z "${new_version}" ];then exit 1;fi
url="https://github.com/westes/flex/releases/download/v${new_version}/flex-${new_version}.tar.gz"
source_name="$(basename "${url}")"

# version check
if ! check-semantic-version;then exit;fi

cd "${stow_directory}"
wget --no-netrc --https-only --continue "${url}"
tar xvf "${source_name}"
mv "${package}-${new_version}" "${package}.build"
cd "${package}.build"

# build
stable-remove-directory build
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}" \
             --enable-shared \
             --enable-static
make -j
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install