#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
sudo tee /etc/apt/sources.list.d/spotify.sources > /dev/null <<EOF
Types: deb
URIs: https://repository.spotify.com/
Suites: stable
Components: non-free
Signed-By: /etc/apt/trusted.gpg.d/spotify.gpg
EOF
sudo apt -y --force-yes update && sudo apt -y --force-yes install spotify-client
sudo cp ${scrDir}/../.debian/spotify.desktop /usr/share/applications
