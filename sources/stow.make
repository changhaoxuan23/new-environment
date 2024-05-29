#!/bin/bash

set -e
base="$(dirname "$0")"
base="$(realpath --canonicalize-existing "${base}/..")"

package="stow"

cleanup(){
  rm -rf "${base}/${package}.build"
  rm -rf "${base}/${package}.new"
}

trap cleanup EXIT

mkdir -p "${base}/${package}.build"
cd "${base}/${package}.build"
if [ -n "${SILENT}" ];then
  curl --silent --fail --output stow.tar.bz2 'https://ftp.gnu.org/gnu/stow/stow-latest.tar.bz2'
  tar xf stow.tar.bz2
else
  curl --fail --output stow.tar.bz2 'https://ftp.gnu.org/gnu/stow/stow-latest.tar.bz2'
  tar xvf stow.tar.bz2
fi
rm -f stow.tar.bz2
source_directory="$(ls | grep stow-)"
mapfile -d '.' -t new_version < <(echo -n "${source_directory}" | cut -d '-' -f 2)
if [ -f "${base}/${package}.version" ];then
  mapfile -d '.' -t old_version < "${base}/${package}.version"
  new_code=$((new_version[0]*1000000+new_version[1]*1000+new_version[2]))
  old_code=$((old_version[0]*1000000+old_version[1]*1000+old_version[2]))
  if [ new_code -le old_code ];then
    printf -- '%s: up to date\n' "${package}"
    exit
  fi
fi

cd "${source_directory}"
if [ -n "${SILENT}" ];then
  ./configure --prefix="${base}/${package}" > /dev/null
  make -j > /dev/null
  make DESTDIR="${base}/${package}.new" install > /dev/null
else
  ./configure --prefix="${base}/${package}"
  make -j
  make DESTDIR="${base}/${package}.new" install
fi
if [ -f "${base}/${package}.version" ];then
  stow --dir="${base}" --target=/data1/nenv --delete "${package}"
  rm -rf "${base}/${package}"
fi
mv "${base}/${package}.new${base}/${package}" "${base}/${package}"
"${base}/${package}/bin/stow" --dir="${base}" --target=/data1/nenv --stow "${package}"
printf '%s: installed %s.%s.%s\n' "${package}" "${new_version[0]}" "${new_version[1]}" "${new_version[2]}"
printf '%s.%s.%s' "${new_version[0]}" "${new_version[1]}" "${new_version[2]}" > "${base}/${package}.version"
