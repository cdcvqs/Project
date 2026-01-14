# Get-GPU-Info.ps1
# Detailed GPU information (no colored output). English only.
# Works on Windows PowerShell / PowerShell Core (queries WMI/CIM and performance counters if available).

function Get-GPUInfo {
    try {
        $gpus = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop
    } catch {
        Write-Output "ERROR: Unable to query Win32_VideoController: $($_.Exception.Message)"
        return @()
    }

    $result = @()
    foreach ($g in $gpus) {
        # Convert driver date (if present)
        $driverDate = $null
        if ($g.DriverDate) {
            try {
                $driverDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($g.DriverDate)
            } catch {
                $driverDate = $g.DriverDate
            }
        }

        $adapterRAMMB = $null
        if ($g.AdapterRAM -ne $null) {
            $adapterRAMMB = [math]::Round($g.AdapterRAM / 1MB, 2)
        }

        $currentRes = if ($g.CurrentHorizontalResolution -and $g.CurrentVerticalResolution) {
            "$($g.CurrentHorizontalResolution) x $($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate)Hz"
        } else {
            $g.VideoModeDescription
        }

        $obj = [PSCustomObject]@{
            'Index'                    = $g.DeviceID
            'Name'                     = $g.Name
            'PNPDeviceID'              = $g.PNPDeviceID
            'VideoProcessor'           = $g.VideoProcessor
            'AdapterCompatibility'     = $g.AdapterCompatibility
            'DriverVersion'            = $g.DriverVersion
            'DriverDate'               = $driverDate
            'AdapterRAM (MB)'          = $adapterRAMMB
            'CurrentResolution'        = $currentRes
            'VideoModeDescription'     = $g.VideoModeDescription
            'InstalledDisplayDrivers'  = $g.InstalledDisplayDrivers
            'InfName'                  = $g.InfName
            'Status'                   = $g.Status
        }
        $result += $obj
    }

    return $result
}

function Get-GPUDrivers {
    try {
        $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop |
                   Where-Object { ($_.DeviceClass -eq 'DISPLAY') -or ($_.DeviceName -like '*Display*') -or ($_.DeviceName -like '*Video*') }
    } catch {
        Write-Output "WARNING: Unable to query Win32_PnPSignedDriver: $($_.Exception.Message)"
        return @()
    }

    $drivers | Select-Object DeviceName, Manufacturer, DriverVersion, DriverDate, InfName, DriverProviderName
}

function Get-DirectXVersion {
    try {
        $dx = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\DirectX' -ErrorAction Stop
        return $dx.Version
    } catch {
        return $null
    }
}

# --- Main output (no colors) ---
Write-Output "=== GPU HARDWARE INFO ==="
$gpuInfo = Get-GPUInfo
if ($gpuInfo -and $gpuInfo.Count -gt 0) {
    # Print each GPU with a clear separator
    $i = 1
    foreach ($g in $gpuInfo) {
        Write-Output ""
        Write-Output "GPU #$i - $($g.Name)"
        $g.PSObject.Properties | Sort-Object Name | Format-List
        $i++
    }
} else {
    Write-Output "No GPUs found or failed to retrieve GPU information."
}

Write-Output "`n=== GPU DRIVER DETAILS ==="
$drivers = Get-GPUDrivers
if ($drivers -and $drivers.Count -gt 0) {
    $drivers | Format-Table -AutoSize
} else {
    Write-Output "No driver details found."
}