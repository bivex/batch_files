# Windows Keyboard Settings Restore Script
# This script restores the original keyboard settings

$backupPath = "HKCU:\Software\KeyboardSettingsBackup"
$originalDelay = Get-ItemProperty -Path $backupPath -Name "OriginalDelay" -ErrorAction SilentlyContinue
$originalSpeed = Get-ItemProperty -Path $backupPath -Name "OriginalSpeed" -ErrorAction SilentlyContinue
$originalAltTab = Get-ItemProperty -Path $backupPath -Name "OriginalAltTab" -ErrorAction SilentlyContinue
$originalWinKeys = Get-ItemProperty -Path $backupPath -Name "OriginalWinKeys" -ErrorAction SilentlyContinue

if ($originalDelay -and $originalSpeed) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value $originalDelay.OriginalDelay
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value $originalSpeed.OriginalSpeed
    Write-Host "Original keyboard timing restored" -ForegroundColor Green
}

if ($originalAltTab -and $originalWinKeys) {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AltTabSettings" -Value $originalAltTab.OriginalAltTab
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "NoWinKeys" -Value $originalWinKeys.OriginalWinKeys
    Write-Host "Original keyboard shortcuts restored" -ForegroundColor Green
}

Write-Host "Restore complete!" -ForegroundColor Green
