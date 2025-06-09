@echo off
echo Switching keyboard layout...
powershell -command "Set-WinUILanguageOverride -Language 'uk-UA'; Set-WinUserLanguageList -LanguageList 'uk-UA','ru-RU','en-US' -Force"
timeout /t 2
echo Done. Enjoy multilingualism :)
pause
