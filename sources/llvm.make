#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="llvm"

# prepare source
if [ ! -d "${stow_directory}/${package}.build" ];then
  git clone 'https://github.com/llvm/llvm-project' "${stow_directory}/${package}.build"
fi
cd "${stow_directory}/${package}.build"
git pull --rebase
build-git-version

# version check
if ! check-git-version;then exit;fi

if [ -d "${stow_directory}/${package}" ];then
  cp -r "${stow_directory}/${package}" "${stow_directory}/${package}.backup"
fi

# build
stable-remove-directory build
if clang --version >/dev/null 2>&1 && clang++ --version  >/dev/null 2>&1;then
  CC=clang CXX=clang++ \
  cmake -S llvm \
        -B build \
	      -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
        -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;libc;lld;lldb;polly;pstl' \
        -DLLVM_ENABLE_RUNTIMES='compiler-rt;libcxx;libcxxabi;libunwind' \
	      -DLLVM_TARGETS_TO_BUILD=X86 \
        -DLLDB_ENABLE_LIBEDIT=On
else
  rerun=true
  cmake -S llvm \
        -B build \
	      -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
        -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra' \
	      -DLLVM_TARGETS_TO_BUILD=X86
fi
cmake --build build

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" ninja -C build install

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package
if [ "${rerun}" = 'true' ];then
  unset rerun
  SKIP_VERSION_CHECK=1 "$0"
fi