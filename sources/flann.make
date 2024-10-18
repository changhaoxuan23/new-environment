#!/bin/bash

package="flann"
scripts_directory="$(dirname "$0")"
this_script="$(realpath --canonicalize-existing "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/flann-lib/flann.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
#  find the latest CUDA toolkit available locally if not set
if [ -z "${CUDAToolkit_ROOT}" ];then
  CUDAToolkit_ROOT="/usr/local/$(ls /usr/local | grep cuda- | sort --general-numeric-sort --reverse | head -n 1)"
  export CUDAToolkit_ROOT
fi
printf -- 'Using CUDA: %s\n' "${CUDAToolkit_ROOT}"

# workaround unsupported compiler
stable-remove-directory temporary-path
mkdir temporary-path
printf -- '#/bin/bash\nnvcc --allow-unsupported-compiler "$@"' > temporary-path/nvcc
PATH="$(readlink -m temporary-path):${PATH}"
export PATH

cmake -S . \
      -B build \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
      -DBUILD_MATLAB_BINDINGS=OFF \
      -DBUILD_CUDA_LIB=ON \
      -DBUILD_EXAMPLES=OFF
cmake --build build

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip

# install to final place
version="${new_version}"
full-install