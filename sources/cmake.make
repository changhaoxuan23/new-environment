#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  rm -rf "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="cmake"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://gitlab.kitware.com/cmake/cmake.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git pull --rebase

# version check
new_version="$(git rev-parse HEAD)"
if [ -z "${SKIP_VERSION_CHECK}" ] && [ -f "${stow_directory}/${package}.version" ];then
  old_version="$(cat "${stow_directory}/${package}.version")"
  if [ "${new_version}" = "${old_version}" ];then
    printf -- '%s: already up to date\n' "${package}"
    exit
  fi
fi

# build
rm -rf build
mkdir build
cd build
../bootstrap --parallel="$(/usr/bin/getconf _NPROCESSORS_ONLN)" \
             --no-system-libs \
             --no-qt-gui \
             --sphinx-man \
             --sphinx-html \
             --prefix="${stow_directory}/${package}" \
             --mandir=/share/man \
             --docdir=/share/doc/cmake \
             --datadir=/share/cmake
make -j

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package