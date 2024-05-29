#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
  stable-remove-directory "${stow_directory}/${package}.build"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="python"

# fetch url of latest stable
source_url="$(curl --fail --location --compressed --silent 'https://www.python.org/box/supernav-python-downloads/' | grep -Po 'https://.+?.tar.xz')"

# get version code
new_version="$(echo -n "${source_url}" | sed -E 's|.+Python-(.+).tar.xz|\1|')"

# version check
if ! check-semantic-version;then exit;fi

# get source
cd "${stow_directory}"
if [ ! -f "Python-${new_version}.tar.xz" ];then
  wget --no-netrc --https-only "${source_url}"
fi
stable-remove-directory "${stow_directory}/${package}.build"
tar xvf "Python-${new_version}.tar.xz"
mv "Python-${new_version}" python.build

# build
cd python.build
mkdir build
cd build
LDFLAGS="-lncurses ${LDFLAGS}" CFLAGS="${CFLAGS/-O2/-O3} -ffat-lto-objects"
../configure --prefix="${stow_directory}/${package}" \
             --enable-optimizations \
             --with-lto=full \
             --with-readline \
             --enable-shared \
             --with-computed-gotos \
             --enable-ipv6 \
             --enable-loadable-sqlite-extensions

make -j

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
for python_package_script in "${scripts_directory}/python-"*;do
  "${python_package_script}" uninstall
done
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package
