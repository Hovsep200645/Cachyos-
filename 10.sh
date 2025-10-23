#!/bin/bash
# flash_recovery_only.sh - Прошивка только рекавери и запуск

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

RECOVERY_FILE="recovery.img"

log() {
    echo -e "${GREEN}[$(date +%T)]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_recovery_file() {
    log "Проверка файла рекавери..."
    
    if [[ ! -f "$RECOVERY_FILE" ]]; then
        error "Файл $RECOVERY_FILE не найден!"
        echo "Убедитесь что recovery.img находится в текущей папке"
        exit 1
    fi
    
    # Проверяем размер файла
    file_size=$(stat -f%z "$RECOVERY_FILE" 2>/dev/null || stat -c%s "$RECOVERY_FILE" 2>/dev/null)
    if [[ $file_size -lt 10000000 ]]; then
        warn "Файл рекавери очень маленький ($file_size bytes) - возможно битый"
    fi
    
    log "✅ Файл рекавери найден: $RECOVERY_FILE ($file_size bytes)"
}

detect_device() {
    log "Поиск устройства в режиме прошивки..."
    
    if sudo heimdall detect; then
        log "✅ Устройство обнаружено"
        return 0
    else
        error "❌ Устройство не обнаружено"
        echo "Подключите телефон в режиме загрузки:"
        echo "1. Выключить телефон"
        echo "2. Зажать Vol- + Home + Power"
        echo "3. Подключить USB кабель"
        return 1
    fi
}

flash_recovery_only() {
    log "Начинаю прошивку рекавери..."
    
    # Пробуем разные методы прошивки
    log "Метод 1: Стандартная прошивка..."
    if sudo heimdall flash --RECOVERY "$RECOVERY_FILE" --no-reboot; then
        log "✅ Рекавери успешно прошит"
        return 0
    fi
    
    # Если не сработало, пробуем с force
    warn "Метод 1 не сработал, пробуем принудительную прошивку..."
    if sudo heimdall flash --RECOVERY "$RECOVERY_FILE" --no-reboot --force; then
        log "✅ Рекавери прошит принудительно"
        return 0
    fi
    
    # Пробуем с verbose для диагностики
    warn "Пробуем с подробным выводом..."
    if sudo heimdall flash --RECOVERY "$RECOVERY_FILE" --no-reboot --verbose; then
        log "✅ Рекавери прошит (verbose mode)"
        return 0
    fi
    
    error "❌ Все методы прошивки не сработали"
    return 1
}

reboot_to_recovery() {
    log "Пытаюсь перезагрузить в рекавери..."
    
    # Метод 1: Через heimdall
    if sudo heimdall reboot --recovery; then
        log "✅ Команда перезагрузки в рекавери отправлена"
        return 0
    fi
    
    # Метод 2: Через обычную перезагрузку + комбинация кнопок
    warn "Пробуем альтернативный метод перезагрузки..."
    if sudo heimdall reboot; then
        log "✅ Команда перезагрузки отправлена"
        echo "Сразу после перезагрузки зажмите: Vol+ + Home + Power"
        return 0
    fi
    
    # Метод 3: Принудительная перезагрузка
    warn "Пробуем принудительную перезагрузку..."
    sudo heimdall reboot --force
    log "✅ Команда принудительной перезагрузки отправлена"
}

wait_for_recovery() {
    log "Ожидание загрузки в рекавери..."
    echo "Если телефон загрузится в рекавери - скрипт завершится успешно"
    echo "Жду 30 секунд..."
    
    for i in {1..30}; do
        # Проверяем ADB устройство в рекавери
        if adb devices | grep -q "recovery"; then
            log "🎉 Телефон успешно загрузился в рекавери!"
            return 0
        fi
        
        # Проверяем USB устройство
        if lsusb | grep -q "04e8.*recovery\|04e8.*adb"; then
            log "🎉 Обнаружено устройство в режиме ADB/Recovery!"
            return 0
        fi
        
        echo -n "."
        sleep 1
    done
    
    warn "⚠️ Телефон не загрузился в рекавери в течение 30 секунд"
    echo "Попробуйте вручную:"
    echo "1. Отключить и включить телефон"
    echo "2. Зажать Vol+ + Home + Power"
    echo "3. Подождать 10-15 секунд"
}

emergency_reflash() {
    log "=== АВАРИЙНАЯ ПРОШИВКА ==="
    warn "Если обычные методы не работают, пробуем экстренный метод..."
    
    # Создаем временный PIT файл
    log "Создаем временный PIT..."
    if sudo heimdall print-pit --output temp.pit; then
        log "PIT файл создан, пробуем прошивку с PIT..."
        sudo heimdall flash --RECOVERY "$RECOVERY_FILE" --pit temp.pit --no-reboot
    else
        log "PIT не доступен, пробуем raw прошивку..."
        sudo heimdall flash --RECOVERY "$RECOVERY_FILE" --raw --no-reboot
    fi
    
    # Очистка
    rm -f temp.pit
}

main() {
    log "=== Прошивка Recovery для SM-J530FM ==="
    
    # Проверки
    check_recovery_file
    
    # Обнаружение устройства
    if ! detect_device; then
        error "Устройство не найдено. Подключите телефон в режиме загрузки."
        exit 1
    fi
    
    # Прошивка рекавери
    if flash_recovery_only; then
        log "✅ Recovery успешно прошит"
    else
        warn "Пробуем аварийный метод прошивки..."
        emergency_reflash
    fi
    
    # Перезагрузка
    reboot_to_recovery
    
    # Ожидание
    wait_for_recovery
    
    log "=== СКРИПТ ЗАВЕРШЕН ==="
    echo ""
    echo "Если телефон загрузился в рекавери:"
    echo "1. Можете прошить полную прошивку"
    echo "2. Сделать wipe data/factory reset"
    echo "3. Установить кастомную прошивку"
    echo ""
    echo "Если телефон не загрузился:"
    echo "1. Попробуйте другой файл recovery.img"
    echo "2. Проверьте оригинальность USB кабеля"
    echo "3. Попробуйте другой компьютер"
}

# Обработка Ctrl+C
trap 'echo -e "\n${YELLOW}Скрипт прерван пользователем${NC}"; exit 1' INT

# Запуск
main "$@"