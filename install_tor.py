import os
import shutil
import requests
import tarfile
import winreg
import threading

TOR_DIR = r"C:\Tor"
TOR_DATA_DIR = os.path.join(TOR_DIR, "Data")
TOR_ARCHIVE_URL = "https://archive.torproject.org/tor-package-archive/torbrowser/14.5.4/tor-expert-bundle-windows-x86_64-14.5.4.tar.gz"
TOR_ARCHIVE_NAME = "tor-expert-bundle.tar.gz"
TORRC_PATH = os.path.join(TOR_DIR, "torrc")
START_TOR_BAT = os.path.join(TOR_DIR, "start-tor.bat")
DISABLE_PROXY_BAT = os.path.join(TOR_DIR, "disable-proxy.bat")


def create_dirs():
    os.makedirs(TOR_DATA_DIR, exist_ok=True)


def download_tor():
    if os.path.exists(TOR_ARCHIVE_NAME):
        return
    r = requests.get(TOR_ARCHIVE_URL, stream=True)
    with open(TOR_ARCHIVE_NAME, 'wb') as f:
        for chunk in r.iter_content(chunk_size=1024*1024):  # 1MB chunk
            if chunk:
                f.write(chunk)


def extract_tor():
    if not os.path.exists(TOR_ARCHIVE_NAME):
        return
    # Проверим, установлен ли tor.exe
    if os.path.exists(os.path.join(TOR_DIR, "tor.exe")):
        return
    with tarfile.open(TOR_ARCHIVE_NAME, 'r:gz') as tar:
        tar.extractall(TOR_DIR)


def move_tor_files():
    tor_subdir = os.path.join(TOR_DIR, "tor")
    if os.path.isdir(tor_subdir):
        for item in os.listdir(tor_subdir):
            s = os.path.join(tor_subdir, item)
            d = os.path.join(TOR_DIR, item)
            if os.path.isdir(s):
                if os.path.exists(d):
                    shutil.rmtree(d)
                shutil.move(s, d)
            else:
                shutil.move(s, d)
        shutil.rmtree(tor_subdir)


def create_torrc():
    if os.path.exists(TORRC_PATH):
        return
    with open(TORRC_PATH, 'w', encoding='utf-8') as f:
        f.write(r"""# Tor конфигурация для приватности и безопасности
# Локальный SOCKS-прокси для приложений
SocksPort 9050

# Порт управления (для Vidalia, Nyx и др.)
ControlPort 9051

# Каталог данных Tor
DataDirectory C:\\Tor\\Data

# Лог только важного в файл
Log notice file C:\\Tor\\tor.log

# Безопасное логирование (без IP-адресов)
SafeLogging 1

# Минимизировать запись на диск
AvoidDiskWrites 1

# Аутентификация через cookie (безопаснее, чем пароль)
CookieAuthentication 1

# Пример для мостов (раскомментируйте и добавьте свои)
# UseBridges 1
# Bridge obfs4 ...

# Не быть выходным узлом (только клиент)
ExitPolicy reject *:*
""")


def create_startup_script():
    if os.path.exists(START_TOR_BAT):
        return
    with open(START_TOR_BAT, 'w') as f:
        f.write(r"""@echo off
cd /d C:\\Tor
tor.exe -f C:\\Tor\\torrc
pause
""")


def set_system_proxy():
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                            r"Software\Microsoft\Windows\CurrentVersion\Internet Settings", 0, winreg.KEY_SET_VALUE) as key:
            winreg.SetValueEx(key, "ProxyEnable", 0, winreg.REG_DWORD, 1)
            winreg.SetValueEx(key, "ProxyServer", 0, winreg.REG_SZ, "socks=127.0.0.1:9050")
    except Exception:
        pass


def create_disable_proxy_script():
    if os.path.exists(DISABLE_PROXY_BAT):
        return
    with open(DISABLE_PROXY_BAT, 'w') as f:
        f.write(r"""@echo off
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
echo Proxy disabled
pause
""")


def cleanup():
    if os.path.exists(TOR_ARCHIVE_NAME):
        os.remove(TOR_ARCHIVE_NAME)


def main():
    # Создание директорий и скачивание параллельно
    t1 = threading.Thread(target=create_dirs)
    t2 = threading.Thread(target=download_tor)
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    extract_tor()
    move_tor_files()
    create_torrc()
    create_startup_script()
    set_system_proxy()
    create_disable_proxy_script()
    cleanup()
    print('Tor установлен!')
    print('Для запуска: C:\\Tor\\start-tor.bat')
    print('Отключить прокси: C:\\Tor\\disable-proxy.bat')
    print('ВНИМАНИЕ: Весь трафик будет идти через Tor!')


if __name__ == "__main__":
    main() 
