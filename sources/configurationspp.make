#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="configurationspp"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://github.com/changhaoxuan23/configurationspp.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git pull --rebase
new_version="$(git rev-parse HEAD)"

# version check
if ! check-git-version;then exit;fi

# build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
      -G Ninja -B build -S .
cmake --build build

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" cmake --install build

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package