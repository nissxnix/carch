#!/usr/bin/env bash

clear

source "$(dirname "$0")/../colors.sh" > /dev/null 2>&1

print_message() {
    local color="$1"
    local message="$2"
    printf "%b%s%b\n" "$color" "$message" "$RC"
}

confirm() {
    while true; do
        read -p "$(printf "%b%s%b" "$CYAN" "$1 [y/N]: " "$RC")" answer
        case ${answer,,} in
            y | yes) return 0 ;;
            n | no | "") return 1 ;;
            *) print_message "$YELLOW" "Please answer with y/yes or n/no." ;;
        esac
    done
}

detect_distro() {
    if command -v pacman &> /dev/null; then
        distro="arch"
        print_message "$GREEN" "Detected distribution: Arch Linux"
    elif command -v dnf &> /dev/null; then
        distro="fedora"
        print_message "$YELLOW" "Detected distribution: Fedora"
    elif command -v zypper &> /dev/null; then
        distro="opensuse"
        print_message "$YELLOW" "Detected distribution: opensuse"
    else
        print_message "$RED" "Unsupported distribution. Exiting..."
        exit 1
    fi
}

install_packages() {
    if [ "$distro" == "arch" ]; then
        check_aur_helper
        print_message "$CYAN" ":: Installing required packages using pacman and AUR..."

        sudo pacman -S --needed git base-devel libx11 libxinerama libxft gnome-keyring ttf-cascadia-mono-nerd \
            ttf-cascadia-code-nerd ttf-jetbrains-mono-nerd ttf-jetbrains-mono imlib2 libxcb git unzip lxappearance \
            feh mate-polkit meson ninja xorg-xinit xorg-server network-manager-applet blueman pasystray bluez-utils \
            thunar flameshot trash-cli tumbler fzf gvfs-mtp vim neovim slock nwg-look swappy kvantum \
            gtk3 gtk4 qt5ct qt6ct man man-db pamixer pavucontrol pavucontrol-qt ffmpeg ffmpegthumbnailer yazi || {
            print_message "$RED" "Failed to install some packages via pacman."
            exit 1
        }

        print_message "$CYAN" ":: Installing xautolock from AUR..."
        $aur_helper -S --noconfirm xautolock || {
            print_message "$RED" "Failed to install xautolock from AUR."
            exit 1
        }

    elif [ "$distro" == "fedora" ]; then
        print_message "$CYAN" ":: Installing required packages using dnf..."

        print_message "$CYAN" ":: Enabling RPM Fusion repositories..."
        sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm \
                            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm || {
            print_message "$RED" "Failed to enable RPM Fusion repositories."
            exit 1
        }

        print_message "$CYAN" ":: Enabling lihaohong/yazi COPR repository..."
        sudo dnf copr enable -y lihaohong/yazi || {
            print_message "$RED" "Failed to enable lihaohong/yazi COPR repository."
            exit 1
        }

        sudo dnf install -y git libX11-devel libXinerama-devel libXft-devel imlib2-devel libxcb-devel \
            gnome-keyring unzip lxappearance feh mate-polkit meson ninja-build jetbrains-mono-fonts-all \
            google-noto-color-emoji-fonts network-manager-applet blueman pasystray google-noto-emoji-fonts thunar flameshot \
            trash-cli tumbler fzf gvfs-mtp vim neovim slock nwg-look swappy kvantum gtk3 gtk4 qt5ct qt6ct man man-db pamixer \
            pavucontrol pavucontrol-qt ffmpeg-devel ffmpegthumbnailer yazi xautolock || {
            print_message "$RED" "Failed to install some packages via dnf."
            exit 1
        }

    elif [ "$distro" == "opensuse" ]; then
        print_message "$CYAN" ":: Installing required packages using zypper..."

        sudo zypper install -y libX11-devel libXinerama-devel libXft-devel imlib2-devel libxcb-devel \
            gnome-keyring unzip lxappearance feh mate-polkit meson ninja jetbrains-mono-fonts \
            google-noto-fonts noto-coloremoji-fonts NetworkManager-applet blueman pasystray thunar flameshot \
            trash-cli tumbler mtp-tools fzf vim neovim i3lock nwg-look swappy kvantum-manager libgtk-3-0 libgtk-4-1 qt5ct qt6ct man man-pages pamixer \
            pavucontrol pavucontrol-qt ffmpeg-7 ffmpegthumbnailer yazi xautolock || {
            print_message "${RED}" "Failed to install some packages via zypper."
            exit 1
        }

        print_message "$YELLOW" "NOTE: openSUSE uses i3lock instead of slock (slock is not available in official repositories)."
        print_message "$YELLOW" "To manually lock your screen, run: i3lock"
    fi
}

