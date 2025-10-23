#!/bin/bash
echo "=== Samsung J530FM Emergency Recovery ==="

# 1. Сброс USB
for dev in /sys/bus/usb/devices/*/power/control; do
    echo "auto" | sudo tee $dev > /dev/null
done

# 2. Поиск устройства
echo "Searching for device..."
lsusb | grep -i samsung || lsusb | grep -i exynos

# 3. Попытка heimdall с принудительным режимом
sudo heimdall detect --verbose
if [ $? -eq 0 ]; then
    echo "Attempting flash in current mode..."
    sudo heimdall flash --BOOT boot.img --no-reboot
else
    echo "Device not detected in heimdall"
    echo "Try physical button combination:"
    echo "1. Disconnect USB"
    echo "2. Hold Vol-Down + Home + Power for 15sec"
    echo "3. Connect USB while holding Vol-Down + Home"
fi