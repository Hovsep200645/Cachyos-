#!/usr/bin/env python3
import usb.core
import usb.util
import sys
import time

# Поиск устройства Exynos
dev = usb.core.find(idVendor=0x04e8)

if dev is None:
    print("Устройство не найдено!")
    sys.exit(1)

print(f"Найдено: {dev}")

try:
    # Попытка сброса
    dev.reset()
    print("Сброс выполнен")
    
    # Попытка установки конфигурации
    dev.set_configuration()
    print("Конфигурация установлена")
    
    # Отправка контрольных пакетов
    dev.ctrl_transfer(0x40, 1, 0, 0, b'')
    print("Команда отправлена")
    
except Exception as e:
    print(f"Ошибка: {e}")