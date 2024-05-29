#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  rm -rf "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="ninja"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://github.com/ninja-build/ninja.git' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git checkout release
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
cmake -S . \
      -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
      -Wno-dev
cmake --build build

# check
build/ninja_test

# install to temporary directory
cd build
install -Dm755 -t "${stow_directory}/${package}.new/bin" ninja
cd ..
install -Dm644 -t "${stow_directory}/${package}.new/share/doc/ninja" doc/manual.asciidoc
install -Dm644 -t "${stow_directory}/${package}.new/share/vim/vimfiles/syntax" misc/ninja.vim
install -Dm644 misc/bash-completion "${stow_directory}/${package}.new/share/bash-completion/completions/ninja"
install -Dm644 misc/zsh-completion "${stow_directory}/${package}.new/share/zsh/site-functions/_ninja"

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new" "${stow_directory}/${package}"
version="${new_version}"
install-new-package