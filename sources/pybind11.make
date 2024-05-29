#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="pybind11"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://github.com/pybind/pybind11.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git pull --rebase
new_version="$(git rev-parse HEAD)"

# version check
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
  -DPYBIND11_INSTALL=ON \
  -DPYBIND11_TEST=OFF \
  -DPYBIND11_NOPYTHON=ON

cmake --build build

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" ninja -C build install

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package
