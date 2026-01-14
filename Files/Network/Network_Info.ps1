# Device Information
$hostname = hostname
Write-Host "Device Name: $hostname"
Write-Host "Username: $env:USERNAME"
Write-Host "Domain: $env:USERDOMAIN"

# Connection Speed Tests
Write-Host "`nConnection speed tests"

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
    @{Name="Google Primary IPv4"; Address="8.8.8.8"; Type="IPv4"}
)

# Add IPv6 servers only if IPv6 is supported
if ($hasGlobalIPv6) {
    $testServers += @(
        @{Name="Cloudflare Primary IPv6"; Address="2606:4700:4700::1111"; Type="IPv6"},
        @{Name="Google Primary IPv6"; Address="2001:4860:4860::8888"; Type="IPv6"}
    )
}

$results = @()
foreach ($server in $testServers) {
    Write-Host ""
    Write-Host " $($server.Name) ($($server.Address)):" -NoNewline
try {
    $ping = Test-Connection -ComputerName $server.Address -Count 2 -ErrorAction Stop
    if ($ping) {
        $avgLatency = ($ping | Measure-Object -Property ResponseTime -Average).Average
        $minLatency = ($ping | Measure-Object -Property ResponseTime -Minimum).Minimum
        $maxLatency = ($ping | Measure-Object -Property ResponseTime -Maximum).Maximum

        Write-Host "`nAvg: $([math]::Round($avgLatency, 2)) ms | Min: $([math]::Round($minLatency, 2)) ms | Max: $([math]::Round($maxLatency, 2)) ms"
    }
}
    catch {
        Write-Host " Failed"
        Write-Host "    Error: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 1
}

# DNS Resolution Test
Write-Host "`nDNS Resolution Test:"
$hosts = @("google.com","cloudflare.com","microsoft.com","facebook.com")
foreach ($h in $hosts) {
    $result = Resolve-DnsName $h -ErrorAction SilentlyContinue
    if ($result) {
        Write-Host "  $h - Working"
    } else {
        Write-Host "  $h - Failed"
    }
}

# Default Gateway Address
Write-Host "`nDefault Gateway Address:"
$gateway = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue).NextHop
if ($gateway) {
    Write-Host "  $gateway"
} else {
    Write-Host "  Not found"
}

