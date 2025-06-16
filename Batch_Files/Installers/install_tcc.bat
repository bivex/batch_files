@echo off
setlocal

:: Define TCC version, architecture, filename, and download URL
set "TCC_VERSION=0.9.27"
set "TCC_ARCH=win64"
set "TCC_FILENAME=tcc-%TCC_VERSION%-%TCC_ARCH%-bin.zip"
set "DOWNLOAD_URL=https://download-mirror.savannah.gnu.org/releases/tinycc/%TCC_FILENAME%"
set "INSTALL_DIR=%SystemDrive%\TCC"

echo.
echo Tiny C Compiler (TCC) Installation Script for Windows
echo.

:: Download TCC
echo Downloading TCC from %DOWNLOAD_URL%...
curl -L "%DOWNLOAD_URL%" -o "%TEMP%\%TCC_FILENAME%"

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to download TCC. Please check your internet connection or the download URL.
    goto :eof
)
echo Download successful.

:: Create installation directory if it doesn't exist
echo Creating installation directory %INSTALL_DIR%...
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)
echo Directory created or already exists.

:: Extract TCC
echo Extracting TCC to a temporary location...
set "TEMP_EXTRACT_PATH=%TEMP%\TCC_extracted"
set "POWERSHELL_SCRIPT=%TEMP%\extract_tcc.ps1"

echo Expand-Archive -Path '%TEMP%\%TCC_FILENAME%' -DestinationPath '%TEMP_EXTRACT_PATH%' -Force > "%POWERSHELL_SCRIPT%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%POWERSHELL_SCRIPT%"

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to extract TCC using PowerShell. Please ensure PowerShell 5.0 or newer is installed and working correctly.
    goto :eof
)
echo Extraction to temporary location successful.

rem Identify the top-level directory inside the extracted zip
for /D %%i in ("%TEMP_EXTRACT_PATH%\*") do set "TCC_EXTRACTED_SUBDIR=%%i"

if not defined TCC_EXTRACTED_SUBDIR (
    echo Error: Could not find the expected sub-directory within the extracted archive.
    goto :eof
)

rem Move contents of the sub-directory to the final install directory
echo Moving contents from "%TCC_EXTRACTED_SUBDIR%" to "%INSTALL_DIR%"...
robocopy "%TCC_EXTRACTED_SUBDIR%" "%INSTALL_DIR%" /E /MOV /NFL /NDL /NJH /NJS

if %ERRORLEVEL% GEQ 8 (
    echo Error: Robocopy failed to move files. Please check permissions or available disk space.
    goto :eof
)
echo Files moved successfully.

rem Clean up the temporary extracted directory
echo Cleaning up temporary extraction directory...
rmdir /s /q "%TEMP_EXTRACT_PATH%"
del "%POWERSHELL_SCRIPT%"

if %ERRORLEVEL% NEQ 0 (
    echo Warning: Failed to clean up temporary directory %TEMP_EXTRACT_PATH%. You may need to delete it manually.
)
echo Temporary directory cleaned up.

:: Add TCC to system PATH
echo Adding %INSTALL_DIR% to system PATH...
setx PATH "%PATH%;%INSTALL_DIR%" /M

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to add TCC to PATH. You may need to run this script as an administrator.
    goto :eof
)
echo TCC path added to system PATH.

:: Clean up downloaded zip file
echo Cleaning up temporary files...
del "%TEMP%\%TCC_FILENAME%"
echo Cleanup complete.

echo.
echo TCC installation complete!
echo Please restart your Command Prompt or PowerShell for PATH changes to take effect.
echo You can verify the installation by running: tcc -v
echo.
pause
