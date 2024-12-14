#!/bin/bash
# install (not really) all packages available by an predefined order
#  if no argument is supplied, all packages will be installed
#  otherwise, we will only install the package supplied as $1 and subsequent packages
#  this can be used as a handy way to resume installation

scripts_directory="$(dirname "$0")"
# shellcheck source=../common/utility
source '__{{install_directory}}__/scripts/common/utility'
if ! confirm "This will install ALL packages. Are you sure?";then exit;fi

# list of all packages, note that this is not updated for quite a long time
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
# activate nenv bu sourcing the activator
# shellcheck source=../../activator
source '__{{export_directory}}__/README'

# since the activator sets CC=clang, CXX=clang++ and LDFLAGS=-fuse-ld=lld, which may be not available when
#  doing the initial installation of packages, we unset them
unset CC
unset CXX
unset LDFLAGS

# mark that we are doing bootstrap: this is a standard environment and some make scripts will change their
#  behavior accordingly, see package-scripting for more information on this and similar variables
NENV_BOOTSTRAP=1
export NENV_BOOTSTRAP

for item in "${list[@]}";do
  # check if we should skip this package
  if [ $# -eq 1 ] && [ "${item}" != "$1" ];then
    log-blue 'Skipping %s...\n' "${item}"
  else
    if [ $# -eq 1 ];then
      # argument is supplied but we did not go to the if branch
      #  $1 must matched $item
      shift
    fi

    log-blue 'Building %s...\n' "${item}"
    if ! "${scripts_directory}/../${item}.make";then
      log-red 'Error when building and installing %s, look at output above\n' "${item}"
      exit 1
    fi

    log-green 'Done with %s\n' "${item}"
  fi
  
  # we want to use the clang/llvm toolchain immediately after which is available
  if [ "${item}" = 'llvm' ];then
    # shellcheck source=../../activator
    source '__{{export_directory}}__/README'
  fi
done