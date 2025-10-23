#!/bin/bash
# blank_emmc_activator.sh - Активация виртуального eMMC для Exynos 7870

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Пути и параметры
IMAGE_FILE="blank_emmc.img"
IMAGE_SIZE=64 # MB

log() {
    echo -e "${GREEN}[$(date +%T)]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Не запускайте скрипт от root! Запрашиваем права когда нужно."
        exit 1
    fi
}

create_blank_image() {
    if [[ ! -f "$IMAGE_FILE" ]]; then
        log "Создаю пустой образ eMMC ($IMAGE_SIZE MB)..."
        dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=$IMAGE_SIZE status=progress
        sudo mkfs.vfat "$IMAGE_FILE"
        log "Образ создан: $IMAGE_FILE"
    else
        log "Образ уже существует: $IMAGE_FILE"
    fi
}

unload_module() {
    log "Выгружаем модуль g_mass_storage..."
    sudo modprobe -r g_mass_storage 2>/dev/null || true
    sleep 2
}

load_emmc_module() {
    log "Активируем виртуальный eMMC..."
    sudo modprobe g_mass_storage \
        file="$(pwd)/$IMAGE_FILE" \
        stall=0 \
        removable=1 \
        vendor=0x04e8 \
        product=0x6860 \
        product_id="SAMSUNG eMMC" \
        serial="EXYNOS7870_BOOT"
    
    # Проверяем что модуль загружен
    if lsmod | grep -q g_mass_storage; then
        log "✅ Виртуальный eMMC активирован"
    else
        error "Не удалось активировать виртуальный eMMC"
        exit 1
    fi
}

power_cycle_ports() {
    log "Цикл питания USB портов..."
    for port in /sys/bus/usb/devices/*/power/control; do
        if [[ -f "$port" ]]; then
            echo "suspend" | sudo tee "$port" > /dev/null 2>&1 || true
        fi
    done
    sleep 1
    
    for port in /sys/bus/usb/devices/*/power/control; do
        if [[ -f "$port" ]]; then
            echo "on" | sudo tee "$port" > /dev/null 2>&1 || true
        fi
    done
}

usb_reset_devices() {
    log "Сброс USB устройств Samsung..."
    while IFS= read -r line; do
        if echo "$line" | grep -q "04e8"; then
            bus=$(echo "$line" | awk '{print $2}')
            dev=$(echo "$line" | awk '{print $4}' | tr -d ':')
            if [[ -n "$bus" && -n "$dev" ]]; then
                sudo usb_modeswitch -v 04e8 -p "${dev#0}" -b "$bus" -d "$dev" -R 2>/dev/null || true
            fi
        fi
    done < <(lsusb)
}

monitor_devices() {
    log "Мониторинг подключения устройств..."
    log "Подключите телефон сейчас! Пробуйте разные комбинации кнопок:"
    echo "1. Vol- + Home + Power"
    echo "2. Vol+ + Home + Power" 
    echo "3. Только Power"
    echo "4. Подключение/отключение кабеля"
    echo ""
    echo "Нажмите Ctrl+C для выхода"
    echo ""
    
    local detected=0
    while [[ $detected -eq 0 ]]; do
        # Проверяем подключение Samsung устройств
        if lsusb | grep -q "04e8"; then
            log "📱 Обнаружено устройство Samsung!"
            echo "=== USB УСТРОЙСТВА ==="
            lsusb | grep -i samsung
            echo "======================"
            
            # Пробуем сброс
            usb_reset_devices
            sleep 2
            power_cycle_ports
            
            # Проверяем heimdall
            if sudo heimdall detect > /dev/null 2>&1; then
                log "🎉 HEIMDALL ВИДИТ УСТРОЙСТВО!"
                log "Можно пробовать прошивку: sudo heimdall flash --BOOT boot.img"
                detected=1
            else
                log "Heimdall не видит устройство, продолжаем мониторинг..."
                sleep 5
            fi
        fi
        sleep 2
    done
}

emergency_recovery() {
    log "Запуск экстренного восстановления..."
    for attempt in {1..10}; do
        log "Попытка $attempt/10"
        
        unload_module
        sleep 1
        load_emmc_module
        sleep 2
        power_cycle_ports
        sleep 2
        usb_reset_devices
        
        # Ждем подключения
        for wait in {1..10}; do
            if lsusb | grep -q "04e8"; then
                log "Устройство обнаружено на попытке $wait!"
                return 0
            fi
            sleep 1
        done
    done
    
    error "Устройство не обнаружено после 10 попыток"
    return 1
}

cleanup() {
    log "Очистка..."
    sudo modprobe -r g_mass_storage 2>/dev/null || true
}

main() {
    trap cleanup EXIT
    
    log "=== Virtual eMMC Activator для Exynos 7870 ==="
    log "Цель: оживление загрузчика без прошивки"
    
    check_root
    create_blank_image
    unload_module
    load_emmc_module
    
    echo ""
    log "Выберите режим:"
    echo "1) Мониторинг (рекомендуется)"
    echo "2) Экстренное восстановление"
    echo "3) Только активация eMMC"
    read -p "Введите номер [1]: " choice
    
    case "${choice:-1}" in
        1)
            monitor_devices
            ;;
        2)
            emergency_recovery
            ;;
        3)
            log "eMMC активирован, запустите мониторинг вручную"
            ;;
        *)
            error "Неверный выбор"
            exit 1
            ;;
    esac
}

# Запуск скрипта
main "$@"