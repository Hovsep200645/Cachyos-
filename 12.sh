#!/usr/bin/env python3
# dead_phone_rescuer.py

import subprocess
import time
import os

print("🆘 СПАСАТЕЛЬ МЕРТВОГО ТЕЛЕФОНА")

def force_usb_power_cycle():
    """Экстренный цикл питания USB"""
    for i in range(10):
        # Выкл
        subprocess.run(["echo", "suspend"], 
                      stdout=subprocess.DEVNULL, 
                      stderr=subprocess.DEVNULL)
        time.sleep(0.05)
        # Вкл
        subprocess.run(["echo", "on"], 
                      stdout=subprocess.DEVNULL, 
                      stderr=subprocess.DEVNULL)
        time.sleep(0.05)

def emergency_flash():
    """Мгновенная прошивка при обнаружении"""
    print("⚡ МГНОВЕННАЯ ПРОШИВКА...")
    result = subprocess.run([
        "sudo", "heimdall", "flash", 
        "--RECOVERY", "recovery.img", 
        "--no-reboot", "--force"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✅ УСПЕХ! Перезагружаем в рекавери...")
        subprocess.run(["sudo", "heimdall", "reboot", "--recovery", "--force"])
        return True
    return False

# Основной цикл
print("Поиск мертвого устройства...")
while True:
    # Проверяем USB устройства
    result = subprocess.run(["lsusb"], capture_output=True, text=True)
    
    if "04e8" in result.stdout:
        print("🎯 ОБНАРУЖЕН SAMSUNG!")
        force_usb_power_cycle()
        
        if emergency_flash():
            print("🎉 ВОЗМОЖНО УСПЕХ! Проверяйте телефон")
            break
    
    time.sleep(1)