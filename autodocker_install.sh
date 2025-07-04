#!/bin/bash

# Скрипт для автоматической установки Docker и Docker Compose на Debian 12

# !!! ВНИМАНИЕ: Этот скрипт использует 'echo "1" | sudo -S' для автоматического ввода пароля '1' для sudo.
# Это удобно для автоматизации в тестовых средах, но НЕБЕЗОПАСНО для продакшн-систем.
# Для продакшн-систем рекомендуется запускать скрипт с 'sudo bash autodocker_install.sh'
# и вводить пароль вручную при запросе.

echo "Начинаем установку Docker и Docker Compose..."

# Шаг 1: Обновление индекса пакетов apt
echo "Обновление индекса пакетов apt..."
echo "1" | sudo -S apt update || { echo "Ошибка при обновлении apt."; exit 1; }

# Шаг 2: Установка необходимых пакетов
echo "Установка необходимых пакетов (ca-certificates, curl, gnupg)..."
echo "1" | sudo -S apt install -y ca-certificates curl gnupg || { echo "Ошибка при установке необходимых пакетов."; exit 1; }

# Шаг 3: Добавление GPG ключа Docker
echo "Добавление GPG ключа Docker..."
echo "1" | sudo -S install -m 0755 -d /etc/apt/keyrings || { echo "Ошибка при создании директории keyrings."; exit 1; }
echo "1" | sudo -S curl -fsSL https://download.docker.com/linux/debian/gpg | sudo -S gpg --dearmor -o /etc/apt/keyrings/docker.gpg || { echo "Ошибка при добавлении GPG ключа Docker."; exit 1; }

# Шаг 4: Добавление репозитория Docker
echo "Добавление репозитория Docker..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || { echo "Ошибка при добавлении репозитория Docker."; exit 1; }

# Шаг 5: Обновление индекса пакетов apt (повторно)
echo "Повторное обновление индекса пакетов apt..."
echo "1" | sudo -S apt update || { echo "Ошибка при повторном обновлении apt."; exit 1; }

# Шаг 6: Установка Docker Engine, Docker CLI и Containerd
echo "Установка Docker Engine, Docker CLI, Containerd и плагинов..."
echo "1" | sudo -S apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { echo "Ошибка при установке Docker компонентов."; exit 1; }

# Шаг 7: Проверка установки Docker
echo "Проверка установки Docker..."
echo "1" | sudo -S docker run hello-world || { echo "Docker не работает корректно."; exit 1; }

echo "Установка Docker и Docker Compose завершена успешно!" 
