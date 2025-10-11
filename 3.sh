git clone https://github.com/Alexays/Waybar/  
cd Waybar  
sudo pacman -S fmt spdlog gtkmm3 libdbusmenu-gtk3 upower libmpdclient sndio gtk-layer-shell scdoc  
clang awesome-terminal-fonts jq  

yay catch2-git

sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch   workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp  

meson --prefix=/usr --buildtype=plain --auto-features=enabled --wrap-mode=nodownload build  
meson configure -Dexperimental=true build  
sudo ninja -C build install  

Можно так же из реп поставить или из аура. Я ставил из реп, вроде все пофиксили и все норм.