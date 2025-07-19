@echo off
setlocal enabledelayedexpansion

echo ========================================
echo ADB (Android Debug Bridge) Installer
echo ========================================
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator - Good!
) else (
    echo WARNING: This script should be run as Administrator to modify PATH
    echo Please right-click and "Run as Administrator"
    pause
    exit /b 1
)

:: Set variables
set "DOWNLOAD_URL=https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
set "INSTALL_DIR=%PROGRAMFILES%\Android\platform-tools"
set "TEMP_DIR=%TEMP%\adb_install"
set "ZIP_FILE=%TEMP_DIR%\platform-tools.zip"

echo Creating installation directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Creating temporary directory...
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

echo Downloading Android Platform Tools...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'}"

if not exist "%ZIP_FILE%" (
    echo ERROR: Failed to download platform tools
    pause
    exit /b 1
)

echo Extracting files...
powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%ZIP_FILE%', '%TEMP_DIR%')}"

echo Copying files to installation directory...
xcopy "%TEMP_DIR%\platform-tools\*" "%INSTALL_DIR%\" /E /Y /Q

echo Cleaning up temporary files...
rmdir /S /Q "%TEMP_DIR%"

:: Add to PATH if not already present
echo Checking if ADB is already in PATH...
echo %PATH% | find /i "%INSTALL_DIR%" >nul
if %errorLevel% == 0 (
    echo ADB is already in PATH
) else (
    echo Adding ADB to system PATH...
    setx PATH "%PATH%;%INSTALL_DIR%" /M
    echo PATH updated successfully
)

:: Verify installation
echo.
echo Verifying installation...
"%INSTALL_DIR%\adb.exe" version
if %errorLevel% == 0 (
    echo.
    echo ========================================
    echo ADB Installation Completed Successfully!
    echo ========================================
    echo.
    echo ADB has been installed to: %INSTALL_DIR%
    echo ADB has been added to your system PATH
    echo.
    echo You may need to restart your command prompt or computer
    echo for the PATH changes to take effect.
    echo.
    echo To test ADB, open a new command prompt and type: adb version
) else (
    echo.
    echo ERROR: ADB installation verification failed
    echo Please check the installation manually
)

echo.
pause 
