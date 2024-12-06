#!/bin/bash

package="cuda"
_version="12.6.3"
_dirver_version="560.35.05"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
  stable-remove-directory "${stow_directory}/${package}.build"
}
source "${scripts_directory}/common/prepare-execution-environment"

while [ $# -gt 0 ];do
  case "$1" in
    '--')
        shift
        break
    ;;
    '-v' | '--version')
      _version="$2"
      shift
    ;;
    '--dirver-version')
      _dirver_version="$2"
      shift
    ;;
    *)
      log-red 'Invalid option [%s]!\n' "$1"
      exit 1
    ;;
  esac
  shift
done

# version check
new_verion="${_version}"
if ! check-semantic-version;then exit;fi

# prepare source
mkdir "${stow_directory}/${package}.build"
cd "${stow_directory}/${package}.build"
wget --no-netrc \
     --https-only \
     "https://developer.download.nvidia.com/compute/cuda/${_version}/local_installers/cuda_${_version}_${_dirver_version}_linux.run"

mkdir extract
sh "cuda_${_version}_${_dirver_version}_linux.run" --target extract --noexec

# =========================================================================================================

# build
_prepare_directory="$(readlink -m prepare)"
mkdir "${_prepare_directory}"
cd extract/builds

rm -r NVIDIA*.run bin
mkdir -p "${_prepare_directory}/opt/cuda/extras"
mv integration nsight_compute nsight_systems EULA.txt "${_prepare_directory}/opt/cuda"
mv cuda_demo_suite/extras/demo_suite "${_prepare_directory}/opt/cuda/extras/demo_suite"
mv cuda_sanitizer_api/compute-sanitizer "${_prepare_directory}/opt/cuda/extras/compute-sanitizer"
rmdir cuda_sanitizer_api
for lib in *; do
  if [[ "${lib}" =~ .*"version.json".* ]]; then
    continue
  fi
  cp -r "${lib}/"* "${_prepare_directory}/opt/cuda/"
done

rm -r "${_prepare_directory}"/opt/cuda/bin/cuda-uninstaller
ln -s lib64 "${_prepare_directory}/opt/cuda/lib"

# disable checking on newer compilers
sed -i "/.*unsupported GNU version.*/d" "${_prepare_directory}"/opt/cuda/targets/x86_64-linux/include/crt/host_config.h
sed -i "/.*unsupported clang version.*/d" "${_prepare_directory}"/opt/cuda/targets/x86_64-linux/include/crt/host_config.h

# change path since we use different path than /usr/local/cuda
find "${_prepare_directory}/opt/cuda" -name Makefile -exec sed -i "s|/usr/local/cuda|${target_directory}/opt/cuda|g" '{}' ';'

# =========================================================================================================

# install to temporary directory
package_directory="${stow_directory}/${package}.new"
mkdir "${package_directory}"
cd "${_prepare_directory}"
cp --archive --link ./* "${package_directory}"

# remove broken links
rm "${package_directory}"/opt/cuda/include/include
rm "${package_directory}"/opt/cuda/lib64/lib64

# script to update PATH and LD_LIBRARY_PATH
mkdir -p "${package_directory}/etc/profile.d"
cat > "${package_directory}/etc/profile.d/cuda.sh" <<EOF
# environment variables to find executables
export CUDA_PATH="${target_directory}/opt/cuda"
prepend_pathlike PATH "${target_directory}/opt/cuda/bin"
prepend_pathlike PATH "${target_directory}/opt/cuda/nsight_compute"
prepend_pathlike PATH "${target_directory}/opt/cuda/nsight_systems/bin"
export PATH

# environment variables to find libraries
prepend_pathlike LD_LIBRARY_PATH "${target_directory}/opt/cuda/lib64"
prepend_pathlike LD_LIBRARY_PATH "${target_directory}/opt/cuda/nvvm/lib64"
prepend_pathlike LD_LIBRARY_PATH "${target_directory}/opt/cuda/extras/CUPTI/lib64"
EOF

# licenses and readme
mkdir -p "${package_directory}/usr/share/licenses/${package}"
ln -s /opt/cuda/EULA.txt "${package_directory}/usr/share/licenses/${package}/EULA.txt"
ln -s /opt/cuda/README "${package_directory}/usr/share/licenses/${package}/README"

# install to final place
version="${new_version}"
# we do not use full-install since we do not have nested file tree structure in .new directory
remove-old-package
mv "${package_directory}" "${stow_directory}/${package}"
install-new-package
