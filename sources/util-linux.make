#!/bin/bash

package="util-linux"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://git.kernel.org/pub/scm/utils/util-linux/util-linux.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
./autogen.sh
stable-remove-directory build
mkdir build
cd build
../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}" \
             --enable-symvers \
             --disable-chfn-chsh \
             --disable-mount \
             --disable-newgrp \
             --disable-su \
             --disable-wall \
             --disable-write
make -j
make DESTDIR="${stow_directory}/${package}.new" install-strip

# install to final place
version="${new_version}"
full-install