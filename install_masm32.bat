@echo off
setlocal EnableDelayedExpansion

:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: This script requires administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

title MASM32 Installer
echo ===================================
echo        MASM32 SDK Installer
echo ===================================
echo.

:: Define variables
set "INSTALL_DIR=C:\masm32"
set "TEMP_DIR=%TEMP%\masm32_install"
set "DOWNLOAD_URL=https://www.masm32.com/download/masm32v11r.zip"
set "ZIP_FILE=%TEMP_DIR%\masm32.zip"

:: Create temp directory
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%" 2>nul
if %errorlevel% neq 0 (
    echo Error: Failed to create temporary directory.
    goto :error
)
cd /d "%TEMP_DIR%" || goto :error

:: Download MASM32 SDK
echo [1/4] Downloading MASM32 SDK...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -ErrorAction Stop } catch { exit 1 }}"
if %errorlevel% neq 0 (
    echo Error: Failed to download MASM32 SDK.
    echo Please check your internet connection and try again.
    goto :cleanup
)
if not exist "%ZIP_FILE%" goto :download_error

:: Extract MASM32 SDK
echo [2/4] Extracting files to %INSTALL_DIR%...
if exist "%INSTALL_DIR%" (
    echo Note: Removing existing MASM32 installation...
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)
powershell -Command "& {try { Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%INSTALL_DIR%' -Force -ErrorAction Stop } catch { exit 1 }}"
if %errorlevel% neq 0 (
    echo Error: Failed to extract MASM32 SDK.
    goto :cleanup
)
if not exist "%INSTALL_DIR%" goto :extract_error

:: Update system PATH
echo [3/4] Adding MASM32 to system PATH...
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH ^| find "PATH"') do set "CURRENT_PATH=%%b"
echo Current PATH: !CURRENT_PATH!
if "!CURRENT_PATH:~-1!" == ";" (
    set "NEW_PATH=!CURRENT_PATH!%INSTALL_DIR%\bin"
) else (
    set "NEW_PATH=!CURRENT_PATH!;%INSTALL_DIR%\bin"
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!NEW_PATH!" /f
if %errorlevel% neq 0 (
    echo Warning: Failed to update system PATH. You may need to add "%INSTALL_DIR%\bin" manually.
)

:: Set up file associations
echo [4/4] Setting up file associations...
ftype ASMFile="%INSTALL_DIR%\bin\Qeditor.exe" "%%1"
assoc .asm=ASMFile

:: Installation complete
echo.
echo ===================================
echo       Installation Complete!
echo ===================================
echo.
echo MASM32 has been installed to: %INSTALL_DIR%
echo.
echo IMPORTANT: You must restart your command prompt for PATH changes to take effect.
echo.
echo To test your installation, create a .asm file and compile it with:
echo    ml /c /coff yourfile.asm
echo    link /subsystem:console yourfile.obj
echo.
goto :cleanup

:download_error
echo Error: The downloaded file was not found.
goto :cleanup

:extract_error
echo Error: The extraction process failed.
goto :cleanup

:error
echo Installation failed.
goto :cleanup

:cleanup
echo Cleaning up temporary files...
cd /d "%USERPROFILE%"
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul

if exist "%INSTALL_DIR%" (
    echo Installation completed successfully.
) else (
    echo Installation failed.
)

pause
endlocal
exit /b 