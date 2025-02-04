#!/bin/bash
scripts_directory="$(dirname "$0")"
source '__{{install_directory}}__/scripts/common/utility'
if ! confirm "This will install ALL packages. Are you sure?";then exit;fi
list=(
  stow
  readline
  libedit
  gettext
  cmake
  ninja
  llvm
  bzip2
  lz4
  zstd
  eigen
  flex
  ncurses
  onetbb
  tcl
  sqlite
  bison
  util-linux
  python
  pybind11
  configurationspp
  secret-storage
  python-secret-storage
  gps
  python-ruff
  send-email
)
source '__{{export_directory}}__/README'
unset CC
unset CXX
unset LDFLAGS
NENV_BOOTSTRAP=1
export NENV_BOOTSTRAP
for item in "${list[@]}";do
  if [ $# -eq 1 ] && [ "${item}" != "$1" ];then
    printf -- '\x1b[1;34mSkipping %s...\x1b[0m\n' "${item}"
    if [ "${item}" = 'llvm' ];then
      source '__{{export_directory}}__/README'
    fi
    continue
  else
    shift
  fi
  printf -- '\x1b[1;34mBuilding %s...\x1b[0m\n' "${item}"
  if ! "${scripts_directory}/../${item}.make";then
    printf -- '\x1b[1;31mError at %s, look at output above\x1b[0m\n' "${item}"
    exit
  fi
  printf -- '\x1b[1;34mDone with %s\x1b[0m\n' "${item}"
  if [ "${item}" = 'llvm' ];then
    source '__{{export_directory}}__/README'
  fi
done