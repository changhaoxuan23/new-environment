#!/bin/bash

package="gcc"

cleanup(){
  # stable-remove-directory "${stow_directory}/${package}.new"
  git -C "${stow_directory}/${package}.build" reset --hard HEAD
  true
}

scripts_directory="$(new-environment-get-install-directory)/scripts"
source "${scripts_directory}/common/prepare-execution-environment"

# prepare source
prepare-git-source 'git://gcc.gnu.org/git/gcc.git'

# version check
build-git-version
if ! check-git-version;then exit;fi

# find mpc, gmp and mpfr
helper_script="$(mktemp)"
cat > "${helper_script}" <<EOF
target_name="\$1"
shift
for arg in "\$@";do
  if [ "\$(basename "\${arg}")" = "\${target_name}" ];then
    echo "\${arg}"
    break
  fi
done
EOF

find_package_with_header (){
  local header_name
  local helper_make
  local full_path
  helper_make="$(mktemp)"
  header_name="$1"
  printf '#include <%s>' "${header_name}" | clang-cpp -MM > "${helper_make}"
  printf '\t@bash %s %s $^\n' "${helper_script}" "${header_name}" >> "${helper_make}"
  full_path="$(make --file="${helper_make}")"
  printf '%s' "${full_path/\/include\/"${header_name}"}"
  rm -f "${helper_make}"
}

# build
_common_options=(
  --prefix="${stow_directory}/${package}"
  --libdir="${stow_directory}/${package}/lib"
  --libexecdir="${stow_directory}/${package}/lib"
  --mandir="${stow_directory}/${package}/share/man"
  --infodir="${stow_directory}/${package}/share/info"
  --with-build-config=bootstrap-lto
  --with-linker-hash-style=gnu
  --with-system-zlib
  --enable-__cxa_atexit
  --enable-cet=auto
  --enable-checking=release
  --enable-clocale=gnu
  --enable-default-pie
  --enable-default-ssp
  --enable-gnu-indirect-function
  --enable-gnu-unique-object
  --enable-libstdcxx-backtrace
  --enable-link-serialization=1
  --enable-linker-build-id
  --enable-lto
  --enable-plugin
  --enable-shared
  --enable-threads=posix

  --disable-libssp
  --disable-libstdcxx-pch
  --disable-multilib
  --disable-werror

  --with-mpfr="$(find_package_with_header mpfr.h)"
  --with-mpc="$(find_package_with_header mpc.h)"
  --with-gmp="$(find_package_with_header gmp.h)"
)

CHOST=x86_64-pc-linux-gnu

# unset environment variables that will cause unexpected header being included
unset CFLAGS
unset CXXFLAGS
unset CPATH

# enable colored output
CC="clang -fcolor-diagnostics"
CXX="clang++ -fcolor-diagnostics"

# Do not run fixincludes: not sure what this mean
sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in

# use /lib instead of /lib64
sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64

stable-remove-directory main-build
mkdir main-build
cd main-build
../configure --enable-languages=c,c++,lto \
             --enable-bootstrap           \
             "${_common_options[@]}"

make --jobs=8 --output-sync STAGE1_CFLAGS="-O2"             \
                            BOOT_CFLAGS="${CFLAGS}"         \
                            BOOT_CXXFLAGS="${CXXFLAGS}"     \
                            BOOT_LDFLAGS="${LDFLAGS}"       \
                            LDFLAGS_FOR_TARGET="${LDFLAGS}" \
                            bootstrap

# we skip documentation for now
# make --output-sync --directory="${CHOST}/libstdc++-v3/doc" doc-man-doxygen

cd ..
stable-remove-directory libgccjit-build
mkdir libgccjit-build
cd libgccjit-build
../configure --enable-languages=jit \
             --disable-bootstrap    \
             --enable-host-shared   \
             "${_common_options[@]}"

make --jobs=8 --output-sync STAGE1_CFLAGS="-O2"             \
                            BOOT_CFLAGS="${CFLAGS}"         \
                            BOOT_CXXFLAGS="${CXXFLAGS}"     \
                            BOOT_LDFLAGS="${LDFLAGS}"       \
                            LDFLAGS_FOR_TARGET="${LDFLAGS}" \
                            all-gcc

cp --archive gcc/libgccjit.so* ../main-build/gcc/

# ------------------------------------------------------------------------------------------------------------

# check
cd ../main-build
make --output-sync --keep-going check || true
../contrib/test_summary

# ------------------------------------------------------------------------------------------------------------

# install to temporary directory
make --directory=gcc DESTDIR="${stow_directory}/${package}.new" install-driver     \
                                                                install-cpp        \
                                                                install-gcc-ar     \
                                                                c++.install-common \
                                                                install-headers    \
                                                                install-plugin     \
                                                                install-lto-wrapper

_internal_version="$(echo -n '__GNUC__.__GNUC_MINOR__.__GNUC_PATCHLEVEL__' | "${stow_directory}/${package}.new/${stow_directory}/${package}/bin/cpp" -P | tr -cd '.[:digit:]')"

install -m755 -t "${stow_directory}/${package}.new/${stow_directory}/${package}/bin/" gcc/gcov{,-tool}
install -m755 -t "${stow_directory}/${package}.new/${stow_directory}/${package}/lib/gcc/${CHOST}/${_internal_version}/" gcc/{cc1,cc1plus,collect2,lto1}

make --directory="${CHOST}/libgcc" DESTDIR="${stow_directory}/${package}.new" install
rm --force "${stow_directory}/${package}.new/${stow_directory}/${package}/"lib/libgcc_s.so*

