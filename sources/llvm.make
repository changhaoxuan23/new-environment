#!/bin/bash

package="llvm"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/llvm/llvm-project'

# version check
build-git-version
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
DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip

# install to final place
version="${new_version}"
full-install

if [ "${rerun}" = 'true' ];then
  unset rerun
  SKIP_VERSION_CHECK=1 "$0"
  exit
fi
if [ -f "${stow_directory}/${package}.backup" ];then
  stable-remove-directory "${stow_directory}/${package}.backup"
fi