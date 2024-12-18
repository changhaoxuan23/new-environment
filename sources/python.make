# shellcheck shell=bash
# this file is not meant to be executed directly but sourced by other scripts, therefore we will not
#  include a shebang for this file

package="python"
cleanup+=(clean-package-directory clean-build-directory)

nenv_make_source() {
  # fetch url of latest stable
  source_url="$(curl --fail --location --compressed --silent 'https://www.python.org/box/supernav-python-downloads/' | grep -Po 'https://.+?.tar.xz')"

  # get version code
  new_version="$(echo -n "${source_url}" | sed -E 's|.+Python-(.+).tar.xz|\1|')"

  # version check
  if ! check-semantic-version;then return 77;fi

  # get source
  cd "${stow_directory}"
  wget --no-netrc --https-only "${source_url}"
  tar xvf "Python-${new_version}.tar.xz"
  mv "Python-${new_version}" "${source_directory}"
}

nenv_make_build() {
  cd "${source_directory}"

  mkdir build
  cd build
  LDFLAGS="-lncurses ${LDFLAGS}" CFLAGS="${CFLAGS/-O2/-O3} -ffat-lto-objects"
  ../configure --prefix="${package_prefix}" \
             --enable-optimizations \
             --with-lto=full \
             --with-readline \
             --enable-shared \
             --with-computed-gotos \
             --enable-ipv6 \
             --enable-loadable-sqlite-extensions
  make --jobs --output-sync
}

nenv_make_pack() {
  cd "${source_directory}"

  make DESTDIR="${package_directory}" install

  # make symbolic links: python -> python3 and pip -> pip3
  ln --symbolic python3 "${package_content_directory}/bin/python"
  ln --symbolic pip3 "${package_content_directory}/bin/pip"
}

nenv_make_install() {
  for python_package_script in "${scripts_directory}/python-"*;do
    "${python_package_script}" uninstall
  done

  version="${new_version}"
  full-install

  # reinstall all python packages if not bootstrapping
  if [ -z "${NENV_BOOTSTRAP}" ];then
    for python_package_script in "${scripts_directory}/python-"*;do
      "${python_package_script}" uninstall
    done
  fi
}
