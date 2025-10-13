#!/usr/bin/env bash

name=$1
link=$2
version=$3

if [ ! -d "${name}" ] ; then
    git clone --depth 1 --recursive ${link} ${name}
fi

cd "${name}"
git checkout ${version}

meson build
ninja -C build
sudo ninja -C build install

cd ..
