#!/bin/bash
set -e
source "$(dirname "$0")/sources/common/utility"
show-help(){
  printf -- 'Usage: install.sh [<export-directory> <install-directory>]\n'
  printf -- '  <export-directory>  is the directory to be used by everyone on the same machine, like /\n'
  printf -- '  <install-directory> is where packages are actually installed and managed by you\n'
  printf -- ' If there is an instance of new environment installed and activated, it can be detected and\n'
  printf -- '  updated automatically by a plain install.sh\n'
}
die(){
  printf -- '\x1b[1;31mError: %s\x1b[0m\n' "$1"
  show-help
  exit 1
}
ensure-directory(){
  if [ ! -e "$1" ];then
    if ! mkdir --mode=755 --parents "$1";then
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
  if [ "$(ls --almost-all "$1" | wc --lines)" -ne 0 ];then
    die "$1 is not empty"
  fi
}
if [ $# -eq 0 ];then
  if {
    type new-environment-get-export-directory && type new-environment-get-install-directory
  } >/dev/null 2>&1;then
    export_directory="$(new-environment-get-export-directory)"
    install_directory="$(new-environment-get-install-directory)"
    printf -- '\x1b[1;36mUpdating installed environment...\x1b[0m\n'
    printf -- 'export directory: \x1b[1;36m%s\x1b[0m\n' "${export_directory}"
    printf -- 'install directory: \x1b[1;36m%s\x1b[0m\n' "${install_directory}"
  else
    die 'no installed environment detected, cannot update'
  fi
elif [ $# -eq 2 ];then
  new_install=true
  printf -- '\x1b[1;36mInstalling a new instance...\x1b[0m\n'
  printf -- '  If you are a privileged user, you should not provide updated softwares by this way.\n'
  printf -- '   Do that by updating packages directly, updating the whole system, or switching to \n'
  printf -- '   some other distributor that provides up-to-date packages. Of course you *CAN* use \n'
  printf -- '   this set of tools, but be aware that we have disabled certain features in packages\n'
  printf -- '   since we assume our users being unprivileged, for example set-user-id binaries, so\n'
  printf -- '   you will notice missing features in some packages.\n'
  export_directory="$1"
  install_directory="$2"
  ensure-directory "${export_directory}"
  ensure-directory "${install_directory}"
  export_directory="$(realpath --canonicalize-existing "${export_directory}")"
  install_directory="$(realpath --canonicalize-existing "${install_directory}")"
  printf -- 'Export directory: %s\n' "${export_directory}"
  printf -- 'Install directory: %s\n' "${install_directory}"
  if ! confirm "Is that correct?";then exit;fi
else
  die 'invalid usage'
fi
source_directory="$(dirname "$0")"
rm --force --recursive "${install_directory}/scripts"
cp --recursive --no-dereference "${source_directory}/sources" "${install_directory}/scripts"
cp --force "${source_directory}/activator" "${export_directory}/README"
sed -E --in-place "s|__\{\{export_directory\}\}__|${export_directory}|g" \
                  "${install_directory}/scripts/common/prepare-execution-environment" \
                  "${install_directory}/scripts/common/nenv-makepkg" \
                  "${install_directory}/scripts/meta/install.sh" \
                  "${export_directory}/README"
sed -E --in-place "s|__\{\{install_directory\}\}__|${install_directory}|g" \
                  "${install_directory}/scripts/common/prepare-execution-environment" \
                  "${install_directory}/scripts/common/nenv-makepkg" \
                  "${install_directory}/scripts/meta/install.sh" \
                  "${export_directory}/README"
chmod 555 "${export_directory}/README"
chmod 500 "${install_directory}/scripts/"*.make \
          "${install_directory}/scripts/common/"* \
          "${install_directory}/scripts/meta/"*
install --directory --mode=1777 "${export_directory}/.meta"
install --directory --mode=0755 "${export_directory}/bin"
ln --symbolic "${install_directory}/scripts/common/nenv-makepkg" "${export_directory}/bin/nenv-makepkg"
printf -- '\x1b[1;32mDone. You can now run scripts to install packages\x1b[0m\n'
if [ -z "${new_install}" ] || [ "${new_install}" != 'true' ];then
  exit
fi
pl(){
  if [ -z "${list_counter}" ];then
    list_counter=1
  fi
  printf "\e[1;36m  ${list_counter}. \e[0m$@"
  list_counter=$((list_counter+1))
}
p(){
  printf -- "$@"
}
printf '\e[1;36mBefore you start, something to note:\e[0m\n'
pl 'Read %s first.\n' "${export_directory}/README"
pl 'Deactivate any virtual environment before building and installing packages.\n'
pl 'Use %s to install all packages\n' "${install_directory}/scripts/meta/install.sh"
pl 'Systems can have very different setup, pull requests are welcomed if you found something not working\n'
pl 'To update scripts, update the repository then invoke install.sh without arguments.\n'
pl 'Modifications to scripts will be overwritten while updating.\n'
p '      If modifications are required to get things work, do not forget to make a pull request.\n'
p '      Keep new scripts for packages in a separate directory.\n'
p '       A compiling script should work regardless where it is. Read package-scripting for specification.\n'
p '       Please consider sharing the script: other users may find it useful. Thank you for your kindness.\n'