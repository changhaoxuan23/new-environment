#!/bin/bash

package="cmake"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://gitlab.kitware.com/cmake/cmake.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
mkdir build
cd build
if ! sphinx-build --version >/dev/null 2>&1;then
  temporary_directory="$(mktemp --directory)"
  if ! python3 -m venv "${temporary_directory}";then
    log-red "Cannot prepare sphinx automatically which is required by cmake.\n"
    log-yellow "  You have to provide sphinx manually to this script first.\n"
    log-yellow "  If this cannot be done, consider install python via provided script first.\n"
    log-yellow "  If you encountered this error when executing meta/install.sh, you may want to reinstall\n"
    log-yellow "   python later since python, when build at this time point, will have incomplete features\n"
    exit 1
  fi
  source "${temporary_directory}/bin/activate"
  python3 -m pip install sphinx
fi
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

if [ -n "${temporary_directory}" ];then
  deactivate
  stable-remove-directory "${temporary_directory}"
  unset temporary_directory
fi

# install to final place
version="${new_version}"
full-install