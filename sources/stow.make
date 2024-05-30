#!/bin/bash

package="stow"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/stow.tar.bz2"
  stable-remove-directory "${stow_directory}/${package}.build"
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

cd "${stow_directory}"
curl --fail --output stow.tar.bz2 'https://ftp.gnu.org/gnu/stow/stow-latest.tar.bz2'
tar xvf stow.tar.bz2
rm -f stow.tar.bz2

source_directory="$(ls | grep stow-)"
new_version="$(echo -n "${source_directory}" | cut -d '-' -f 2)"
if ! check-semantic-version;then exit;fi
mv "${source_directory}" "${stow_directory}/${package}.build"

cd "${stow_directory}/${package}.build"
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}"
make
make DESTDIR="${stow_directory}/${package}.new" install

remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
"${stow_directory}/${package}/bin/stow" --dir="${stow_directory}" \
                                        --target="${target_directory}" \
                                        --stow "${package}"
printf '%s: installed %s\n' "${package}" "${version}"
printf '%s' "${version}" > "${stow_directory}/${package}.version"