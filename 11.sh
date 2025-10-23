#!/bin/bash
# hotplug_recovery.sh

echo "=== МЕТОД ГОРЯЧЕГО ПОДКЛЮЧЕНИЯ ==="
echo "1. Подготовьте recovery.img"
echo "2. Запустите этот скрипт"
echo "3. Быстро вставляйте/вынимайте USB кабель 3-4 раза"
echo "4. Скрипт автоматически попытается прошить устройство"

while true; do
    if lsusb | grep -q "04e8"; then
        echo "📱 Телефон обнаружен! Срочно прошиваем..."
        
        # Мгновенная прошивка рекавери
        if sudo heimdall flash --RECOVERY recovery.img --no-reboot --force; then
            echo "✅ Рекавери прошит! Пробуем загрузку..."
            sudo heimdall reboot --recovery --force
            echo "🎉 КОМАНДА ОТПРАВЛЕНА! Ждем 30 секунд..."
            sleep 30
            break
        fi
    fi
    sleep 0.5
done