make --directory="${CHOST}/libstdc++-v3/src" DESTDIR="${stow_directory}/${package}.new" install
make --directory="${CHOST}/libstdc++-v3/include" DESTDIR="${stow_directory}/${package}.new" install
make --directory="${CHOST}/libstdc++-v3/libsupc++" DESTDIR="${stow_directory}/${package}.new" install
make --directory="${CHOST}/libstdc++-v3/python" DESTDIR="${stow_directory}/${package}.new" install

make DESTDIR="${stow_directory}/${package}.new" install-libcc1
install -d "${stow_directory}/${package}.new/${stow_directory}/${package}/share/gdb/auto-load/${stow_directory}/${package}/lib"
mv "${stow_directory}/${package}.new/${stow_directory}/${package}/"lib/libstdc++.so.6.*-gdb.py "${stow_directory}/${package}.new/${stow_directory}/${package}/share/gdb/auto-load/${stow_directory}/${package}/lib/"
rm "${stow_directory}/${package}.new/${stow_directory}/${package}/"lib/libstdc++.so*

make DESTDIR="${stow_directory}/${package}.new" install-fixincludes
make --directory=gcc DESTDIR="${stow_directory}/${package}.new" install-mkheaders

make --directory=lto-plugin DESTDIR="${stow_directory}/${package}.new" install
install -dm755 "${stow_directory}/${package}.new/${stow_directory}/${package}/"lib/bfd-plugins/
ln --symbolic "${stow_directory}/${package}/lib/gcc/${CHOST}/${_internal_version}"/liblto_plugin.so "${stow_directory}/${package}.new/${stow_directory}/${package}/lib/bfd-plugins/"

make --directory="${CHOST}/libgomp" DESTDIR="${stow_directory}/${package}.new" install-nodist_{libsubinclude,toolexeclib}HEADERS
make --directory="${CHOST}/libitm" DESTDIR="${stow_directory}/${package}.new" install-nodist_toolexeclibHEADERS
make --directory="${CHOST}/libquadmath" DESTDIR="${stow_directory}/${package}.new" install-nodist_libsubincludeHEADERS
make --directory="${CHOST}/libsanitizer" DESTDIR="${stow_directory}/${package}.new" install-nodist_{saninclude,toolexeclib}HEADERS
make --directory="${CHOST}/libsanitizer/asan" DESTDIR="${stow_directory}/${package}.new" install-nodist_toolexeclibHEADERS
make --directory="${CHOST}/libsanitizer/tsan" DESTDIR="${stow_directory}/${package}.new" install-nodist_toolexeclibHEADERS
make --directory="${CHOST}/libsanitizer/lsan" DESTDIR="${stow_directory}/${package}.new" install-nodist_toolexeclibHEADERS

make --directory=gcc DESTDIR="${stow_directory}/${package}.new" install-man install-info
rm "${stow_directory}/${package}.new/${stow_directory}/${package}/"share/man/man1/lto-dump.1

make --directory=libcpp DESTDIR="${stow_directory}/${package}.new" install
make --directory=gcc    DESTDIR="${stow_directory}/${package}.new" install-po

ln --symbolic gcc "${stow_directory}/${package}.new/${stow_directory}/${package}/"bin/cc

for binary in {c++,g++,gcc,gcc-ar,gcc-nm,gcc-ranlib};do
  ln --symbolic "${stow_directory}/${package}/bin/${binary}" "${stow_directory}/${package}.new/${stow_directory}/${package}/bin/x86_64-linux-gnu-${binary}"
done

# we skip documentation for now
# make --directory="${CHOST}/libstdc++-v3/doc" DESTDIR="${stow_directory}/${package}.new" doc-install-man

rm -f "${stow_directory}/${package}.new/${stow_directory}/${package}/"lib32/lib{stdc++,gcc_s}.so

python -m compileall "${stow_directory}/${package}.new/${stow_directory}/${package}/share/gcc-${_internal_version}/"
python -O -m compileall "${stow_directory}/${package}.new/${stow_directory}/${package}/share/gcc-${_internal_version}/"

make --directory="${CHOST}/libgcc" DESTDIR="${stow_directory}/${package}.new" install-shared
rm --force "${stow_directory}/${package}.new/${stow_directory}/${package}/lib/gcc/${CHOST}/${_internal_version}/libgcc_eh.a"

for lib in libatomic                  \
           libgomp                    \
           libitm                     \
           libquadmath                \
           libsanitizer/{a,l,ub,t}san \
           libstdc++-v3/src           \
           libvtv; do
  make --directory="${CHOST}/${lib}" DESTDIR="${stow_directory}/${package}.new" install-toolexeclibLTLIBRARIES
done

make --directory="${CHOST}/libstdc++-v3/po" DESTDIR="${stow_directory}/${package}.new" install

rm --recursive --force "${stow_directory}/${package}.new/${stow_directory}/${package}/lib/gcc/${CHOST}/${_internal_version}/include/d/"
rm --force "${stow_directory}/${package}.new/${stow_directory}/${package}/"lib/libgphobos.spec

for lib in libgomp \
           libitm  \
           libquadmath; do
  make --directory="${CHOST}/${lib}" DESTDIR="${stow_directory}/${package}.new" install-info
done

rm --recursive --force "${stow_directory}/${package}.new/${stow_directory}/${package}/"lib32/

install -Dm644 ../COPYING.RUNTIME "${stow_directory}/${package}.new/${stow_directory}/${package}/share/licenses/${package}/RUNTIME.LIBRARY.EXCEPTION"

make --directory=gcc DESTDIR="${stow_directory}/${package}.new" lto.install-{common,man,info}

make --directory=gcc DESTDIR="${stow_directory}/${package}.new" jit.install-common jit.install-info

# install to final place
version="${new_version}"
full-install
