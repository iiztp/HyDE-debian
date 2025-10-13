#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091
#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install pkgs from input list |--/ /-|#
#|-/ /--| Prasanth Rangan                        |-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

install_from_list() {
    local listPkg="$1"
    while read -r pkg; do
        pkg="${pkg// /}"
        if [[ -z "${pkg}" ]]; then
            continue
        fi
        if pkg_installed "${pkg}"; then
            echo -e "\033[0;33m[skip]\033[0m ${pkg} is already installed..."
        elif pkg_available "${pkg}"; then
            echo -e "\033[0;32m[o]\033[0m Installing ${pkg} from official debian repo..."
            sudo apt install -y --force-yes "${pkg}" &>/dev/null
        else
            echo "Error: unknown package ${pkg}..."
        fi
    done < <(cut -d '#' -f 1 "${listPkg}")
}

# Install dependencies and softwares
echo -e "\033[0;31mNote: Installing with APT in CLI is at risks, be sure you know what you do before continuing.\033[0m You can install the packages manually and go back to this script if needed."
read -p " :: Press y to continue : " aptwarning
case ${aptwarning} in
    y) ;;
    *) exit ;;
esac

listPkg="${scrDir}/pkg_deps.lst"
echo ""
echo -e "\033[0;35m[o]\033[0m Installing dependencies..."
echo ""
install_from_list $listPkg

listPkg="${scrDir}/pkg_core.lst"
echo ""
echo -e "\033[0;35m[o]\033[0m Installing core packages..."
echo ""
install_from_list $listPkg

# Installing Rust
if ! pkg_installed "rustup"; then
    echo -e "\033[0;35m[o]\033[0m Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
else
    echo -e "\033[0;33m[skip]\033[0m Rust is already installed..."
fi

IFS=${ofs}

# Install git packages
listPkg="${1:-"${scrDir}/pkg_wm.lst"}"
while read -r input; do
    input="${input// /}"
    if [ -z "${input}" ]; then
        continue
    fi

    name=$(echo "$input" | cut -d':' -f1)
    script=$(echo "$input" | cut -d':' -f2-)
    version=$(echo "$input" | cut -d':' -f3-)
    argument=$(echo "$input" | cut -d':' -f4-)

    echo -e "\033[0;32m[o]\033[0m Installing manually ${name} with ${script}..."
    ./installers/${script}.sh ${name} ${argument} ${version}
done < <(cut -d '#' -f 1 "${listPkg}")

# Install extra
listPkg="${1:-"${scrDir}/pkg_extra.lst"}"
while read -r input; do
    input="${input// /}"
    if [ -z "${input}" ]; then
        continue
    fi
    echo -e "\033[0;32m[o]\033[0m Installing ${input} from script..."
    ./extra/${input}.sh
done < <(cut -d '#' -f 1 "${listPkg}")
