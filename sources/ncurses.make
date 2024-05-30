#!/bin/bash

package="ncurses"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
  stable-remove-directory "${stow_directory}/${package}.build"
}

source "${scripts_directory}/common/prepare-execution-environment"

# get source
cd "${stow_directory}"
wget --no-netrc --https-only 'https://invisible-island.net/datafiles/release/ncurses.tar.gz'
stable-remove-directory "${stow_directory}/${package}.build"
tar xvf ncurses.tar.gz
rm -f ncurses.tar.gz

# get and check version code
source_directory="$(ls | grep ncurses-)"
new_version="$(echo -n "${source_directory}" | cut -d '-' -f 2).0"
if ! check-semantic-version;then exit;fi

mv "${source_directory}" ncurses.build

base_configurations=(
  --prefix="${stow_directory}/${package}"
  --disable-root-access
  --disable-root-environ
  --disable-setuid-environ
  --enable-pc-files
  --mandir=/usr/share/man
  --with-cxx-binding
  --with-cxx-shared
  --with-manpage-format=normal
  --with-shared
  --with-versioned-syms
  --with-xterm-kbs=del
  --without-ada
  --with-strip-program=llvm-strip
  --without-debug
)

# build normal version
cd "${stow_directory}/${package}.build"
mkdir build
cd build
LDFLAGS="-Wl,--undefined-version ${LDFLAGS}"  ../configure "${base_configurations[@]}"
             
make -j
make DESTDIR="${stow_directory}/${package}.new" install
cd ..
stable-remove-directory build

# build wide-character version
mkdir build
cd build
LDFLAGS="-Wl,--undefined-version ${LDFLAGS}" ../configure --enable-widec "${base_configurations[@]}"
make -j
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install
