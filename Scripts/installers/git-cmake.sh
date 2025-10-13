#!/usr/bin/env bash

name=$1
link=$2
version=$3

if [ ! -d "${name}" ] ; then
    git clone --depth 1 --branch ${version} --recursive ${link} ${name}
fi

cd "${name}"

cmake -DCMAKE_INSTALL_PREFIX=/usr -B build
cmake --build build -j`nproc`
sudo cmake --install build

cd ..
