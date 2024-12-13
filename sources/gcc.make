#!/bin/bash

package="gcc"
cleanup+=(clean-package-directory)

nenv_make_source() {
  # prepare source
  prepare-git-source 'git://gcc.gnu.org/git/gcc.git'

  # we shall use the latest commit on a release branch
  cleanup+=(reset-git-repository)
  local _branch
  _branch="$(git branch --remotes | grep /releases/gcc | sort --version-sort --reverse | head -n 1)"
  git checkout "${_branch}"

  # version check
  build-git-version
  if ! check-git-version;then exit;fi
}

nenv_make_prepare() {
  cd "${source_directory}"
  # Do not run fixincludes: not sure what this mean
  sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in

  # use /lib instead of /lib64
  sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64
}

nenv_make_build() {
  cd "${source_directory}"
  
  local _common_options
  _common_options=(
    --prefix="${package_prefix}"
    --libdir="${package_prefix}/lib"
    --libexecdir="${package_prefix}/lib"
    --mandir="${package_prefix}/share/man"
    --infodir="${package_prefix}/share/info"
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

    --with-mpfr="$(find-header-location mpfr.h)"
    --with-mpc="$(find-header-location mpc.h)"
    --with-gmp="$(find-header-location gmp.h)"
  )
  CHOST=x86_64-pc-linux-gnu

  # unset environment variables that will cause unexpected header being included
  unset CFLAGS
  unset CXXFLAGS
  unset CPATH

  # enable colored output
  CC="clang -fcolor-diagnostics"
  CXX="clang++ -fcolor-diagnostics"

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
}

nenv_make_check() {
  cd "${source_directory}/main-build"
  make --output-sync --keep-going check || true
  ../contrib/test_summary
}

nenv_make_pack() {
  cd "${source_directory}/main-build"

  make --directory=gcc DESTDIR="${package_directory}" install-driver     \
                                                                  install-cpp        \
                                                                  install-gcc-ar     \
                                                                  c++.install-common \
                                                                  install-headers    \
                                                                  install-plugin     \
                                                                  install-lto-wrapper

  _internal_version="$(echo -n '__GNUC__.__GNUC_MINOR__.__GNUC_PATCHLEVEL__' | "${package_content_directory}/bin/cpp" -P | tr -cd '.[:digit:]')"

  install -m755 -t "${package_content_directory}/bin/" gcc/gcov{,-tool}
  install -m755 -t "${package_content_directory}/lib/gcc/${CHOST}/${_internal_version}/" gcc/{cc1,cc1plus,collect2,lto1}

  make --directory="${CHOST}/libgcc" DESTDIR="${package_directory}" install
  rm --force "${package_content_directory}/"lib/libgcc_s.so*

  make --directory="${CHOST}/libstdc++-v3/src" DESTDIR="${package_directory}" install
  make --directory="${CHOST}/libstdc++-v3/include" DESTDIR="${package_directory}" install
  make --directory="${CHOST}/libstdc++-v3/libsupc++" DESTDIR="${package_directory}" install
  make --directory="${CHOST}/libstdc++-v3/python" DESTDIR="${package_directory}" install

  make DESTDIR="${package_directory}" install-libcc1
  install -d "${package_content_directory}/share/gdb/auto-load${package_prefix}/lib"
  mv "${package_content_directory}/"lib/libstdc++.so.6.*-gdb.py "${package_content_directory}/share/gdb/auto-load${package_prefix}/lib/"
  rm "${package_content_directory}/"lib/libstdc++.so*

  make DESTDIR="${package_directory}" install-fixincludes
  make --directory=gcc DESTDIR="${package_directory}" install-mkheaders

  make --directory=lto-plugin DESTDIR="${package_directory}" install
  install -dm755 "${package_content_directory}/"lib/bfd-plugins/
  ln --symbolic "../gcc/${CHOST}/${_internal_version}"/liblto_plugin.so "${package_content_directory}/lib/bfd-plugins/"

  make --directory="${CHOST}/libgomp" DESTDIR="${package_directory}" install-nodist_{libsubinclude,toolexeclib}HEADERS
  make --directory="${CHOST}/libitm" DESTDIR="${package_directory}" install-nodist_toolexeclibHEADERS
  make --directory="${CHOST}/libquadmath" DESTDIR="${package_directory}" install-nodist_libsubincludeHEADERS
  make --directory="${CHOST}/libsanitizer" DESTDIR="${package_directory}" install-nodist_{saninclude,toolexeclib}HEADERS
  make --directory="${CHOST}/libsanitizer/asan" DESTDIR="${package_directory}" install-nodist_toolexeclibHEADERS
  make --directory="${CHOST}/libsanitizer/tsan" DESTDIR="${package_directory}" install-nodist_toolexeclibHEADERS
  make --directory="${CHOST}/libsanitizer/lsan" DESTDIR="${package_directory}" install-nodist_toolexeclibHEADERS

  make --directory=gcc DESTDIR="${package_directory}" install-man install-info
  rm "${package_content_directory}/"share/man/man1/lto-dump.1

  make --directory=libcpp DESTDIR="${package_directory}" install
  make --directory=gcc    DESTDIR="${package_directory}" install-po

  ln --symbolic gcc "${package_content_directory}/"bin/cc

  for binary in {c++,g++,gcc,gcc-ar,gcc-nm,gcc-ranlib};do
    ln --symbolic "${binary}" "${package_content_directory}/bin/x86_64-linux-gnu-${binary}"
  done

  # we skip documentation for now
  # make --directory="${CHOST}/libstdc++-v3/doc" DESTDIR="${package_directory}" doc-install-man

  rm -f "${package_content_directory}/"lib32/lib{stdc++,gcc_s}.so

  python -m compileall "${package_content_directory}/share/gcc-${_internal_version}/"
  python -O -m compileall "${package_content_directory}/share/gcc-${_internal_version}/"

  make --directory="${CHOST}/libgcc" DESTDIR="${package_directory}" install-shared
  rm --force "${package_content_directory}/lib/gcc/${CHOST}/${_internal_version}/libgcc_eh.a"

  for lib in libatomic                  \
             libgomp                    \
             libitm                     \
             libquadmath                \
             libsanitizer/{a,l,ub,t}san \
             libstdc++-v3/src           \
             libvtv; do
    make --directory="${CHOST}/${lib}" DESTDIR="${package_directory}" install-toolexeclibLTLIBRARIES
  done

  make --directory="${CHOST}/libstdc++-v3/po" DESTDIR="${package_directory}" install

  rm --recursive --force "${package_content_directory}/lib/gcc/${CHOST}/${_internal_version}/include/d/"
  rm --force "${package_content_directory}/"lib/libgphobos.spec

  for lib in libgomp \
             libitm  \
             libquadmath; do
    make --directory="${CHOST}/${lib}" DESTDIR="${package_directory}" install-info
  done

  rm --recursive --force "${package_content_directory}/"lib32/

  install -Dm644 ../COPYING.RUNTIME "${package_content_directory}/share/licenses/${package}/RUNTIME.LIBRARY.EXCEPTION"

  make --directory=gcc DESTDIR="${package_directory}" lto.install-{common,man,info}

  make --directory=gcc DESTDIR="${package_directory}" jit.install-common jit.install-info

  rm --force "${package_content_directory}/share/info/dir"
}

nenv_make_install() {
  version="${new_version}"
  full-install
}
