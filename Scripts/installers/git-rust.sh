#!/usr/bin/env bash

name=$1
link=$2
version=$3

if [ ! -d "${name}" ] ; then
    git clone --depth 1 --branch ${version} --recursive ${link} ${name}
fi

cd "${name}"

cargo build --release

sudo cp ./target/release/* /usr/bin

cd ..
