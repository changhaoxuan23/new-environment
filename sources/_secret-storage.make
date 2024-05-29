#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

_package="_secret-storage"
if [ "$(basename "$0")" = 'secret-storage.make' ];then
  package="secret-storage"
elif [ "$(basename "$0")" = 'python-secret-storage.make' ];then
  package="python-secret-storage"
else
  exit 1
fi

check-uninstall "$@"

# prepare source
if [ ! -d "${stow_directory}/${_package}.build" ];then
  git clone 'https://github.com/changhaoxuan23/secret-storage.git' "${stow_directory}/${_package}.build"
fi
cd "${stow_directory}/${_package}.build"
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
if [ "${package}" = 'secret-storage' ];then
  DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip --component ClientLibrary
  DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip --component Server
elif [ "${package}" = 'python-secret-storage' ];then
  DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip --component PythonLanguageBinding
fi

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package