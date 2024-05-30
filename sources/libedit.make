#!/bin/bash

package="libedit"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
  stable-remove-directory "${stow_directory}/${package}.build"
}

source "${scripts_directory}/common/prepare-execution-environment"

# fetch url of latest stable
name="$(curl --fail --location --compressed --silent 'https://www.thrysoee.dk/editline/' | grep -Po '".+?\.tar\.gz"' | tr -d '"')"
source_url="https://www.thrysoee.dk/editline/${name}"

# get version code
new_version="$(echo -n "${source_url}" | sed -E 's|.+libedit-(.+).tar.gz|\1|')"

# version check
if ! check-semantic-version;then exit;fi

# get source
cd "${stow_directory}"
wget --no-netrc --https-only "${source_url}"
stable-remove-directory "${stow_directory}/${package}.build"
tar xvf "${name}"
rm -f "${name}"
mv "libedit-${new_version}" "${package}.build"

# build
cd "${package}.build"
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}" \
             --enable-shared \
             --enable-static \
             --enable-fast-install \
             --disable-examples
make -j

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install
# FIXME: this page conflicts readline, remove it
rm -f "${stow_directory}/${package}.new${stow_directory}/${package}/share/man/man3/history.3"

# install to final place
version="${new_version}"
full-install