# Disable TCP AutoTuning
netsh interface tcp set global autotuninglevel=disabled

# Disable Nagle's Algorithm (TcpAckFrequency) for active network adapters
$adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
foreach ($adapter in $adapters) {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid)"
    New-ItemProperty -Path $regPath -Name "TcpAckFrequency" -PropertyType DWord -Value 1 -Force | Out-Null
}

# Clear DNS cache
Clear-DnsClientCache

# Reset Winsock and TCP/IP stack
netsh winsock reset
netsh int ip reset

# Check if QoS policy "GamingMode" exists, create if not
$existingPolicy = Get-NetQosPolicy -Name "GamingMode" -ErrorAction SilentlyContinue
if (-not $existingPolicy) {
    New-NetQosPolicy -Name "GamingMode" -AppPathNameMatchCondition "*" -NetworkProfile All -DSCPAction 46 -ThrottleRateActionBitsPerSecond 0
} else {
    Set-NetQosPolicy -Name "GamingMode" -AppPathNameMatchCondition "*" -NetworkProfile All -DSCPAction 46 -ThrottleRateActionBitsPerSecond 0
}

Write-Host "Network optimization complete. Please reboot your PC for all changes to take effect."
