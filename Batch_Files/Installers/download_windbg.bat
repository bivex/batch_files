@echo off
set "DOWNLOAD_URL=https://windbg.download.prss.microsoft.com/dbazure/prod/1-2504-15001-0/windbg.msixbundle"
set "OUTPUT_FILE=windbg.msixbundle"

echo Checking for curl...
where curl >NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo curl is not found. Attempting to use PowerShell to download.
    powershell -command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%OUTPUT_FILE%'"
    IF %ERRORLEVEL% NEQ 0 (
        echo An error occurred during download using PowerShell.
        echo Please ensure PowerShell is available or download the file manually from:
        echo %DOWNLOAD_URL%
        goto :EOF
    )
) ELSE (
    echo Downloading WinDbg from %DOWNLOAD_URL%...
    curl -L -o %OUTPUT_FILE% %DOWNLOAD_URL%
    IF %ERRORLEVEL% NEQ 0 (
        echo An error occurred during download using curl.
        echo Please try running the command manually: curl -L -o %OUTPUT_FILE% %DOWNLOAD_URL%
        goto :EOF
    )
)

echo Download complete: %OUTPUT_FILE%
echo Double-click %OUTPUT_FILE% to install WinDbg.
pause 