check_aur_helper() {
    if command -v paru &> /dev/null; then
        print_message "$GREEN" "AUR helper paru is already installed."
        aur_helper="paru"
        return 0
    elif command -v yay &> /dev/null; then
        print_message "$GREEN" "AUR helper yay is already installed."
        aur_helper="yay"
        return 0
    fi

    print_message "$CYAN" ":: No AUR helper found. Installing yay..."

    sudo pacman -S --needed --noconfirm git base-devel

    local temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1

    if git clone https://aur.archlinux.org/yay.git; then
        cd yay || exit 1
        makepkg -si --noconfirm || {
            print_message "$RED" "Failed to install yay."
            cd "$HOME" || exit
            rm -rf "$temp_dir"
            exit 1
        }
        cd "$HOME" || exit
        rm -rf "$temp_dir"
        aur_helper="yay"
        print_message "$GREEN" "Successfully installed yay as AUR helper."
        return 0
    else
        print_message "$RED" "Failed to clone yay repository."
        cd "$HOME" || exit
        rm -rf "$temp_dir"
        exit 1
    fi
}

install_dwm() {
    if [ -d "$HOME/dwm" ]; then
        if confirm "DWM directory already exists. Do you want to overwrite it?"; then
            rm -rf "$HOME/dwm"
        else
            print_message "$YELLOW" "Skipping DWM installation."
            return
        fi
    fi

    print_message "$CYAN" "Cloning DWM repository..."
    git clone https://github.com/harilvfs/dwm.git "$HOME/dwm" || exit 1
    cd "$HOME/dwm" || exit 1
    sudo make clean install || exit 1
    print_message "$GREEN" "DWM installed successfully!"
}

install_slstatus() {
    print_message "$CYAN" ":: Installing slstatus..."
    if confirm "Do you want to install slstatus (recommended)?"; then
        cd "$HOME/dwm/slstatus" || exit 1
        sudo make clean install || exit 1
        print_message "$GREEN" "slstatus installed successfully!"
    else
        print_message "$CYAN" "Skipping slstatus installation."
    fi
}

