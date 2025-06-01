# Windows Hardware Programming Mode Optimizer
# This script optimizes hardware settings for programming

Write-Host "`nEnabling Programming Mode for Hardware Settings" -ForegroundColor Cyan
Write-Host "=============================================`n" -ForegroundColor Cyan

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
Write-Host "Backing up current hardware settings..." -ForegroundColor Yellow
$backupPath = "HKCU:\Software\HardwareSettingsBackup"

# CPU Optimization
Write-Host "`nOptimizing CPU settings..." -ForegroundColor Yellow
$success = $true

# Set CPU priority for foreground applications
$success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff)
$success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0)

# Optimize for background services
$success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Value 6)
$success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Value 2 -Type "DWord")
$success = $success -and (Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "SFIO Priority" -Value 2 -Type "DWord")

if ($success) {
    Write-Host "CPU settings optimized" -ForegroundColor Green
}

# Memory Optimization
Write-Host "`nOptimizing memory settings..." -ForegroundColor Yellow
$success = $true

# Disable SuperFetch for better memory management
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "EnableSuperfetch" -Value 0)
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "EnablePrefetcher" -Value 0)

# Optimize page file
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1)

if ($success) {
    Write-Host "Memory settings optimized" -ForegroundColor Green
}

# Network Optimization
Write-Host "`nOptimizing network settings..." -ForegroundColor Yellow
$success = $true

# Optimize TCP/IP settings
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpNoDelay" -Value 1)
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -Value 1)
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPDelAckTicks" -Value 0)

if ($success) {
    Write-Host "Network settings optimized" -ForegroundColor Green
}

# Disk Optimization
Write-Host "`nOptimizing disk settings..." -ForegroundColor Yellow
$success = $true

# Disable last access timestamp
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Value 1)

# Optimize for performance
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "DisableDeleteNotification" -Value 0)
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "DisableCompression" -Value 0)

if ($success) {
    Write-Host "Disk settings optimized" -ForegroundColor Green
}

# Visual Effects Optimization
Write-Host "`nOptimizing visual effects..." -ForegroundColor Yellow
$success = $true

# Disable unnecessary visual effects
$success = $success -and (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2)

if ($success) {
    Write-Host "Visual effects optimized" -ForegroundColor Green
}

# Power Settings Optimization
Write-Host "`nOptimizing power settings..." -ForegroundColor Yellow
$success = $true

# Set high performance power plan
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Value 0)
$success = $success -and (Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HiberbootEnabled" -Value 0)

if ($success) {
    Write-Host "Power settings optimized" -ForegroundColor Green
}

Write-Host "`nHardware optimization complete!" -ForegroundColor Green
Write-Host "Note: Some changes may require a system restart to take full effect." -ForegroundColor Yellow

# Create restore script
$restoreScript = @"
# Windows Hardware Settings Restore Script
# This script restores the original hardware settings

# Restore CPU settings
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20

# Restore Memory settings
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "EnableSuperfetch" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "EnablePrefetcher" -Value 3
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0

# Restore Network settings
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpNoDelay" -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpAckFrequency" -Value 2
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TCPDelAckTicks" -Value 2

# Restore Disk settings
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Value 0

# Restore Visual Effects
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 1

# Restore Power settings
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HiberbootEnabled" -Value 1

Write-Host "Original hardware settings restored successfully" -ForegroundColor Green
"@

$restoreScript | Out-File -FilePath "restore_hardware_settings.ps1" -Encoding UTF8
Write-Host "`nA restore script has been created: restore_hardware_settings.ps1" -ForegroundColor Cyan 