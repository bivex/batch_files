# Windows Keyboard Settings Analyzer
# This script analyzes various keyboard-related settings in Windows

Write-Host "`nWindows Keyboard Settings Analysis" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Function to convert registry value to milliseconds
function ConvertToMilliseconds {
    param([int]$value)
    return [math]::Round($value * 1000 / 31, 2)
}

# Function to get keyboard layout details
function Get-KeyboardLayoutDetails {
    $layouts = Get-WinUserLanguageList
    $details = @()
    foreach ($layout in $layouts) {
        $details += "Language: $($layout.LanguageTag)"
        $details += "Input Methods: $($layout.InputMethodTips -join ', ')"
    }
    return $details
}

# Get Keyboard Delay and Repeat Rate
Write-Host "Keyboard Delay and Repeat Rate Settings:" -ForegroundColor Yellow
$keyboardSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Keyboard"
$delay = ConvertToMilliseconds $keyboardSettings.KeyboardDelay
$repeatRate = ConvertToMilliseconds $keyboardSettings.KeyboardSpeed

Write-Host "Initial Delay: $delay ms"
Write-Host "Repeat Rate: $repeatRate ms"
Write-Host ""

# Get Filter Keys Settings
Write-Host "Filter Keys Settings:" -ForegroundColor Yellow
$filterKeys = Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility\Keyboard Response"
Write-Host "Filter Keys Enabled: $($filterKeys.Flags -eq 1)"
Write-Host "Bounce Time: $($filterKeys.BounceTime) ms"
Write-Host "Delay Before Acceptance: $($filterKeys.DelayBeforeAcceptance) ms"
Write-Host ""

# Get Sticky Keys Settings
Write-Host "Sticky Keys Settings:" -ForegroundColor Yellow
$stickyKeys = Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys"
Write-Host "Sticky Keys Enabled: $($stickyKeys.Flags -eq 1)"
Write-Host ""

# Get Toggle Keys Settings
Write-Host "Toggle Keys Settings:" -ForegroundColor Yellow
$toggleKeys = Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility\ToggleKeys"
Write-Host "Toggle Keys Enabled: $($toggleKeys.Flags -eq 1)"
Write-Host ""

# Get Mouse Keys Settings
Write-Host "Mouse Keys Settings:" -ForegroundColor Yellow
$mouseKeys = Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility\MouseKeys"
Write-Host "Mouse Keys Enabled: $($mouseKeys.Flags -eq 1)"
Write-Host ""

# Get Keyboard Layout Information
Write-Host "Keyboard Layout Information:" -ForegroundColor Yellow
$keyboardLayout = Get-WinUserLanguageList
if ($keyboardLayout -and $keyboardLayout[0].InputMethodTips.Count -gt 0) {
    Write-Host "Current Keyboard Layout: $($keyboardLayout[0].InputMethodTips[0])"
    Write-Host "Available Layouts:"
    Get-KeyboardLayoutDetails | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "No keyboard layout information available"
}
Write-Host ""

# Get Keyboard Language Bar Settings
Write-Host "Language Bar Settings:" -ForegroundColor Yellow
$languageBar = Get-ItemProperty -Path "HKCU:\Software\Microsoft\CTF\LangBar" -ErrorAction SilentlyContinue
Write-Host "Show Language Bar: $($languageBar.ShowStatus -eq 1)"
Write-Host ""

# Get Keyboard Repeat Delay Settings
Write-Host "Keyboard Repeat Settings:" -ForegroundColor Yellow
$repeatSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Keyboard"
Write-Host "Repeat Delay: $($repeatSettings.KeyboardDelay) (0-3, lower is faster)"
Write-Host "Repeat Rate: $($repeatSettings.KeyboardSpeed) (0-31, higher is faster)"
Write-Host ""

# Get Keyboard Input Method Editor (IME) Settings
Write-Host "Input Method Editor (IME) Settings:" -ForegroundColor Yellow
$imeSettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\IME\15.0\IMETC" -ErrorAction SilentlyContinue
if ($imeSettings) {
    Write-Host "IME Enabled: $($imeSettings.EnableDoublePinyin -eq 1)"
    Write-Host "Double Pinyin Enabled: $($imeSettings.EnableDoublePinyin -eq 1)"
} else {
    Write-Host "IME settings not available"
}
Write-Host ""

# Get Keyboard Hotkey Settings
Write-Host "Keyboard Hotkey Settings:" -ForegroundColor Yellow
$hotkeySettings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue
if ($hotkeySettings) {
    Write-Host "Alt+Tab Enabled: $($hotkeySettings.AltTabSettings -eq 0)"
    Write-Host "Windows Key Enabled: $($hotkeySettings.NoWinKeys -eq 0)"
}
Write-Host ""

# Get Keyboard Accessibility Settings
Write-Host "Keyboard Accessibility Settings:" -ForegroundColor Yellow
$accessSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility" -ErrorAction SilentlyContinue
if ($accessSettings) {
    Write-Host "Keyboard Accessibility Enabled: $($accessSettings.KeyboardPreference -eq 1)"
    Write-Host "Sound On Errors: $($accessSettings.SoundOnErrors -eq 1)"
}
Write-Host ""

Write-Host "Analysis Complete!" -ForegroundColor Green 