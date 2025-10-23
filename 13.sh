#!/bin/bash
# ultimate_rescue.sh

echo "=== УЛЬТИМАТИВНОЕ ВОССТАНОВЛЕНИЕ ==="

# 1. Активируем виртуальную eMMC
sudo modprobe -r g_mass_storage 2>/dev/null
dd if=/dev/zero of=rescue.img bs=1M count=64 2>/dev/null
sudo modprobe g_mass_storage file=rescue.img stall=0 removable=1

# 2. Быстрые циклы питания + мониторинг
for attempt in {1..100}; do
    echo "🔁 Цикл $attempt"
    
    # Супер-быстрое питание
    for i in {1..5}; do
        echo "suspend" | sudo tee /sys/bus/usb/devices/*/power/level >/dev/null 2>&1
        sleep 0.02
        echo "on" | sudo tee /sys/bus/usb/devices/*/power/level >/dev/null 2>&1  
        sleep 0.02
    done
    
    # Мгновенная реакция на устройство
    if lsusb | grep -q "04e8"; then
        echo "🎯 ОБНАРУЖЕНО! Мгновенная прошивка..."
        sudo heimdall flash --RECOVERY recovery.img --no-reboot --force && \
        sudo heimdall reboot --recovery --force && \
        echo "🎉 КОМАНДЫ ОТПРАВЛЕНЫ!" && \
        break
    fi
    
    sleep 0.5
done

echo "Готово! Проверьте телефон."