#!/usr/bin/env bash

name=$1
link=$2
version=$3

if [ ! -d "${name}" ] ; then
    git clone --depth 1 --branch ${version} --recursive ${link} ${name}
fi

cd "${name}"
git checkout ${version}

make build
sudo source "$HOME/.cargo/env" && sudo make install

cd ..
