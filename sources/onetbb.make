#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  rm -rf "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="onetbb"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://github.com/oneapi-src/oneTBB.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git pull --rebase
new_version="$(git rev-parse HEAD)"

# version check
if [ -z "${SKIP_VERSION_CHECK}" ] && [ -f "${stow_directory}/${package}.version" ];then
  old_version="$(cat "${stow_directory}/${package}.version")"
  if [ "${new_version}" = "${old_version}" ];then
    printf -- '%s: already up to date\n' "${package}"
    exit
  fi
fi

# build
rm -rf build
CC=clang CXX=clang++ LDFLAGS="-Wl,--undefined-version ${LDFLAGS}" \
cmake -S . \
      -B build \
	    -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}"

cmake --build build

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" ninja -C build install

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package