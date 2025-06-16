@echo off
echo Switching keyboard layout...
powershell -command "Set-WinUILanguageOverride -Language 'ru-RU'; Set-WinUserLanguageList -LanguageList 'ru-RU','en-US' -Force"
timeout /t 2
echo Done. Enjoy multilingualism :)
pause
