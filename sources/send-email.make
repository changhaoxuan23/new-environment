#!/bin/bash

package="send-email"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/changhaoxuan23/send-email.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build: this package do not need that

# install to temporary directory
install --directory --mode=0755 "${stow_directory}/${package}.new/bin"
install --mode=0555 send-email.py "${stow_directory}/${package}.new/bin/"

# install to final place
version="${new_version}"
remove-old-package
mv "${stow_directory}/${package}.new" "${stow_directory}/${package}"
install-new-package