# Active Network Adapter Information
Write-Host "`nActive Network Adapters"
Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 } | ForEach-Object {
    # Determine adapter type
    $type = if ($_.Name -match 'Wireless|Wi[- ]?Fi') { 'Wi-Fi' } else { 'Ethernet' }
    
    # Calculate speed
    if ($_.Speed) {
        $speedMbps = [math]::Round($_.Speed / 1000000, 1)
        $speedText = "$speedMbps Mbps"
    } else {
        $speedText = "Not Available"
    }
    
    # Get IP address and DNS configuration
    $adapterIndex = $_.Index
    $adapterConfig = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $adapterIndex }
    
    $ipAddress = "No IP Address"
    $dnsServers = "No DNS Servers"
    
    if ($adapterConfig) {
        # Get IPv4 address
        if ($adapterConfig.IPAddress) {
            $ipv4Address = $adapterConfig.IPAddress | Where-Object { $_ -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' } | Select-Object -First 1
            if ($ipv4Address) {
                $ipAddress = $ipv4Address
            }
        }
        
        # Get DNS servers
        if ($adapterConfig.DNSServerSearchOrder -and $adapterConfig.DNSServerSearchOrder.Count -gt 0) {
            # Filter for IPv4 DNS servers
            $ipv4DnsServers = $adapterConfig.DNSServerSearchOrder | Where-Object { $_ -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' }
            if ($ipv4DnsServers) {
                $dnsServers = $ipv4DnsServers -join ", "
            }
        }
    }
    
    # Display information
    Write-Host "  Adapter Name: $($_.Name)"
    Write-Host "  Type: $type"
    Write-Host "  Speed: $speedText"
    Write-Host "  DNS Servers: $dnsServers"
    Write-Host "  Local IP Address (LAN): $ipAddress"
    Write-Host "  MAC Address: $($_.MACAddress)"
    Write-Host ""
}

# Public IP Address (WAN)
Write-Host "`nPublic IP Address (WAN):"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$publicIP = $null
$publicIP = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -ErrorAction SilentlyContinue

if ($publicIP -and $publicIP.ip) {
    Write-Host "  IP Address: $($publicIP.ip)"
    
    # Get GeoIP info
    try {
        $geoInfo = Invoke-RestMethod -Uri "http://ip-api.com/json/$($publicIP.ip)" -ErrorAction SilentlyContinue
        if ($geoInfo) {
            Write-Host "  Country: $($geoInfo.country)"
            Write-Host "  City: $($geoInfo.city)"
            Write-Host "  ISP: $($geoInfo.isp)"
            Write-Host "  Timezone: $($geoInfo.timezone)"
        }
    } catch {
        Write-Host "Could not retrieve geographic information"
    }
} else {
    Write-Host "Could not retrieve public IP address"
}

# VPN Connections
Write-Host "`nVPN Connections"
$vpnConnections = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue
if ($vpnConnections) {
    $vpnConnections | Format-Table Name, ServerAddress, ConnectionStatus -AutoSize
} else {
    Write-Host "  No VPN connections"
}

# Proxy Status
Write-Host "`nProxy Status:"
$proxy = netsh winhttp show proxy 2>$null
if ($proxy -match 'Direct access') {
    Write-Host "  No proxy configured"
} else {
    $proxyLines = $proxy -split "`n" | Where-Object { $_ -match ':' }
    foreach ($line in $proxyLines) {
        Write-Host "  $($line.Trim())"
    }
}

# IPv6 Status
Write-Host "`nIPv6 Status:"
$ipv6Addresses = Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue | Where-Object {
    $_.IPAddress -notlike 'fe80*' -and $_.IPAddress -notlike '::1'
}
if ($ipv6Addresses) {
    Write-Host "  Active"
    $ipv6Addresses | Select-Object -First 3 | ForEach-Object {
        Write-Host "   $($_.IPAddress) [$($_.InterfaceAlias)]"
    }
    if ($ipv6Addresses.Count -gt 3) {
        Write-Host "  ... and $($ipv6Addresses.Count - 3) more"
    }
} else {
    Write-Host "  Inactive or not configured"
}
Write-Host ""

# Firewall status
Write-Host "`nFirewall status:"
$fwProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
if ($fwProfiles) {
    foreach ($profile in $fwProfiles) {
        $status = if ($profile.Enabled) { 'Enable' } else { 'Disable' }
        Write-Host "   $($profile.Name): $status"
    }
} else {
    Write-Host "  Error checking firewall status"
}
Write-Host ""

# Current Network Connection
Write-Host "`nCurrent Network Connection:"
$netProfile = Get-NetConnectionProfile -ErrorAction SilentlyContinue
if ($netProfile) {
    Write-Host "SSID/Network Name: $($netProfile.Name)"
    Write-Host "  Type: $($netProfile.NetworkCategory)"
    Write-Host "  Connected via: $($netProfile.InterfaceAlias)"
    Write-Host "  IPv4 Connectivity: $($netProfile.IPv4Connectivity)"
    Write-Host "  IPv6 Connectivity: $($netProfile.IPv6Connectivity)"
    
    $wifiInterface = $netProfile.InterfaceAlias
    if ($wifiInterface -match "Wi-Fi|Wireless|WLAN") {
        $wifiInfo = netsh wlan show interfaces 2>$null
        if ($wifiInfo) {
            $signal = $wifiInfo | Select-String -Pattern "Signal\s*:\s*(\d+)%"
            $channel = $wifiInfo | Select-String -Pattern "Channel\s*:\s*(\d+)"
            $radioType = $wifiInfo | Select-String -Pattern "Radio type\s*:\s*(.+)"
            $authentication = $wifiInfo | Select-String -Pattern "Authentication\s*:\s*(.+)"
            $cipher = $wifiInfo | Select-String -Pattern "Cipher\s*:\s*(.+)"
            
            if ($signal) { Write-Host   "Signal Strength: $($signal.Matches.Groups[1].Value)%" }
            if ($channel) { Write-Host   "Channel: $($channel.Matches.Groups[1].Value)" }
            if ($radioType) { Write-Host   "Radio Type: $($radioType.Matches.Groups[1].Value.Trim())" }
            if ($authentication) { Write-Host   "Authentication: $($authentication.Matches.Groups[1].Value.Trim())" }
            if ($cipher) { Write-Host   "Cipher: $($cipher.Matches.Groups[1].Value.Trim())" }
        }
    }
} else {
    Write-Host "No active network connection profile"
}

Write-Host "`nAvailable Wi-Fi Networks"
$availableNetworks = netsh wlan show networks mode=bssid 2>$null
if ($availableNetworks) {
    Write-Host ($availableNetworks -join "`n")
} else {
    Write-Host "No Wi-Fi networks available or no Wi-Fi adapter found"
}

# Saved Wi-Fi Profiles
Write-Host "`nSaved Wi-Fi Profiles:"
$profilesOutput = netsh wlan show profiles 2>$null
if ($profilesOutput) {
    $profiles = $profilesOutput | Select-String 'All User Profile' | ForEach-Object { 
        ($_ -split ':')[1].Trim() 
    } | Sort-Object -Unique
    
    if ($profiles) {
        Write-Host "Found $($profiles.Count) saved profiles:`n"
        
        $wifiEvents = Get-WinEvent -LogName 'Microsoft-Windows-WLAN-AutoConfig/Operational' -ErrorAction SilentlyContinue | 
            Where-Object { $_.Id -eq 8001 } | 
            Select-Object TimeCreated, @{Name='SSID';Expression={
                if ($_.Message -match 'SSID:\s*([^\s\n\r]+)') {
                    $matches[1]
                } elseif ($_.Message -match 'SSID\s*=\s*([^\s\n\r]+)') {
                    $matches[1]
                } else {
                    "Unknown"
                }
            }}
        
        foreach ($profile in $profiles) {
            $lastConnection = $wifiEvents | 
                Where-Object { $_.SSID -eq $profile } | 
                Sort-Object TimeCreated -Descending | 
                Select-Object -First 1
            
            Write-Host "  SSID: $profile"
            if ($lastConnection) {
                Write-Host "   Last Connection: $($lastConnection.TimeCreated)"
            } else {
                Write-Host "   Last Connection: Never connected or no logs available"
            }
            
            # Get Wi-Fi profile details
            $profileDetails = netsh wlan show profile name="$profile" key=clear 2>$null
            if ($profileDetails) {
                $auth = $profileDetails | Select-String "Authentication\s*:\s*(.+)"
                $cipher = $profileDetails | Select-String "Cipher\s*:\s*(.+)"
                if ($auth) { Write-Host "    Authentication: $($auth.Matches.Groups[1].Value.Trim())" }
                if ($cipher) { Write-Host "    Cipher: $($cipher.Matches.Groups[1].Value.Trim())" }
            }
            Write-Host ""
        }
    } else {
        Write-Host "No saved Wi-Fi profiles"
    }
} else {
    Write-Host "Error retrieving Wi-Fi profiles"
}

# TCP Connections
Write-Host "Active TCP Connections"
Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | 
    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, @{
        Name='Process';
        Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}
    } | Format-Table -AutoSize

Write-Host "`nTCP Ports and owning processes:"
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | 
    Select-Object LocalPort, OwningProcess -Unique | 
    ForEach-Object { 
        $p = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        if (-not $p) { $p = "Unknown" }
        Write-Host "TCP Port: $($_.LocalPort) - Process: $p"
    }

Write-Host "`nUDP Ports and owning processes:"
Get-NetUDPEndpoint -ErrorAction SilentlyContinue | 
    Select-Object LocalPort, OwningProcess -Unique | 
    ForEach-Object { 
        $p = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        if (-not $p) { $p = "Unknown" }
        Write-Host "UDP Port: $($_.LocalPort) - Process: $p"
    }

# Network Shares
Write-Host "`nNetwork Shares"
$shares = Get-SmbShare -ErrorAction SilentlyContinue
if ($shares) {
    Write-Host "Shares available on this device:"
    $shares | Format-Table Name, Path, Description -AutoSize
} else {
    Write-Host "No network shares"
}