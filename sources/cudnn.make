# shellcheck shell=bash
# this file is not meant to be executed directly but sourced by other scripts, therefore we will not
#  include a shebang for this file
package="cudnn"
cleanup+=(clean-package-directory clean-build-directory)
_package_version=9.5.1.17
_cuda_version=12

nenv_make_source() {

  # version check
  new_version=${_package_version}
  if ! check-semantic-version; then return 77; fi

  # prepare source
  wget --no-netrc --https-only "https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/cudnn-linux-x86_64-${_package_version}_cuda${_cuda_version}-archive.tar.xz"
  tar xvf "cudnn-linux-x86_64-${_package_version}_cuda${_cuda_version}-archive.tar.xz"
  mv "cudnn-linux-x86_64-${_package_version}_cuda${_cuda_version}-archive" "${source_directory}"
  rm --force "cudnn-linux-x86_64-${_package_version}_cuda${_cuda_version}-archive.tar.xz"
}

nenv_make_pack() {
  cd "${source_directory}"

  mkdir "${package_directory}"
  cp -r lib include "${package_directory}"
  install -Dm644 LICENSE "${package_directory}"/share/licenses/${package}/LICENSE
}

nenv_make_install() {
  version="${new_version}"
  full-install
}
