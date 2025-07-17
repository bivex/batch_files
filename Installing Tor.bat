There's a syntax error in the tar command. Here's the corrected batch script:
batch@echo off
echo Installing Tor for Windows...

:: Create directories
mkdir "C:\Tor" 2>nul
mkdir "C:\Tor\Data" 2>nul

:: Download current Tor Expert Bundle (14.5.4)
echo Downloading Tor Expert Bundle...
powershell -Command "Invoke-WebRequest -Uri 'https://archive.torproject.org/tor-package-archive/torbrowser/14.5.4/tor-expert-bundle-windows-x86_64-14.5.4.tar.gz' -OutFile 'tor-expert-bundle.tar.gz'"

:: Extract using PowerShell (Windows 10+ has built-in tar)
echo Extracting Tor...
tar -xzf tor-expert-bundle.tar.gz -C C:\Tor\

:: Move files to correct location
if exist "C:\Tor\tor" (
    xcopy "C:\Tor\tor\*" "C:\Tor\" /E /Y
    rmdir "C:\Tor\tor" /S /Q
)

:: Create torrc configuration
echo Creating torrc configuration...
(
echo SocksPort 9050
echo ControlPort 9051
echo DataDirectory C:\Tor\Data
echo Log notice stdout
echo SafeLogging 1
echo ExitPolicy reject *:*
) > "C:\Tor\torrc"

:: Create startup script
echo Creating startup script...
(
echo @echo off
echo cd /d "C:\Tor"
echo tor.exe -f "C:\Tor\torrc"
echo pause
) > "C:\Tor\start-tor.bat"

:: Set system proxy via registry
echo Configuring system proxy...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "socks=127.0.0.1:9050" /f

:: Create disable proxy script
(
echo @echo off
echo reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
echo echo Proxy disabled
echo pause
) > "C:\Tor\disable-proxy.bat"

:: Cleanup
del tor-expert-bundle.tar.gz 2>nul

echo Installation complete!
echo.
echo To start Tor: Run "C:\Tor\start-tor.bat"
echo To disable proxy: Run "C:\Tor\disable-proxy.bat"
echo.
echo WARNING: This routes ALL traffic through Tor
echo Use responsibly and check your local laws
pause
