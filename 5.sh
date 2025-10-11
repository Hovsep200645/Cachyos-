#!/bin/bash

echo "🚀 Полная установка Hyprland и окружения"

# Функция для проверки успешности выполнения команд
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Ошибка: $1"
        exit 1
    fi
}

# 1. Установка зависимостей для сборки
echo "📦 Установка зависимостей..."
sudo pacman -S --needed --noconfirm \
    base-devel gdb ninja gcc cmake libxcb xcb-proto xcb-util \
    xcb-util-keysyms libxfixes libx11 libxcomposite xorg-xinput libxrender \
    pixman wayland-protocols cairo pango seatd libxkbcommon xcb-util-wm \
    xorg-xwayland cmake wlroots mesa git meson polkit \
    fmt spdlog gtkmm3 libdbusmenu-gtk3 upower libmpdclient sndio gtk-layer-shell scdoc \
    clang awesome-terminal-fonts jq \
    pulseaudio pavucontrol firefox telegram-desktop mousepad gimp inkscape \
    blender ghostscript obs-studio xdg-desktop-portal-wlr transmission-gtk python \
    imv mpv nemo waybar grim slurp swaybg swaylock mako jq wofi htop cmus neofetch ranger unzip \
    ttf-nerd-fonts-symbols

check_success "Установка зависимостей"

# 2. Установка yay если нет
if ! command -v yay &> /dev/null; then
    echo "📦 Установка yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ~
    check_success "Установка yay"
fi

# 3. Установка catch2-git из AUR
echo "📦 Установка catch2-git..."
yay -S catch2-git --noconfirm
check_success "Установка catch2-git"

# 4. Сборка и установка Hyprland из исходников
echo "🔨 Сборка Hyprland из исходников..."
cd /tmp
git clone --recursive https://github.com/hyprwm/Hyprland
cd Hyprland
git submodule init
git submodule update
sudo make install
check_success "Сборка Hyprland"

# 5. Создание конфигурационной директории и копирование примера конфига
echo "⚙️ Настройка конфигурации Hyprland..."
mkdir -p ~/.config/hypr
cp /tmp/Hyprland/example/hyprland.conf ~/.config/hypr/
check_success "Копирование конфига Hyprland"

# 6. Сборка и установка hyprpaper из исходников
echo "🖼️ Сборка hyprpaper..."
cd /tmp
git clone https://github.com/hyprwm/hyprpaper
cd hyprpaper
make all
sudo cp build/hyprpaper /usr/bin/
check_success "Сборка hyprpaper"

# 7. Сборка и установка Waybar из исходников
echo "📊 Сборка Waybar..."
cd /tmp
git clone https://github.com/Alexays/Waybar/
cd Waybar

# Применяем патч для workspace manager
sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp

# Сборка Waybar
meson --prefix=/usr --buildtype=plain --auto-features=enabled --wrap-mode=nodownload build
meson configure -Dexperimental=true build
sudo ninja -C build install
check_success "Сборка Waybar"

# 8. Настройка тем и иконок
echo "🎨 Настройка тем..."
cd /tmp
git clone https://gitlab.com/prolinux410/owl_dots

# Установка тем GTK (если пакеты доступны)
sudo pacman -S --noconfirm breeze-icons capitaine-cursors || echo "⚠️ Темы не найдены в репозиториях"

# Применение настроек тем
gsettings set org.gnome.desktop.interface icon-theme breeze-icons-dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme Fantome 2>/dev/null || true  
gsettings set org.gnome.desktop.interface cursor-theme capitaine-cursors 2>/dev/null || true

# 9. Установка дополнительных программ из AUR
echo "📦 Установка дополнительных программ из AUR..."
yay -S --noconfirm cava
check_success "Установка cava"

# 10. Создание базового конфига Waybar
echo "⚙️ Создание конфига Waybar..."
mkdir -p ~/.config/waybar
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 4,
    
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "cpu", "memory", "battery", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": false,
        "all-outputs": true
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "🔇",
        "format-icons": ["🔈", "🔉", "🔊"]
    },
    
    "cpu": {
        "format": "{usage}% "
    },
    
    "memory": {
        "format": "{}% "
    },
    
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    }
}
EOF

# 11. Создание стиля для Waybar
cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: #1e1e2e;
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 8px;
    background: transparent;
    color: #6c7086;
}

#workspaces button.active {
    background: rgba(137, 180, 250, 0.3);
    color: #89b4fa;
}

#clock, #cpu, #memory, #pulseaudio, #battery {
    padding: 0 10px;
    margin: 0 3px;
}
EOF

# 12. Создание скрипта для запуска
echo "🚀 Создание скрипта запуска..."
cat > ~/start-hyprland.sh << 'EOF'
#!/bin/bash
echo "Запуск Hyprland..."
export XDG_SESSION_TYPE=wayland
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland

# Запуск Hyprland
exec Hyprland
EOF

chmod +x ~/start-hyprland.sh

# 13. Очистка временных файлов
echo "🧹 Очистка временных файлов..."
rm -rf /tmp/Hyprland /tmp/hyprpaper /tmp/Waybar /tmp/yay /tmp/owl_dots

echo ""
echo "🎉 Установка завершена!"
echo ""
echo "📝 Что было установлено:"
echo "   ✅ Hyprland (композитор)"
echo "   ✅ hyprpaper (обои)"
echo "   ✅ Waybar (панель)"
echo "   ✅ Все необходимые зависимости"
echo "   ✅ Дополнительные программы"
echo ""
echo "🚀 Для запуска выполните:"
echo "   Hyprland"
echo "   Или: ~/start-hyprland.sh"
echo ""
echo "⚙️  Конфиги созданы в:"
echo "   ~/.config/hypr/hyprland.conf"
echo "   ~/.config/waybar/config"
echo ""
echo "💡 Не забудьте настроить конфиги под свои нужды!"