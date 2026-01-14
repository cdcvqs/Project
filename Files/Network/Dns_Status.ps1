# c. Using WMI directly
Write-Host "`n   c. Using WMI directly:"
Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } | ForEach-Object {
    Write-Host "   - Adapter: $($_.Description)"
    Write-Host "     DNS: $($_.DNSServerSearchOrder -join ', ')"
}

$ipv6Addresses = Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue
$hasGlobalIPv6 = $false

if ($ipv6Addresses) {
    # Check for global IPv6 addresses (not link-local or unique local)
    foreach ($addr in $ipv6Addresses) {
        if ($addr.AddressPrefixOrigin -eq "RouterAdvertisement" -or
            $addr.AddressPrefixOrigin -eq "Dhcp" -or
            $addr.AddressPrefixOrigin -eq "Manual") {
            # Check if it's a global unicast address (starts with 2000::/3)
            $ipBytes = $addr.IPAddress.GetAddressBytes()
            if ($ipBytes[0] -ge 0x20 -and $ipBytes[0] -le 0x3F) {
                $hasGlobalIPv6 = $true
                Write-Host "Global IPv6 address found: $($addr.IPAddress)"
                break
            }
        }
    }
}

if (-not $hasGlobalIPv6) {
    # Try to ping a known IPv6 address to confirm
    $ipv6Test = Test-Connection "2606:4700:4700::1111" -Count 1 -ErrorAction SilentlyContinue
    if ($ipv6Test) {
        $hasGlobalIPv6 = $true
        Write-Host "IPv6 connectivity confirmed"
    } else {
        Write-Host "IPv6 support: $(if ($hasGlobalIPv6) {'Enabled'} else {'Disabled'})"
    }
}


# Cloudflare, Google, and other DNS servers for testing
$testServers = @(
    @{Name="Cloudflare Primary IPv4"; Address="1.1.1.1"; Type="IPv4"},
    @{Name="Google Primary IPv4"; Address="8.8.8.8"; Type="IPv4"},
    @{Name="Cloudflare Family IPv4 (Block Malware)"; Address="1.1.1.3"; Type="IPv4"},
    @{Name="AdGuard DNS IPv4"; Address="94.140.14.15"; Type="IPv4"},
    @{Name="CleanBrowsing Family IPv4"; Address="185.228.168.168"; Type="IPv4"},
    @{Name="Quad9 Security IPv4"; Address="9.9.9.9"; Type="IPv4"},
	@{Name="OpenDNS IPv4"; Address="208.67.222.222"; Type="IPv4"}
)

# Add IPv6 servers only if IPv6 is supported
if ($hasGlobalIPv6) {
    $testServers += @(
        @{Name="Cloudflare Primary IPv6"; Address="2606:4700:4700::1111"; Type="IPv6"},
        @{Name="Google Primary IPv6"; Address="2001:4860:4860::8888"; Type="IPv6"},
        @{Name="Cloudflare Family IPv6 (Block Malware)"; Address="2606:4700:4700::1113"; Type="IPv6"},
        @{Name="AdGuard DNS IPv6"; Address="2a10:50c0::bad:ff"; Type="IPv6"},
        @{Name="CleanBrowsing Family IPv6"; Address="2a0d:2a00:1::"; Type="IPv6"},
        @{Name="Quad9 Security IPv6"; Address="2620:fe::fe"; Type="IPv6"},
		@{Name="OpenDNS IPv6"; Address="2620:fe::fe"; Type="IPv6"}
    )
}

$results = @()
foreach ($server in $testServers) {
    Write-Host ""
    Write-Host "$($server.Name) ($($server.Address)):" -NoNewline
try {
    $ping = Test-Connection -ComputerName $server.Address -Count 3 -ErrorAction Stop
    if ($ping) {
        $avgLatency = ($ping | Measure-Object -Property ResponseTime -Average).Average
        $minLatency = ($ping | Measure-Object -Property ResponseTime -Minimum).Minimum
        $maxLatency = ($ping | Measure-Object -Property ResponseTime -Maximum).Maximum

        Write-Host "  `nAvg: $([math]::Round($avgLatency, 2)) ms | Min: $([math]::Round($minLatency, 2)) ms | Max: $([math]::Round($maxLatency, 2)) ms"
    }
}
    catch {
        Write-Host " Failed"
        Write-Host "    Error: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 1
}