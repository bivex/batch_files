# Windows Mouse Settings Analyzer
# This script analyzes various mouse-related settings in Windows

Write-Host "`nWindows Mouse Settings Analysis" -ForegroundColor Cyan
Write-Host "=============================`n" -ForegroundColor Cyan

# Function to get mouse speed in pixels per second
function Get-MouseSpeed {
    param([int]$value)
    $speeds = @(1, 2, 4, 6, 8, 10, 12, 14, 16, 20)
    return $speeds[$value]
}

# Get Mouse Speed and Acceleration
Write-Host "Mouse Speed and Acceleration Settings:" -ForegroundColor Yellow
$mouseSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse"
$speed = Get-MouseSpeed $mouseSettings.MouseSpeed
$acceleration = $mouseSettings.MouseThreshold1
$acceleration2 = $mouseSettings.MouseThreshold2

Write-Host "Mouse Speed: $speed pixels per second"
Write-Host "Mouse Acceleration: $($mouseSettings.MouseSpeed -gt 0)"
Write-Host "Acceleration Threshold 1: $acceleration"
Write-Host "Acceleration Threshold 2: $acceleration2"
Write-Host ""

# Get Mouse Button Settings
Write-Host "Mouse Button Settings:" -ForegroundColor Yellow
Write-Host "Swap Mouse Buttons: $($mouseSettings.SwapMouseButtons -eq 1)"
Write-Host "Double-Click Speed: $($mouseSettings.DoubleClickSpeed) ms"
Write-Host "Double-Click Height: $($mouseSettings.DoubleClickHeight) pixels"
Write-Host "Double-Click Width: $($mouseSettings.DoubleClickWidth) pixels"
Write-Host ""

# Get Mouse Wheel Settings
Write-Host "Mouse Wheel Settings:" -ForegroundColor Yellow
Write-Host "Wheel Scroll Lines: $($mouseSettings.WheelScrollLines)"
Write-Host "Wheel Scroll Chars: $($mouseSettings.WheelScrollChars)"
Write-Host ""

# Get Mouse Pointer Settings
Write-Host "Mouse Pointer Settings:" -ForegroundColor Yellow
$pointerSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse" -ErrorAction SilentlyContinue
Write-Host "Pointer Speed: $($pointerSettings.MouseSensitivity)"
Write-Host "Enhance Pointer Precision: $($pointerSettings.MouseSpeed -gt 0)"
Write-Host ""

# Get Mouse Accessibility Settings
Write-Host "Mouse Accessibility Settings:" -ForegroundColor Yellow
$accessSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility\MouseKeys" -ErrorAction SilentlyContinue
if ($accessSettings) {
    Write-Host "Mouse Keys Enabled: $($accessSettings.Flags -eq 1)"
    Write-Host "Mouse Keys Speed: $($accessSettings.MaxSpeed)"
    Write-Host "Mouse Keys Delay: $($accessSettings.TimeToMaxSpeed) ms"
}
Write-Host ""

# Get Mouse Pointer Scheme
Write-Host "Mouse Pointer Scheme:" -ForegroundColor Yellow
$schemeSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Cursors" -ErrorAction SilentlyContinue
if ($schemeSettings) {
    Write-Host "Current Scheme: $($schemeSettings.SchemeSource)"
    Write-Host "Custom Scheme: $($schemeSettings.CustomScheme)"
}
Write-Host ""

# Get Mouse Trails Settings
Write-Host "Mouse Trails Settings:" -ForegroundColor Yellow
$trailSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse" -ErrorAction SilentlyContinue
if ($trailSettings) {
    Write-Host "Mouse Trails Enabled: $($trailSettings.MouseTrails -eq 1)"
    Write-Host "Mouse Trail Length: $($trailSettings.MouseTrails)"
}
Write-Host ""

# Get Mouse Snap Settings
Write-Host "Mouse Snap Settings:" -ForegroundColor Yellow
$snapSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse" -ErrorAction SilentlyContinue
if ($snapSettings) {
    Write-Host "Snap To Default Button: $($snapSettings.SnapToDefaultButton -eq 1)"
}
Write-Host ""

# Get Mouse ClickLock Settings
Write-Host "Mouse ClickLock Settings:" -ForegroundColor Yellow
$clickLockSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse" -ErrorAction SilentlyContinue
if ($clickLockSettings) {
    Write-Host "ClickLock Enabled: $($clickLockSettings.ClickLock -eq 1)"
    Write-Host "ClickLock Time: $($clickLockSettings.ClickLockTime) ms"
}
Write-Host ""

# Get Mouse Hover Settings
Write-Host "Mouse Hover Settings:" -ForegroundColor Yellow
$hoverSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse" -ErrorAction SilentlyContinue
if ($hoverSettings) {
    Write-Host "Hover Time: $($hoverSettings.MouseHoverTime) ms"
    Write-Host "Hover Height: $($hoverSettings.MouseHoverHeight) pixels"
    Write-Host "Hover Width: $($hoverSettings.MouseHoverWidth) pixels"
}
Write-Host ""

Write-Host "Analysis Complete!" -ForegroundColor Green 