#!/bin/bash
scripts_directory="$(dirname "$0")"
list=(
  stow
  readline
  libedit
  gettext
  cmake
  ninja
  llvm
  eigen
  flex
  ncurses
  onetbb
  tcl
  sqlite
  util-linux
  python
  pybind11
  configurationspp
  secret-storage
  python-secret-storage
  gps
  python-ruff
)
for item in "${list[@]}";do
  if [ $# -eq 1 ] && [ "${item}" != "$1" ];then
    continue
  else
    shift
  fi
  if ! "${scripts_directory}/../${item}.make";then
    printf -- '\x1b[1;31mError: at %s\x1b[0m\n' "${item}"
    exit
  fi
done