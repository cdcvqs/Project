# Header Information
Write-Host "System Information:"
Write-Host "  Date/Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "  Computer:  $env:COMPUTERNAME"
Write-Host "  User:      $env:USERNAME"
Write-Host ""

# Operating System
Write-Host "Operating System:"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $systemInfo = systeminfo | Select-String -Pattern "Host Name|OS Name|OS Version|OS Manufacturer|OS Configuration|OS Build Type|Registered Owner|Original Install Date|System Manufacturer|System Type|BIOS Version|System Locale|Input Locale|Time Zone"
    
    if ($systemInfo) {
        $systemInfo | ForEach-Object {
            Write-Host "  $_"
        }
    } else {
        Write-Host "  OS Name: $($os.Caption)"
        Write-Host "  Version: $($os.Version)"
        Write-Host "  Build: $($os.BuildNumber)"
        Write-Host "  Manufacturer: $($os.Manufacturer)"
        Write-Host "  Install Date: $(if($os.InstallDate){[Management.ManagementDateTimeConverter]::ToDateTime($os.InstallDate).ToString('yyyy-MM-dd')}else{'Unknown'})"
    }
} catch {
    Write-Host "  Error retrieving OS information"
}
Write-Host ""

# CPU
Write-Host "CPU:"
try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    if ($cpu) {
        Write-Host "  $($cpu.Name)"
        Write-Host "  Cores: $($cpu.NumberOfCores) Physical, $($cpu.NumberOfLogicalProcessors) Logical"
        Write-Host "  Max Speed: $($cpu.MaxClockSpeed) MHz"
    } else {
        Write-Host "  CPU information not available"
    }
} catch {
    Write-Host "  Error retrieving CPU information"
}
Write-Host ""

# GPU
Write-Host "GPU:"
try {
    $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop
    if ($gpus) {
        foreach ($gpu in $gpus) {
            Write-Host "  $($gpu.Name)"
            Write-Host "    Adapter RAM: $(if($gpu.AdapterRAM){[math]::Round($gpu.AdapterRAM/1MB, 2)}else{0}) MB"
            Write-Host "    Driver Version: $($gpu.DriverVersion)"
        }
    } else {
        Write-Host "  GPU information not available"
    }
} catch {
    Write-Host "  Error retrieving GPU information"
}
Write-Host ""

# Memory
Write-Host "Memory:"
try {
    $mem = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $total = [math]::Round($mem.TotalVisibleMemorySize/1KB, 2)
    $free = [math]::Round($mem.FreePhysicalMemory/1KB, 2)
    $used = $total - $free
    
    Write-Host "  Total Memory: $total MB"
    Write-Host "  Used Memory: $used MB"
    Write-Host "  Free Memory: $free MB"
    Write-Host "  Usage: $([math]::Round(($used/$total)*100, 2))%"
} catch {
    Write-Host "  Error retrieving memory information"
}
Write-Host ""

# Memory slots
Write-Host "Memory Slots:"
try {
    $memoryModules = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
    if ($memoryModules) {
        foreach ($module in $memoryModules) {
            Write-Host "  Slot $($module.DeviceLocator): $([math]::Round($module.Capacity/1GB, 2)) GB $($module.Manufacturer) $($module.PartNumber) ($($module.Speed) MHz)"
        }
        $totalRAM = ($memoryModules | Measure-Object -Property Capacity -Sum).Sum
        Write-Host "  Total Installed: $([math]::Round($totalRAM/1GB, 2)) GB"
    } else {
        Write-Host "  No memory module information available"
    }
} catch {
    Write-Host "  Error retrieving memory slot information"
}
Write-Host ""

