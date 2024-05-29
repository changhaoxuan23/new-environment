#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="util-linux"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://git.kernel.org/pub/scm/utils/util-linux/util-linux.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git pull --rebase
new_version="$(git rev-parse HEAD)"

# version check
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
make
make DESTDIR="${stow_directory}/${package}.new" install-strip

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package