install_nerd_font() {
    local FONT_DIR="$HOME/.fonts"
    local FONT_NAME="MesloLGS NF Regular"
    mkdir -p "$FONT_DIR"

    if fc-list | grep -q "$FONT_NAME"; then
        print_message "$GREEN" "Meslo Nerd Font is already installed. Skipping..."
        return
    fi

    print_message "$CYAN" "Installing Meslo Nerd Font..."

    if command -v pacman &> /dev/null; then
        sudo pacman -S --needed ttf-meslo-nerd || exit 1

    elif command -v dnf &> /dev/null; then
        wget -P /tmp https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip || exit 1
        unzip /tmp/Meslo.zip -d /tmp/Meslo || exit 1
        mv /tmp/Meslo/* "$FONT_DIR" || exit 1

    elif command -v zypper &> /dev/null; then
        sudo zypper install -y meslo-lg-fonts || exit 1

    else
        print_message "$RED" "Unsupported package manager. Please install Meslo Nerd Font manually."
        return 1
    fi

    fc-cache -vf || exit 1
    print_message "$GREEN" "Nerd Fonts installed successfully!"
}

install_picom() {
    if [ "$distro" == "arch" ]; then
        check_aur_helper

        print_message "$CYAN" ":: Installing Picom with $aur_helper..."
        $aur_helper -S --noconfirm picom-ftlabs-git || {
            print_message "$RED" "Failed to install Picom via $aur_helper. Please install manually."
            exit 1
        }

    elif [ "$distro" == "fedora" ]; then
        print_message "$CYAN" ":: Installing Picom manually on Fedora..."
        sudo dnf install -y dbus-devel gcc git libconfig-devel libdrm-devel libev-devel \
            libX11-devel libX11-xcb libXext-devel libxcb-devel libGL-devel libEGL-devel \
            libepoxy-devel meson pcre2-devel pixman-devel uthash-devel \
            xcb-util-image-devel xcb-util-renderutil-devel xorg-x11-proto-devel xcb-util-devel

        git clone https://github.com/FT-Labs/picom.git "$HOME/picom"
        cd "$HOME/picom" || exit 1
        meson setup --buildtype=release build
        ninja -C build
        sudo cp build/src/picom /usr/bin/

    elif [ "$distro" == "opensuse" ]; then
        print_message "$CYAN" ":: Installing Picom manually on openSUSE..."
        sudo zypper install -y dbus-1-devel gcc git libconfig-devel libdrm-devel libev-devel \
            libX11-devel libXext-devel libxcb-devel Mesa-libGL-devel Mesa-libEGL1 \
            libepoxy-devel meson pcre2-devel libpixman-1-0-devel pkgconf uthash-devel cmake libev-devel \
            xcb-util-image-devel xcb-util-renderutil-devel xorg-x11-proto-devel xcb-util-devel

        git clone https://github.com/FT-Labs/picom.git "$HOME/picom"
        cd "$HOME/picom" || exit 1
        meson setup --buildtype=release build
        ninja -C build
        sudo cp build/src/picom /usr/bin/
    fi

    configure_picom
}

configure_picom() {
    local CONFIG_DIR="$HOME/.config"
    local DESTINATION="$CONFIG_DIR/picom.conf"
    local URL="https://raw.githubusercontent.com/harilvfs/dwm/refs/heads/main/config/picom/picom.conf"

    mkdir -p "$CONFIG_DIR"
    if [ -f "$DESTINATION" ]; then
        if confirm "Existing picom.conf detected. Do you want to replace it?"; then
            mv "$DESTINATION" "$DESTINATION.bak"
        else
            return
        fi
    fi

    wget -q -O "$DESTINATION" "$URL" || exit 1
    print_message "$GREEN" "Picom configuration updated."
}

configure_wallpapers() {
    local BG_DIR="$HOME/Pictures/wallpapers"
    mkdir -p "$HOME/Pictures"

    if [ -d "$BG_DIR" ]; then
        if confirm "Wallpapers directory already exists. Do you want to overwrite?"; then
            rm -rf "$BG_DIR"
        else
            return
        fi
    fi

    if confirm "Do you want to download wallpapers? (Note: The wallpaper collection is large in size but recommended)"; then
        print_message "$CYAN" ":: Downloading wallpapers..."
        git clone https://github.com/harilvfs/wallpapers "$BG_DIR" || exit 1
        print_message "$GREEN" "Wallpapers downloaded successfully."
    else
        print_message "$YELLOW" "Skipping wallpaper download."
    fi
}

setup_xinitrc() {
    local XINITRC="$HOME/.xinitrc"

    if [ -f "$XINITRC" ]; then
        if confirm "Existing .xinitrc detected. Do you want to replace it?"; then
            mv "$XINITRC" "$XINITRC.bak"
        else
            return
        fi
    fi

    print_message "$CYAN" ":: Creating .xinitrc file for DWM..."

    if [ "$distro" == "opensuse" ]; then
        cat > "$XINITRC" << 'EOF'
#!/bin/sh

pgrep dunst > /dev/null || /usr/bin/dunst &

xautolock \
  -time 10 \
  -locker i3lock \
  -notify 10 \
  -notifier "/usr/bin/notify-send '🔒 Locking soon' 'The screen will lock in 10 seconds...'" &

exec dwm
EOF
    else
        cat > "$XINITRC" << 'EOF'
#!/bin/sh

pgrep dunst > /dev/null || /usr/bin/dunst &

xautolock \
  -time 10 \
  -locker slock \
  -notify 10 \
  -notifier "/usr/bin/notify-send '🔒 Locking soon' 'The screen will lock in 10 seconds...'" &

exec dwm
EOF
    fi

    chmod +x "$XINITRC"
    print_message "$GREEN" ".xinitrc configured successfully!"
}

setup_tty_login() {
    if confirm "Do you want to use DWM from TTY using startx?"; then
        setup_xinitrc

        if confirm "Do you want to enable automatic login to TTY? (Not recommended for security reasons)"; then
            local username=$(whoami)
            print_message "$CYAN" ":: Setting up autologin for user: $username"

            sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/

            sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $username --noclear %I 38400 linux
EOF

            sudo systemctl daemon-reexec
            print_message "$GREEN" "Autologin configured for TTY1."
        fi
    fi
}

check_display_manager() {
    local dm_found=false
    local dm_name=""

    for dm in sddm gdm lightdm lxdm xdm slim greetd; do
        if systemctl is-enabled $dm.service &> /dev/null; then
            dm_found=true
            dm_name=$dm
            break
        fi
    done

    if $dm_found; then
        print_message "$YELLOW" "Display manager $dm_name is detected."
        if confirm "When using DWM from TTY, a display manager is not needed. Do you want to remove $dm_name?"; then
            if [ "$distro" == "arch" ]; then
                sudo systemctl disable $dm_name.service
                sudo systemctl stop $dm_name.service
                sudo pacman -Rns $dm_name
            elif [ "$distro" == "fedora" ]; then
                sudo systemctl disable $dm_name.service
                sudo systemctl stop $dm_name.service
                sudo dnf remove -y $dm_name
            fi
            print_message "$GREEN" "Display manager $dm_name has been removed."
        fi
    else
        print_message "$GREEN" "No display manager detected. You can start DWM using 'startx' from TTY."
    fi
}

setup_numlock() {
    echo -e "${GREEN}Setting up NumLock on login...${ENDCOLOR}"

    sudo tee "/usr/local/bin/numlock" > /dev/null << 'EOF'
#!/bin/bash
for tty in /dev/tty{1..6}; do
    /usr/bin/setleds -D +num < "$tty"
done
EOF
    sudo chmod +x /usr/local/bin/numlock

    sudo tee "/etc/systemd/system/numlock.service" > /dev/null << 'EOF'
[Unit]
Description=Enable NumLock on startup
[Service]
ExecStart=/usr/local/bin/numlock
StandardInput=tty
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

    if confirm "Enable NumLock on boot?"; then
        sudo systemctl enable numlock.service
        echo -e "${GREEN}NumLock will be enabled on boot.${ENDCOLOR}"
    else
        echo -e "${GREEN}NumLock setup skipped.${ENDCOLOR}"
    fi
}

detect_distro
install_packages
install_dwm
install_slstatus
install_nerd_font
install_picom
configure_wallpapers
setup_xinitrc
setup_tty_login
check_display_manager
setup_numlock
print_message "$GREEN" "DWM setup completed successfully!"
print_message "$YELLOW" "Notice: I am not including dotfiles in this script to avoid conflicts and potential data loss. If you need dotfiles, check out my repo:"
print_message "$CYAN" "https://github.com/harilvfs/dwm/blob/main/config"
