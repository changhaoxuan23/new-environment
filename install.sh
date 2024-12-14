#!/bin/bash
set -e

show-help(){
  printf -- 'Usage: install.sh [<export-directory> <install-directory>]\n'
  printf -- '  <export-directory>  is the directory to be used by everyone on the same machine, like /\n'
  printf -- '  <install-directory> is where packages are actually installed and managed by you\n'
  printf -- ' If there is an instance of new environment installed and activated, it can be detected and\n'
  printf -- '  updated automatically by a plain install.sh\n'
}
die(){
  log-red 'Error: %s\n' "$1"
  show-help
  exit 1
}
# make sure directory pointed by path stored in $1 exists and is empty after this function returns
#  This is done by creating the directory if such entry does not exist
#   otherwise, check if the existing entry is an empty director
#  if any of these steps failed, the corresponding error will be reported and this install program
#   shall be terminated. DO NOT remove the directory.
ensure-directory(){
  if [ ! -e "$1" ];then
    if ! install --directory --mode=755 "$1";then
      die "failed to mkdir $1"
    fi
    return
  fi
  if [ ! -d "$1" ];then
    die "$1 exists and is not a directory"
  fi
  if [ ! -w "$1" ];then
    die "$1 exists but you have no write permission to it"
  fi
  if [ -n "$(ls --almost-all "$1")" ];then
    die "$1 is not empty"
  fi
}

# ==================================================
# --------------- start of execution ---------------
# ==================================================

# setup helpers
source_directory="$(dirname "$0")"
# shellcheck source=sources/helpers/io
source "${source_directory}/sources/helpers/io"

# decide where shall we install the instance, namely export_directory and install_directory
if [ $# -eq 0 ];then
  ## if this script is invoked without any argument, assume the user is trying to update an existing instance
  ##  we will find the location of installed instance via exported commands
  if {
    type new-environment-get-export-directory && type new-environment-get-install-directory
  } >/dev/null 2>&1;then
    export_directory="$(new-environment-get-export-directory)"
    install_directory="$(new-environment-get-install-directory)"
    log-cyan 'Updating installed environment...\n'
    printf 'export directory: '
    log-cyan '%s\n' "${export_directory}"
    printf 'install directory:'
    log-cyan '%s\n' "${install_directory}"
  else
    die 'no installed environment detected, cannot update'
  fi
elif [ $# -eq 2 ];then
  ## if this script is invoked with two arguments, assume a new installation
  new_install=true
  log-cyan  'Installing a new instance...\n'
  printf -- '  If you are a privileged user, you should not provide updated softwares by this way.\n'
  printf -- '   Do that by updating packages directly,  updating the whole system, or switching to\n'
  printf -- '   some other distributor that provides up-to-date packages.  Of course you *CAN* use\n'
  printf -- '   this set of tools, but be aware that we have disabled certain features in packages\n'
  printf -- '   since we assume our users being unprivileged, for example set-user-id binaries, so\n'
  printf -- '   you will notice missing features in some packages.                                \n'

  ## use these arguments directly but in canonicalized form
  export_directory="$(realpath --canonicalize-missing "$1")"
  install_directory="$(realpath --canonicalize-missing "$2")"
  ensure-directory "${export_directory}"
  ensure-directory "${install_directory}"
  printf -- 'Export directory: %s\n' "${export_directory}"
  printf -- 'Install directory: %s\n' "${install_directory}"
  if ! confirm "Is that correct?";then exit;fi
else
  die 'invalid usage'
fi

# install all files
## remove all installed scripts
rm --force --recursive "${install_directory}/scripts"

## copy new scripts into install directory
cp --recursive --no-dereference "${source_directory}/sources" "${install_directory}/scripts"

## install new README of the exported directory, which is also the activator of nenv
cp --force "${source_directory}/activator" "${export_directory}/README"

## inject all hardcoded paths
replacer="s|__\{\{export_directory\}\}__|${export_directory}|g;s|__\{\{install_directory\}\}__|${install_directory}|g"
### inject into the activator, which is the only file have to be modified in export directory
sed -E --in-place "${replacer}" "${export_directory}/README"
### inject into scripts
find "${install_directory}/scripts" -type f -exec sed -E --in-place "${replacer}" '{}' ';'

## set proper mode bits for all installed scripts
### README shall be invocable for anyone
chmod 555 "${export_directory}/README"
### ${install_directory}/scripts/*.make shall be invocable only for the user installing it
chmod 500 "${install_directory}/scripts/"*.make
### ${install_directory}/scripts/common/* shall not be invoked directly
chmod 400 "${install_directory}/scripts/common/"*
### ${install_directory}/scripts/meta/* shall be invocable only for the user installing it
chmod 500 "${install_directory}/scripts/meta/"*
### ${install_directory}/scripts/helpers/** shall not be invoked directly
find "${install_directory}/scripts/helpers" -type f -exec chmod 400 '{}' '+'

## install meta files and directories required in the export directory
### news and comments goes to ${export_directory}/.meta, which shall be writable for all users with
###  but along with an sticky bit
install --directory --mode=1777 "${export_directory}/.meta"

### we will install the newly introduced nenv-makepkg driver into exported directory
install --directory --mode=0755 "${export_directory}/bin"
ln --symbolic --force "${install_directory}/scripts/meta/nenv-makepkg" "${export_directory}/bin/nenv-makepkg"


log-green 'Done. You can now run scripts to install packages\n'

# if we are updating an instance, we are done
if [ -z "${new_install}" ] || [ "${new_install}" != 'true' ];then
  exit
fi

# otherwise if we are installing a new instance, we need to help our user to get started
alias p=printf
alias lc=log-cyan
lc 'Before you start, something to note:\n'
p  '1. Read %s first.\n' "${export_directory}/README"
p  '2. Deactivate any virtual environment before building and installing packages.\n'
p  '3. Use %s to install all packages\n' "${install_directory}/scripts/meta/install.sh"
p  '    For now this script does not really install all available packages, and errors are expected.       \n'
p  '    Since installing all packages is not a rational task, this script is now deprecated and will       \n'
p  '     hardly receive updates.                                                                           \n'
p  '    However, it still gives an illustration on how to install packages (in the legacy way).            \n'
p  '    Generally speaking, you should start with installing stow since which is required by nenv.         \n'
p  '4. Systems can have very different setup, pull requests are welcomed if you found something not working\n'
p  '5. To update scripts, update the repository then invoke ./install.sh without arguments.                \n'
p  '6. !! Modifications to scripts will be overwritten while updating !!                                   \n'
p '     If modifications are required to get things work, do not forget to make a pull request.            \n'
p '     Keep new scripts for packages in a separate directory.                                             \n'
p '      A compiling script should work regardless where it is. Read package-scripting for specification.  \n'
p '      Please consider sharing the script: other users may find it useful. Thank you for your kindness.  \n'