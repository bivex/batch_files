# Windows Mouse Programming Mode Optimizer
# This script configures mouse settings optimized for programming

Write-Host "`nEnabling Programming Mode for Mouse Settings" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

# Function to set registry value
function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    try {
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        return $true
    }
    catch {
        Write-Host "Failed to set $Name in $Path" -ForegroundColor Red
        return $false
    }
}

# Store original settings for backup
Write-Host "Backing up current mouse settings..." -ForegroundColor Yellow
$backupPath = "HKCU:\Software\MouseSettingsBackup"
$mouseSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse" -ErrorAction SilentlyContinue

if ($mouseSettings) {
    Set-RegistryValue -Path $backupPath -Name "OriginalSpeed" -Value $mouseSettings.MouseSpeed
    Set-RegistryValue -Path $backupPath -Name "OriginalThreshold1" -Value $mouseSettings.MouseThreshold1
    Set-RegistryValue -Path $backupPath -Name "OriginalThreshold2" -Value $mouseSettings.MouseThreshold2
    Set-RegistryValue -Path $backupPath -Name "OriginalDoubleClickSpeed" -Value $mouseSettings.DoubleClickSpeed
    Set-RegistryValue -Path $backupPath -Name "OriginalWheelScrollLines" -Value $mouseSettings.WheelScrollLines
    Set-RegistryValue -Path $backupPath -Name "OriginalMouseSensitivity" -Value $mouseSettings.MouseSensitivity
    Write-Host "Backup completed successfully" -ForegroundColor Green
}

# Configure mouse speed and acceleration for programming
Write-Host "`nConfiguring mouse speed and acceleration..." -ForegroundColor Yellow
$success = $true

# Disable acceleration for precise movement
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value 0)
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value 0)
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value 0)

# Set optimal pointer speed (6 is the default 1:1 movement)
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value 6)

if ($success) {
    Write-Host "Mouse speed and acceleration optimized for programming" -ForegroundColor Green
}

# Configure double-click settings
Write-Host "`nConfiguring double-click settings..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "DoubleClickSpeed" -Value 500
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "DoubleClickHeight" -Value 4)
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "DoubleClickWidth" -Value 4)

if ($success) {
    Write-Host "Double-click settings optimized" -ForegroundColor Green
}

# Configure wheel settings
Write-Host "`nConfiguring wheel settings..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "WheelScrollLines" -Value 3
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "WheelScrollChars" -Value 3)

if ($success) {
    Write-Host "Wheel settings optimized" -ForegroundColor Green
}

# Disable unnecessary visual effects
Write-Host "`nDisabling unnecessary visual effects..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseTrails" -Value 0
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "SnapToDefaultButton" -Value 0)

if ($success) {
    Write-Host "Visual effects optimized" -ForegroundColor Green
}

# Configure hover settings
Write-Host "`nConfiguring hover settings..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Value 100
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverHeight" -Value 4)
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverWidth" -Value 4)

if ($success) {
    Write-Host "Hover settings optimized" -ForegroundColor Green
}

# Configure ClickLock settings
Write-Host "`nConfiguring ClickLock settings..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "ClickLock" -Value 0
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Mouse" -Name "ClickLockTime" -Value 1200)

if ($success) {
    Write-Host "ClickLock settings optimized" -ForegroundColor Green
}

Write-Host "`nProgramming mode configuration complete!" -ForegroundColor Green
Write-Host "Note: Some changes may require a system restart to take full effect." -ForegroundColor Yellow
Write-Host "Original settings have been backed up to: $backupPath" -ForegroundColor Yellow

# Create restore script
$restoreScript = @"
# Windows Mouse Settings Restore Script
# This script restores the original mouse settings

`$backupPath = "HKCU:\Software\MouseSettingsBackup"
`$originalSpeed = Get-ItemProperty -Path `$backupPath -Name "OriginalSpeed" -ErrorAction SilentlyContinue
`$originalThreshold1 = Get-ItemProperty -Path `$backupPath -Name "OriginalThreshold1" -ErrorAction SilentlyContinue
`$originalThreshold2 = Get-ItemProperty -Path `$backupPath -Name "OriginalThreshold2" -ErrorAction SilentlyContinue
`$originalDoubleClickSpeed = Get-ItemProperty -Path `$backupPath -Name "OriginalDoubleClickSpeed" -ErrorAction SilentlyContinue
`$originalWheelScrollLines = Get-ItemProperty -Path `$backupPath -Name "OriginalWheelScrollLines" -ErrorAction SilentlyContinue
`$originalMouseSensitivity = Get-ItemProperty -Path `$backupPath -Name "OriginalMouseSensitivity" -ErrorAction SilentlyContinue

if (`$originalSpeed -and `$originalThreshold1 -and `$originalThreshold2) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value `$originalSpeed.OriginalSpeed
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value `$originalThreshold1.OriginalThreshold1
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value `$originalThreshold2.OriginalThreshold2
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "DoubleClickSpeed" -Value `$originalDoubleClickSpeed.OriginalDoubleClickSpeed
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "WheelScrollLines" -Value `$originalWheelScrollLines.OriginalWheelScrollLines
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value `$originalMouseSensitivity.OriginalMouseSensitivity
    Write-Host "Original mouse settings restored successfully" -ForegroundColor Green
} else {
    Write-Host "No backup found to restore" -ForegroundColor Red
}
"@

$restoreScript | Out-File -FilePath "restore_mouse_settings.ps1" -Encoding UTF8
Write-Host "`nA restore script has been created: restore_mouse_settings.ps1" -ForegroundColor Cyan 