#!/usr/bin/env bash

curl -L https://risczero.com/install | bash
export PATH="$HOME/.risc0/bin:$PATH"
rzup install
