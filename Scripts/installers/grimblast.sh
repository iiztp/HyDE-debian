#!/usr/bin/env bash

name=$1
link=$2
version=$3

if [ ! -d "${name}" ] ; then
    git clone --depth 1 --branch ${version} --recursive ${link} ${name}
fi

cd "${name}"
git checkout ${version}
cd grimblast

make all
sudo make install

cd ..
cd ..
