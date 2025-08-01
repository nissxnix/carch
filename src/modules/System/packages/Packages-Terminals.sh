#!/usr/bin/env bash

install_terminals() {
    detect_distro
    distro=$?

    if [[ $distro -eq 0 ]]; then
        install_aur_helper
        pkg_manager="sudo pacman -S --noconfirm"
        pkg_manager_aur="$AUR_HELPER -S --noconfirm"
        get_version() { pacman -Qi "$1" | grep Version | awk '{print $3}'; }
    elif [[ $distro -eq 1 ]]; then
        install_flatpak
        pkg_manager="sudo dnf install -y"
        flatpak_cmd="flatpak install -y --noninteractive flathub"
        get_version() { rpm -q "$1"; }
    elif [[ $distro -eq 2 ]]; then
        pkg_manager="sudo zypper install -y"
        get_version() { rpm -q "$1"; }
    else
        echo -e "${RED}:: Unsupported distribution. Exiting.${NC}"
        return
    fi

    while true; do
        clear
        local options=("Alacritty" "Kitty" "St" "Terminator" "Tilix" "Hyper" "GNOME Terminal" "Konsole" "WezTerm" "Ghostty" "Back to Main Menu")

        show_menu "Terminals Installation" "${options[@]}"
        get_choice "${#options[@]}"
        local choice_index=$?
        local selection="${options[$((choice_index - 1))]}"

        case "$selection" in
            "Alacritty")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager alacritty
                elif [[ $distro -eq 1 ]]; then
                    $pkg_manager alacritty
                else
                    $pkg_manager alacritty
                fi
                version=$(get_version alacritty)
                echo "Alacritty installed successfully! Version: $version"
                ;;

            "Kitty")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager kitty
                elif [[ $distro -eq 1 ]]; then
                    $pkg_manager kitty
                else
                    $pkg_manager kitty
                fi
                version=$(get_version kitty)
                echo "Kitty installed successfully! Version: $version"
                ;;

            "St")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager_aur st
                    version=$(get_version st)
                elif [[ $distro -eq 1 ]]; then
                    $pkg_manager st
                    version=$(get_version st)
                else
                    $pkg_manager st
                    version=$(get_version st)
                fi
                echo "St Terminal installed successfully! Version: $version"
                ;;

            "Terminator")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager_aur terminator
                    version=$(get_version terminator)
                elif [[ $distro -eq 1 ]]; then
                    $pkg_manager terminator
                    version=$(get_version terminator)
                else
                    $pkg_manager terminator
                    version=$(get_version terminator)
                fi
                echo "Terminator installed successfully! Version: $version"
                ;;

            "Tilix")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager_aur tilix
                    version=$(get_version tilix)
                elif [[ $distro -eq 1 ]]; then
                    $pkg_manager tilix
                    version=$(get_version tilix)
                else
                    $pkg_manager tilix
                    version=$(get_version tilix)
                fi
                echo "Tilix installed successfully! Version: $version"
                ;;

            "Hyper")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager_aur hyper
                    version=$(get_version hyper)
                    echo "Hyper installed successfully! Version: $version"
                elif [[ $distro -eq 1 ]]; then
                    echo ":: Downloading Hyper RPM for Fedora..."
                    cd /tmp || exit
                    wget -O hyper-3.4.1.x86_64.rpm https://github.com/vercel/hyper/releases/download/v3.4.1/hyper-3.4.1.x86_64.rpm
                    if [[ $? -eq 0 ]]; then
                        sudo dnf install -y hyper-3.4.1.x86_64.rpm
                        version=$(get_version hyper)
                        echo "Hyper installed successfully! Version: $version"
                        rm -f hyper-3.4.1.x86_64.rpm
                    else
                        echo -e "${RED}!! Failed to download Hyper RPM.${NC}"
                    fi
                else
                    echo ":: Downloading Hyper RPM for OpenSUSE..."
                    cd /tmp || exit
                    wget -O hyper-3.4.1.x86_64.rpm https://github.com/vercel/hyper/releases/download/v3.4.1/hyper-3.4.1.x86_64.rpm
                    if [[ $? -eq 0 ]]; then
                        sudo zypper install -y hyper-3.4.1.x86_64.rpm
                        version=$(get_version hyper)
                        echo "Hyper installed successfully! Version: $version"
                        rm -f hyper-3.4.1.x86_64.rpm
                    else
                        echo -e "${RED}!! Failed to download Hyper RPM.${NC}"
                    fi
                fi
                ;;

            "GNOME Terminal")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager gnome-terminal
                elif [[ $distro -eq 1 ]]; then
                    $pkg_manager gnome-terminal
                else
                    $pkg_manager gnome-terminal
                fi
                version=$(get_version gnome-terminal)
                echo "GNOME Terminal installed successfully! Version: $version"
                ;;

            "Konsole")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager konsole
                elif [[ $distro -eq 1 ]]; then
                    $pkg_manager konsole
                else
                    $pkg_manager konsole
                fi
                version=$(get_version konsole)
                echo "Konsole installed successfully! Version: $version"
                ;;

            "WezTerm")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager wezterm
                    version=$(get_version wezterm)
                    echo "WezTerm installed successfully! Version: $version"
                elif [[ $distro -eq 1 ]]; then
                    if sudo dnf list --installed wezterm &> /dev/null; then
                        version=$(get_version wezterm)
                        echo "WezTerm is already installed! Version: $version"
                    else
                        $flatpak_cmd org.wezfurlong.wezterm
                        version="(Flatpak version installed)"
                        echo "WezTerm installed successfully! Version: $version"
                    fi
                else
                    if sudo zypper se -i wezterm &> /dev/null; then
                        version=$(get_version wezterm)
                        echo "WezTerm is already installed! Version: $version"
                    else
                        sudo zypper install -y wezterm
                        version=$(get_version wezterm)
                        echo "WezTerm installed successfully! Version: $version"
                    fi
                fi
                ;;

            "Ghostty")
                clear
                if [[ $distro -eq 0 ]]; then
                    $pkg_manager ghostty
                elif [[ $distro -eq 1 ]]; then
                    sudo dnf copr enable pgdev/ghostty -y
                    sudo dnf install -y ghostty
                else
                    $pkg_manager ghostty
                fi
                version=$(get_version ghostty)
                echo "Ghostty installed successfully! Version: $version"
                ;;
            "Back to Main Menu")
                return
                ;;
        esac
        read -p "$(printf "\n%bPress Enter to continue...%b" "$GREEN" "$NC")"
    done
}
