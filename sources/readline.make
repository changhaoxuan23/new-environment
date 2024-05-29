#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="readline"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://git.savannah.gnu.org/git/readline.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git pull --rebase

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}" \
             --enable-multibyte \
             --enable-shared \
             --enable-static \
             --disable-install-examples
make -j
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package