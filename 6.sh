#!/bin/bash

# Сброс USB питания для всех устройств Samsung
for device in /sys/bus/usb/devices/*/power/control; do
    echo "auto" | sudo tee "$device" > /dev/null
done

# Попытка перезагрузки через heimdall
sudo heimdall detect > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Device detected, attempting reboot to download mode..."
    sudo heimdall reboot --download
    sleep 5
fi

# Дополнительная попытка через USB reset
sudo usb_reset || echo "USB reset not available"

echo "If device is still unresponsive, try physical key combination:"
echo "1. Hold Vol-Down + Home + Power for 10 seconds"
echo "2. Release all buttons"
echo "3. Immediately hold Vol-Down + Home and connect USB cable"