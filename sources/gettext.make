#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  rm -f "${stow_directory}/${source_name}"
  stable-remove-directory "${stow_directory}/${package}.new"
  stable-remove-directory "${stow_directory}/${package}.build"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="gettext"

# prepare source
url="$(curl --silent --location --compressed --fail 'https://www.gnu.org/software/gettext/' | grep -Po 'https://ftp.gnu.org/pub/gnu/gettext/gettext-.+?\.gz' | head -n 1)"
source_name="$(basename "${url}")"
new_version="$(echo -n "${source_name}" | sed -E 's/.*-(.+)\.tar\.gz/\1/')"

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
             --enable-threads=posix \
             --enable-shared \
             --enable-static \
             --enable-year2038
make -j
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package