# System performance
Write-Host "System Performance:"
try {
    $cpuLoad = (Get-CimInstance Win32_Processor -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average).Average
    $mem = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $memUsed = [math]::Round((($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize) * 100, 1)
    
    Write-Host "  CPU Usage: $cpuLoad %"
    Write-Host "  Memory Usage: $memUsed %"
} catch {
    Write-Host "  Error retrieving performance information"
}
Write-Host ""

# Physical disks
Write-Host "Physical Disks:"
try {
    $disks = Get-CimInstance Win32_DiskDrive -ErrorAction Stop
    if ($disks) {
        foreach ($disk in $disks) {
            $diskType = if ($disk.Model -match 'SSD') {
                'SSD'
            } elseif ($disk.MediaType -match 'Fixed hard disk media') {
                'HDD'
            } elseif ($disk.SpindleSpeed -eq 0) {
                'SSD'
            } elseif ($disk.SpindleSpeed -gt 0) {
                'HDD'
            } else {
                'Unknown'
            }
            
            Write-Host "  Disk: $($disk.DeviceID)"
            Write-Host "    Model: $($disk.Model)"
            Write-Host "    Type: $diskType"
            Write-Host "    Size: $([math]::Round($disk.Size/1GB, 2)) GB"
            Write-Host "    Interface: $($disk.InterfaceType)"
        }
    } else {
        Write-Host "  No disk information available"
    }
} catch {
    Write-Host "  Error retrieving disk information"
}
Write-Host ""

# Logical drives
Write-Host "Logical Drives:"
try {
    $drives = Get-CimInstance Win32_LogicalDisk -ErrorAction Stop
    if ($drives) {
        foreach ($drive in $drives) {
            $driveType = switch ($drive.DriveType) {
                0 { 'Unknown' }
                1 { 'No Root Directory' }
                2 { 'Removable Disk' }
                3 { 'Local Disk' }
                4 { 'Network Drive' }
                5 { 'CD-ROM' }
                6 { 'RAM Disk' }
                default { 'Other' }
            }
            
            $total = if ($drive.Size) { [math]::Round($drive.Size/1GB, 2) } else { 0 }
            $free = if ($drive.FreeSpace) { [math]::Round($drive.FreeSpace/1GB, 2) } else { 0 }
            $used = [math]::Round($total - $free, 2)
            $percent = if ($total -gt 0) { [math]::Round(($used/$total)*100, 2) } else { 0 }
            
            Write-Host "  Drive $($drive.DeviceID): $driveType ($($drive.FileSystem))"
            Write-Host "    Total: $total GB | Used: $used GB | Free: $free GB | Usage: $percent%"
        }
    } else {
        Write-Host "  No logical drive information available"
    }
} catch {
    Write-Host "  Error retrieving logical drive information"
}
Write-Host ""

# Disk health status
Write-Host "Disk Health Status (SMART):"
try {
    $smart = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus -ErrorAction Stop
    if ($smart) {
        foreach ($disk in $smart) {
            $status = if (-not $disk.PredictFailure) { 
                'OK' 
            } else { 
                'FAILING - Backup data immediately!' 
            }
            Write-Host "  $($disk.InstanceName): $status"
        }
    } else {
        Write-Host "  No SMART data available"
    }
} catch {
    Write-Host "  SMART status not available on this system"
}
Write-Host ""

Write-Host "Battery Status:"

try {
    $battery = Get-CimInstance Win32_Battery -ErrorAction Stop

    if (-not $battery) {
        Write-Host "  No battery detected (Desktop PC)"
        return
    }

    # Read real capacity data from WMI
    $designCap = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue
    $fullCap   = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue

    foreach ($bat in $battery) {
        $status = switch ($bat.BatteryStatus) {
            1  { 'Discharging' }
            2  { 'On AC Power' }
            3  { 'Fully Charged' }
            4  { 'Low' }
            5  { 'Critical' }
            6  { 'Charging' }
            7  { 'Charging and High' }
            8  { 'Charging and Low' }
            9  { 'Charging and Critical' }
            10 { 'Undefined' }
            11 { 'Partially Charged' }
            default { 'Unknown' }
        }

        Write-Host "  Battery Level: $($bat.EstimatedChargeRemaining)%"
        Write-Host "  Status: $status"

        if ($designCap.DesignedCapacity) {
            Write-Host "  Design Capacity: $($designCap.DesignedCapacity) mWh"
        } 

        if ($fullCap.FullChargedCapacity) {
            Write-Host "  Full Charge Capacity: $($fullCap.FullChargedCapacity) mWh"
        } 
    }

} catch {
    Write-Host "  Battery information not available"
}

Write-Host ""

# Last system boot
Write-Host "Last System Boot:"
try {
    $bootTime = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    Write-Host "  $($bootTime.ToString('yyyy-MM-dd HH:mm:ss'))"
} catch {
    Write-Host "  Error retrieving boot time"
}
Write-Host ""

# System Uptime
Write-Host "System Uptime:"
try {
    $lastBoot = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    $uptime = (Get-Date) - $lastBoot
    Write-Host "  $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
} catch {
    Write-Host "  Error calculating uptime"
}