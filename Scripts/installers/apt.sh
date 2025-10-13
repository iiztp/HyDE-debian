#!/usr/bin/env bash

name=$1
opt=$2

sudo apt install -y ${opt} --force-yes "${name}" &>/dev/null
