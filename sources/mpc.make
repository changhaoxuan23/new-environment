#!/bin/bash

package="mpc"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

scripts_directory="$(new-environment-get-install-directory)/scripts"
source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://gitlab.inria.fr/mpc/mpc.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
autoreconf -i
[ -f Makefile ] && make distclean
./configure --prefix="${stow_directory}/${package}" \
            --infodir="${stow_directory}/${package}/share/info/${package}" \
            --with-mpfr="${target_directory}"
make --jobs=8 --output-sync
make check || true

# install to temporary directory
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
version="${new_version}"
full-install