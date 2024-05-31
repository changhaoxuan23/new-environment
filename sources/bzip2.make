#!/bin/bash

package="bzip2"
scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
}

source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'git://sourceware.org/git/bzip2.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# build
make -f Makefile-libbz2_so CC="clang $CFLAGS $CPPFLAGS $LDFLAGS"
make bzip2 bzip2recover CC="clang $CFLAGS $CPPFLAGS $LDFLAGS"

cat << EOF > bzip2.pc
prefix=${target_directory}
exec_prefix=${target_directory}
bindir=\${exec_prefix}/bin
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: bzip2
Description: A file compression library
Version: ${version}
Libs: -L\${libdir} -lbz2
Cflags: -I\${includedir}
EOF

# check
make test


# install to temporary directory
install -dm755 "${stow_directory}/${package}.new"/{bin,lib,include,share/man/man1}

install -m755 bzip2-shared "${stow_directory}/${package}.new"/bin/bzip2
install -m755 bzip2recover bzdiff bzgrep bzmore "${stow_directory}/${package}.new"/bin
ln -sf bzip2 "${stow_directory}/${package}.new"/bin/bunzip2
ln -sf bzip2 "${stow_directory}/${package}.new"/bin/bzcat

cp -a libbz2.so* "${stow_directory}/${package}.new"/lib
source_shared_name="$(find "${stow_directory}/${package}.new/lib" -name 'libbz2.so*' | sort | tail -n 1 | xargs -- basename)"
source_shared_version="${source_shared_name:10}"
ln -s libbz2.so.$source_shared_version "${stow_directory}/${package}.new"/lib/libbz2.so
ln -s libbz2.so.$source_shared_version "${stow_directory}/${package}.new"/lib/libbz2.so.1

install -m644 bzlib.h "${stow_directory}/${package}.new"/include/

install -m644 bzip2.1 "${stow_directory}/${package}.new"/share/man/man1/
ln -sf bzip2.1 "${stow_directory}/${package}.new"/share/man/man1/bunzip2.1
ln -sf bzip2.1 "${stow_directory}/${package}.new"/share/man/man1/bzcat.1
ln -sf bzip2.1 "${stow_directory}/${package}.new"/share/man/man1/bzip2recover.1

install -Dm644 bzip2.pc -t "${stow_directory}/${package}.new"/lib/pkgconfig
install -Dm644 LICENSE "${stow_directory}/${package}.new"/share/licenses/${pkgname}/LICENSE

# cleanup
make distclean
rm -f bzip2.pc

# install to final place
version="${new_version}"
remove-old-package
mv "${stow_directory}/${package}.new" "${stow_directory}/${package}"
install-new-package