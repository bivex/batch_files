# Windows Mouse Settings Restore Script
# This script restores the original mouse settings

$backupPath = "HKCU:\Software\MouseSettingsBackup"
$originalSpeed = Get-ItemProperty -Path $backupPath -Name "OriginalSpeed" -ErrorAction SilentlyContinue
$originalThreshold1 = Get-ItemProperty -Path $backupPath -Name "OriginalThreshold1" -ErrorAction SilentlyContinue
$originalThreshold2 = Get-ItemProperty -Path $backupPath -Name "OriginalThreshold2" -ErrorAction SilentlyContinue
$originalDoubleClickSpeed = Get-ItemProperty -Path $backupPath -Name "OriginalDoubleClickSpeed" -ErrorAction SilentlyContinue
$originalWheelScrollLines = Get-ItemProperty -Path $backupPath -Name "OriginalWheelScrollLines" -ErrorAction SilentlyContinue
$originalMouseSensitivity = Get-ItemProperty -Path $backupPath -Name "OriginalMouseSensitivity" -ErrorAction SilentlyContinue

if ($originalSpeed -and $originalThreshold1 -and $originalThreshold2) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value $originalSpeed.OriginalSpeed
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value $originalThreshold1.OriginalThreshold1
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value $originalThreshold2.OriginalThreshold2
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "DoubleClickSpeed" -Value $originalDoubleClickSpeed.OriginalDoubleClickSpeed
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "WheelScrollLines" -Value $originalWheelScrollLines.OriginalWheelScrollLines
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value $originalMouseSensitivity.OriginalMouseSensitivity
    Write-Host "Original mouse settings restored successfully" -ForegroundColor Green
} else {
    Write-Host "No backup found to restore" -ForegroundColor Red
}
