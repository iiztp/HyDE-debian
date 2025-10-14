#!/usr/bin/env bash
#|---/ /+-------------------------------------+---/ /|#
#|--/ /-| Script to apply pre install configs |--/ /-|#
#|-/ /--| Prasanth Rangan                     |-/ /--|#
#|/ /---+-------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}

# grub
if pkg_installed grub-common && [ -f /boot/grub/grub.cfg ]; then
    print_log -sec "bootloader" -b "detected :: " "grub..."

    if [ ! -f /etc/default/grub.hyde.bkp ] && [ ! -f /boot/grub/grub.hyde.bkp ]; then
        [ "${flg_DryRun}" -eq 1 ] || sudo cp /etc/default/grub /etc/default/grub.hyde.bkp
        [ "${flg_DryRun}" -eq 1 ] || sudo cp /boot/grub/grub.cfg /boot/grub/grub.hyde.bkp

        # Only if the nvidia installation doesn't skip
        if nvidia_detect; then
            if [ ${flg_Nvidia} -eq 1 ]; then
                print_log -g "[bootloader] " -b "configure :: " "nvidia detected, adding nvidia_drm.modeset=1 to boot option..."
                gcld=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "/etc/default/grub" | cut -d'"' -f2 | sed 's/\b nvidia_drm.modeset=.\b//g')
                [ "${flg_DryRun}" -eq 1 ] || sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"${gcld} nvidia_drm.modeset=1\"" /etc/default/grub
            else
                print_log -g "[bootloader] " -b "skip :: " "nvidia detected, skipping nvidia_drm.modeset=1 to boot option..."
            fi
        fi

        print_log -g "[bootloader] " "Select grub theme:" -y "\n[1]" -y " Retroboot (dark)" -y "\n[2]" -y " Pochita (light)"
        read -r -p " :: Press enter to skip grub theme <or> Enter option number : " grubopt
        case ${grubopt} in
        1) grubtheme="Retroboot" ;;
        2) grubtheme="Pochita" ;;
        *) grubtheme="None" ;;
        esac

        if [ "${grubtheme}" == "None" ]; then
            print_log -g "[bootloader] " -b "skip :: " "grub theme selection skipped..."
            echo ""
        else
            print_log -g "[bootloader] " -b "set :: " "grub theme // ${grubtheme}"
            echo ""
            # shellcheck disable=SC2154
            sudo mkdir -p /usr/share/grub/themes/
            [ "${flg_DryRun}" -eq 1 ] || sudo tar -xzf "${cloneDir}/Source/arcs/Grub_${grubtheme}.tar.gz" -C /usr/share/grub/themes/
            grubfile="/etc/default/grub"
            # Update or add GRUB_DEFAULT
            if grep -q '^GRUB_DEFAULT=' $grubfile; then
                sudo sed -i 's|^GRUB_DEFAULT=.*|GRUB_DEFAULT=saved|' $grubfile
            else
                echo 'GRUB_DEFAULT=saved' | sudo tee -a $grubfile
            fi

            # Update or add GRUB_GFXMODE
            if grep -q '^GRUB_GFXMODE=' $grubfile; then
                sudo sed -i 's|^GRUB_GFXMODE=.*|GRUB_GFXMODE=1280x1024x32,auto|' $grubfile
            else
                echo 'GRUB_GFXMODE=1280x1024x32,auto' | sudo tee -a $grubfile
            fi

            # Update or add GRUB_THEME
            if grep -q '^GRUB_THEME=' $grubfile; then
                sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"|" $grubfile
            else
                echo "GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"" | sudo tee -a $grubfile
            fi

            # Update or add GRUB_SAVEDEFAULT
            if grep -q '^GRUB_SAVEDEFAULT=' $grubfile; then
                sudo sed -i 's|^GRUB_SAVEDEFAULT=.*|GRUB_SAVEDEFAULT=true|' $grubfile
            else
                echo 'GRUB_SAVEDEFAULT=true' | sudo tee -a $grubfile
            fi

            # Finally, update grub
            sudo update-grub
            [ "${flg_DryRun}" -eq 1 ] || sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi

    else
        print_log -y "[bootloader] " -b "exist :: " "grub is already configured..."
    fi
fi

# systemd-boot
if pkg_installed systemd && nvidia_detect && [ "$(bootctl status 2>/dev/null | awk '{if ($1 == "Product:") print $2}')" == "systemd-boot" ]; then
    print_log -sec "bootloader" -stat "detected" "systemd-boot"

    if [ "$(find /boot/loader/entries/ -type f -name '*.conf.hyde.bkp' 2>/dev/null | wc -l)" -ne "$(find /boot/loader/entries/ -type f -name '*.conf' 2>/dev/null | wc -l)" ]; then
        print_log -g "[bootloader] " -b " :: " "nvidia detected, adding nvidia_drm.modeset=1 to boot option..."
        if [[ "${flg_DryRun}" -ne 1 ]]; then
            find /boot/loader/entries/ -type f -name "*.conf" | while read -r imgconf; do
                sudo cp "${imgconf}" "${imgconf}.hyde.bkp"
                sdopt=$(grep -w "^options" "${imgconf}" | sed 's/\b quiet\b//g' | sed 's/\b splash\b//g' | sed 's/\b nvidia_drm.modeset=.\b//g')
                sudo sed -i "/^options/c${sdopt} quiet splash nvidia_drm.modeset=1" "${imgconf}"
            done
        fi
    else
        print_log -y "[bootloader] " -stat "skipped" "systemd-boot is already configured..."
    fi
fi
