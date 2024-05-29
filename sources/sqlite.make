#!/bin/bash

scripts_directory="$(dirname "$0")"

cleanup(){
  stable-remove-directory "${stow_directory}/${package}.new"
  stable-remove-directory "${stow_directory}/${package}.build"
}

source "${scripts_directory}/common/prepare-execution-environment"

package="sqlite"

# prepare source
cd "${stow_directory}"
wget --no-netrc --https-only --continue "https://www.sqlite.org/src/tarball/sqlite.tar.gz?r=release"
mkdir "${stow_directory}/${package}.build"
tar --extract --verbose --file 'sqlite.tar.gz?r=release' --directory="${stow_directory}/${package}.build"
# rm -f 'sqlite.tar.gz?r=release'
cd "${stow_directory}/${package}.build/${package}"
new_version="$(cat VERSION)"

# version check
if ! check-semantic-version;then exit;fi

# build
stable-remove-directory build
mkdir build
cd build

# adapted from Archlinux package
export CFLAGS="${CFLAGS/_FORTIFY_SOURCE=3/_FORTIFY_SOURCE=2}"
export CXXFLAGS="${CXXFLAGS/_FORTIFY_SOURCE=3/_FORTIFY_SOURCE=2}"

export CPPFLAGS="$CPPFLAGS \
  -DSQLITE_ENABLE_COLUMN_METADATA=1 \
  -DSQLITE_ENABLE_UNLOCK_NOTIFY \
  -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
  -DSQLITE_ENABLE_FTS3_TOKENIZER=1 \
  -DSQLITE_ENABLE_FTS3_PARENTHESIS \
  -DSQLITE_SECURE_DELETE \
  -DSQLITE_ENABLE_STMTVTAB \
  -DSQLITE_ENABLE_STAT4 \
  -DSQLITE_MAX_VARIABLE_NUMBER=250000 \
  -DSQLITE_MAX_EXPR_DEPTH=10000 \
  -DSQLITE_ENABLE_MATH_FUNCTIONS"


../configure --prefix="${stow_directory}/${package}" \
             --infodir="${stow_directory}/${package}/share/info/${package}" \
             --enable-shared \
             --enable-static \
             --enable-editline \
	           --enable-fts3 \
	           --enable-fts4 \
	           --enable-fts5 \
	           --enable-rtree \
             TCLLIBDIR="${stow_directory}/${package}/lib/sqlite"
make
make showdb showjournal showstat4 showwal sqldiff sqlite3_analyzer
make DESTDIR="${stow_directory}/${package}.new" install

# install to final place
remove-old-package
mv "${stow_directory}/${package}.new${stow_directory}/${package}" "${stow_directory}/${package}"
version="${new_version}"
install-new-package