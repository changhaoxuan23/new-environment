#!/bin/bash

package="ninja"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/ninja-build/ninja.git' release

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
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