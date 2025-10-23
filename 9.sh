#!/bin/bash
# auto_recovery_loop.sh - Автоматический цикл восстановления

while true; do
    echo "=== Запуск цикла восстановления ==="
    ./blank_emmc_activator.sh
    
    echo ""
    read -p "Повторить? (y/n) [y]: " answer
    case "${answer:-y}" in
        [Yy]* ) continue;;
        * ) break;;
    esac
done