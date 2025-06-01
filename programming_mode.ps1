# Windows Keyboard Programming Mode Optimizer
# This script configures keyboard settings optimized for programming

Write-Host "`nEnabling Programming Mode for Keyboard Settings" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

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

# Function to convert milliseconds to registry value
function ConvertToRegistryValue {
    param([int]$milliseconds)
    return [math]::Round($milliseconds * 31 / 1000)
}

# Store original settings for backup
Write-Host "Backing up current keyboard settings..." -ForegroundColor Yellow
$backupPath = "HKCU:\Software\KeyboardSettingsBackup"
$keyboardSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -ErrorAction SilentlyContinue
$hotkeySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue

if ($keyboardSettings) {
    Set-RegistryValue -Path $backupPath -Name "OriginalDelay" -Value $keyboardSettings.KeyboardDelay
    Set-RegistryValue -Path $backupPath -Name "OriginalSpeed" -Value $keyboardSettings.KeyboardSpeed
    if ($hotkeySettings) {
        Set-RegistryValue -Path $backupPath -Name "OriginalAltTab" -Value $hotkeySettings.AltTabSettings
        Set-RegistryValue -Path $backupPath -Name "OriginalWinKeys" -Value $hotkeySettings.NoWinKeys
    }
    Write-Host "Backup completed successfully" -ForegroundColor Green
}

# Configure keyboard delay and repeat rate for programming
Write-Host "`nConfiguring keyboard delay and repeat rate..." -ForegroundColor Yellow
$success = $true

# Set fastest repeat rate (approximately 15ms)
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value 31)
# Set shortest initial delay (approximately 200ms)
$success = $success -and (Set-RegistryValue -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value 0)

if ($success) {
    Write-Host "Keyboard timing optimized for programming" -ForegroundColor Green
}

# Enable Alt+Tab and Windows Key
Write-Host "`nConfiguring keyboard shortcuts..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AltTabSettings" -Value 0
$success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "NoWinKeys" -Value 0)
if ($success) {
    Write-Host "Keyboard shortcuts enabled" -ForegroundColor Green
}

# Disable Filter Keys
Write-Host "`nDisabling Filter Keys..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Value 0
if ($success) {
    Write-Host "Filter Keys disabled" -ForegroundColor Green
}

# Configure Sticky Keys for programming (enabled but with modified settings)
Write-Host "`nConfiguring Sticky Keys for programming..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value 63
if ($success) {
    Write-Host "Sticky Keys configured for programming" -ForegroundColor Green
}

# Enable Toggle Keys
Write-Host "`nEnabling Toggle Keys..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value 1
if ($success) {
    Write-Host "Toggle Keys enabled" -ForegroundColor Green
}

# Configure Mouse Keys for programming
Write-Host "`nConfiguring Mouse Keys..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\MouseKeys" -Name "Flags" -Value 1
if ($success) {
    Write-Host "Mouse Keys configured" -ForegroundColor Green
}

# Configure Language Bar for programming
Write-Host "`nConfiguring Language Bar..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Software\Microsoft\CTF\LangBar" -Name "ShowStatus" -Value 1
if ($success) {
    Write-Host "Language Bar configured" -ForegroundColor Green
}

# Enable keyboard accessibility
Write-Host "`nConfiguring keyboard accessibility..." -ForegroundColor Yellow
$success = Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility" -Name "KeyboardPreference" -Value 1
if ($success) {
    Write-Host "Keyboard accessibility enabled" -ForegroundColor Green
}

Write-Host "`nProgramming mode configuration complete!" -ForegroundColor Green
Write-Host "Note: Some changes may require a system restart to take full effect." -ForegroundColor Yellow
Write-Host "Original settings have been backed up to: $backupPath" -ForegroundColor Yellow

# Create restore script
$restoreScript = @"
# Windows Keyboard Settings Restore Script
# This script restores the original keyboard settings

`$backupPath = "HKCU:\Software\KeyboardSettingsBackup"
`$originalDelay = Get-ItemProperty -Path `$backupPath -Name "OriginalDelay" -ErrorAction SilentlyContinue
`$originalSpeed = Get-ItemProperty -Path `$backupPath -Name "OriginalSpeed" -ErrorAction SilentlyContinue
`$originalAltTab = Get-ItemProperty -Path `$backupPath -Name "OriginalAltTab" -ErrorAction SilentlyContinue
`$originalWinKeys = Get-ItemProperty -Path `$backupPath -Name "OriginalWinKeys" -ErrorAction SilentlyContinue

if (`$originalDelay -and `$originalSpeed) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value `$originalDelay.OriginalDelay
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value `$originalSpeed.OriginalSpeed
    Write-Host "Original keyboard timing restored" -ForegroundColor Green
}

if (`$originalAltTab -and `$originalWinKeys) {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AltTabSettings" -Value `$originalAltTab.OriginalAltTab
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "NoWinKeys" -Value `$originalWinKeys.OriginalWinKeys
    Write-Host "Original keyboard shortcuts restored" -ForegroundColor Green
}

Write-Host "Restore complete!" -ForegroundColor Green
"@

$restoreScript | Out-File -FilePath "restore_keyboard_settings.ps1" -Encoding UTF8
Write-Host "`nA restore script has been created: restore_keyboard_settings.ps1" -ForegroundColor Cyan 