# shellcheck shell=bash
# this file is not meant to be executed directly but sourced by other scripts, therefore we will not
#  include a shebang for this file
package="doxygen"
cleanup+=(clean-package-directory)

nenv_make_source() {
  # prepare source
  prepare-git-source 'https://github.com/doxygen/doxygen.git'

  # version check
  build-git-version
  if ! check-git-version; then return 77; fi
}

nenv_make_build() {
  cd "${source_directory}"

  local _common_options
  _common_options=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="${package_prefix}"
  )

  # enable colored output
  CC="clang -fcolor-diagnostics"
  CXX="clang++ -fcolor-diagnostics"

  rm --force --recursive build
  mkdir build

  cmake -G Ninja -S . -B build "${_common_options[@]}"
  cmake --build build
}

nenv_make_pack() {
  cd "${source_directory}"

  DESTDIR="${package_directory}" cmake --install build --strip
}

nenv_make_install() {
  version="${new_version}"
  full-install
}
