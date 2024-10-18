#!/bin/bash

package="colmap"
scripts_directory="$(dirname "$0")"
this_script="$(realpath --canonicalize-existing "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'https://github.com/colmap/colmap.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
stable-remove-directory build
#  find the latest CUDA toolkit available locally if not set
if [ -z "${CUDAToolkit_ROOT}" ];then
  CUDAToolkit_ROOT="/usr/local/$(ls /usr/local | grep cuda- | sort --general-numeric-sort --reverse | head -n 1)"
  export CUDAToolkit_ROOT
  PATH="${CUDAToolkit_ROOT}/bin:${PATH}"
  export PATH
fi
printf -- 'Using CUDA: %s\n' "${CUDAToolkit_ROOT}"

# fix errors
# 1. in src/thirdparty/PoissonRecon/Ply.h, point-p.value should be point-p.value
sed --in-place -E 's|point-p\.value|point-p.point|g' src/thirdparty/PoissonRecon/Ply.h
# 2. in src/thirdparty/PoissonRecon/SparseMatrix.inl, argument of the call to Resize should be fixed
sed --in-place -E 's|this->m_N, this->m_M|this->rows|g' src/thirdparty/PoissonRecon/SparseMatrix.inl


cmake -S . \
      -B build \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="${stow_directory}/${package}" \
      -DCMAKE_CUDA_ARCHITECTURES=native \
      -DFLANN_INCLUDE_DIR_HINTS="${target_directory}/include" \
      -DFLANN_LIBRARY_DIR_HINTS="${target_directory}/lib" \
      -DLZ4_INCLUDE_DIR_HINTS="${target_directory}/include" \
      -DLZ4_LIBRARY_DIR_HINTS="${target_directory}/lib" \
      -DCMAKE_CXX_FLAGS="-include cassert"
cmake --build build -j
git restore .

# install to temporary directory
DESTDIR="${stow_directory}/${package}.new" cmake --install build --strip

# install to final place
version="${new_version}"
full-install