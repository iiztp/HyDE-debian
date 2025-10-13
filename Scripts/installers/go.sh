#!/usr/bin/env bash

name=$1
link=$2
version=$3

go install $2@$3
