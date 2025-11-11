#!/bin/bash

# Скрипт автоматической настройки автодополнения команд в Fedora
# Сохраните как setup_autocomplete.sh и запустите: bash setup_autocomplete.sh

echo "=== Настройка автодополнения команд для Fedora ==="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки успешности выполнения команды
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Успешно${NC}"
    else
        echo -e "${RED}✗ Ошибка${NC}"
        exit 1
    fi
}

# Проверка, что система Fedora
if ! grep -q "Fedora" /etc/os-release; then
    echo -e "${RED}Ошибка: Этот скрипт предназначен только для Fedora${NC}"
    exit 1
fi

echo -e "\n${YELLOW}1. Обновление системы...${NC}"
sudo dnf update -y
check_success

echo -e "\n${YELLOW}2. Установка bash-completion...${NC}"
sudo dnf install -y bash-completion
check_success

echo -e "\n${YELLOW}3. Создание резервной копии .bashrc...${NC}"
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
check_success

echo -e "\n${YELLOW}4. Настройка автодополнения в .bashrc...${NC}"

# Проверяем, есть ли уже настройки автодополнения
if grep -q "bash-completion" ~/.bashrc; then
    echo -e "${YELLOW}Настройки автодополнения уже присутствуют в .bashrc${NC}"
else
    # Добавляем настройки автодополнения
    cat >> ~/.bashrc << 'EOF'

# === Автодополнение команд ===
# Настроено автоматически скриптом настройки

# Загрузка bash-completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Улучшенные настройки автодополнения
bind 'set show-all-if-ambiguous on'
bind 'set colored-completion-prefix on'
bind 'set completion-ignore-case on'
bind 'TAB: complete'

# Циклическое автодополнение при повторном нажатии Tab
bind '"\t": menu-complete'

# Поиск в истории по стрелкам вверх/вниз
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Показать все варианты при двойном нажатии Tab
bind '"\e[Z": complete'

# Цветное приглашение командной строки
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

EOF
    check_success
fi

echo -e "\n${YELLOW}5. Проверка установленных пакетов...${NC}"
if dnf list installed | grep -q "bash-completion"; then
    echo -e "${GREEN}bash-completion установлен${NC}"
else
    echo -e "${RED}bash-completion не установлен${NC}"
    exit 1
fi

echo -e "\n${YELLOW}6. Применение изменений...${NC}"
source ~/.bashrc
check_success

echo -e "\n${YELLOW}7. Дополнительные настройки...${NC}"

# Установка полезных утилит для разработчика (опционально)
read -p "Установить дополнительные утилиты для разработки? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Установка дополнительных пакетов..."
    sudo dnf install -y git wget curl tree htop ncdu ripgrep fd-find bat exa
    check_success
fi

echo -e "\n${GREEN}=== Настройка завершена! ===${NC}"
echo -e "${GREEN}Теперь автодополнение команд должно работать.${NC}"
echo -e "\n${YELLOW}Как использовать:${NC}"
echo "- Начинайте вводить команду и нажмите Tab для автодополнения"
echo "- Нажмите Tab дважды для показа всех вариантов"
echo "- Используйте стрелки вверх/вниз для поиска в истории"
echo -e "\n${YELLOW}Перезапустите терминал для полного применения изменений.${NC}"

# Проверка работы автодополнения
echo -e "\n${YELLOW}Проверка работы автодополнения...${NC}"
if complete -p | head -5; then
    echo -e "${GREEN}Автодополнение настроено корректно${NC}"
else
    echo -e "${YELLOW}Автодополнение может потребовать перезагрузки терминала${NC}"
fi