@echo off
chcp 65001 >nul
echo ========================================
echo   KDNET Setup Script
echo ========================================
echo.
echo [1/5] Deleting old debug settings...
bcdedit /dbgsettings delete 2>nul
echo [2/5] Enabling kernel debug...
bcdedit /debug on
echo [3/5] Configuring KDNET...
echo    Host IP: 172.16.236.128 (Debugger)
echo    Target IP: 172.16.236.130
echo    Port: 50000
echo    Key: 1.2.3.4
bcdedit /dbgsettings net hostip:172.16.236.128 port:50000 key:1.2.3.4
echo [4/5] Opening firewall port 50000...
netsh advfirewall firewall add rule name="KDNET" dir=in action=allow protocol=TCP localport=50000 2>nul
echo [5/5] Current settings:
bcdedit /dbgsettings
echo.
echo Setup complete! Reboot required!
echo.
pause
