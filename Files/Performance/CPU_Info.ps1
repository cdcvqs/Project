# Get WMI/CIM Processor Information
$cpuInfo = Get-CimInstance -ClassName Win32_Processor

# Basic CPU Information
Write-Host "Basic information"
$cpuInfo | ForEach-Object {
    Write-Host "Processor Name:        $($_.Name)"
    Write-Host "Architecture:          $(switch($_.Architecture){0{'x86'} 1{'MIPS'} 2{'Alpha'} 3{'PowerPC'} 5{'ARM'} 6{'Itanium'} 9{'x64'} default{'Unknown'}})"
    Write-Host "Manufacturer:          $($_.Manufacturer)"
    Write-Host "Description:           $($_.Caption)"
    Write-Host "Device ID:             $($_.DeviceID)"
    Write-Host "Socket Designation:    $($_.SocketDesignation)"
}

# Core/Thread Configuration
Write-Host "`nCore/thread configuration"
$cpuInfo | ForEach-Object {
    Write-Host "Physical Cores:        $($_.NumberOfCores)"
    Write-Host "Logical Processors:    $($_.NumberOfLogicalProcessors)"
    Write-Host "Thread Count:          $($_.ThreadCount)"
    Write-Host "HyperThreading:        $(if($_.NumberOfLogicalProcessors -gt $_.NumberOfCores) {'Enabled'} else {'Disabled'})"
}

# Cache Information
Write-Host "`nCACHE INFORMATION"
$cpuInfo | ForEach-Object {
    Write-Host "L2 Cache Size:         $([math]::Round($_.L2CacheSize/1024, 2)) MB"
    Write-Host "L2 Cache Speed:        $($_.L2CacheSpeed) MHz"
    Write-Host "L3 Cache Size:         $([math]::Round($_.L3CacheSize/1024, 2)) MB"
    Write-Host "L3 Cache Speed:        $($_.L3CacheSpeed) MHz"
}

# Current Status
Write-Host "`nCurrent status"
$cpuInfo | ForEach-Object {
    Write-Host "Current Clock Speed:   $($_.CurrentClockSpeed) MHz"
    Write-Host "Max Clock Speed:       $($_.MaxClockSpeed) MHz"
    Write-Host "Load Percentage:       $($_.LoadPercentage)%"
    Write-Host "Status:                $($_.Status)"
    Write-Host "Availability:          $(switch($_.Availability){1{'Other'} 2{'Unknown'} 3{'Running/Full Power'} 4{'Warning'} 5{'In Test'} 6{'Not Applicable'} 7{'Power Off'} 8{'Off Line'} 9{'Off Duty'} 10{'Degraded'} 11{'Not Installed'} 12{'Install Error'} 13{'Power Save - Unknown'} 14{'Power Save - Low Power Mode'} 15{'Power Save - Standby'} 16{'Power Cycle'} 17{'Power Save - Warning'} 18{'Paused'} 19{'Not Ready'} 20{'Not Configured'} 21{'Quiesced'} default{'Unknown'}})"
}

# Power Management
Write-Host "`nPower management"
$cpuInfo | ForEach-Object {
    Write-Host "CPU Status:            $($_.CpuStatus)"
    Write-Host "Power Management:      $(if($_.PowerManagementSupported){'Supported'} else {'Not Supported'})"
}

# Technical Details
Write-Host "`nTechnical details"
$cpuInfo | ForEach-Object {
    Write-Host "Processor ID:          $($_.ProcessorId)"
    Write-Host "Processor Type:        $(switch($_.ProcessorType){1{'Other'} 2{'Unknown'} 3{'Central Processor'} 4{'Math Processor'} 5{'DSP Processor'} 6{'Video Processor'} default{'Unknown'}})"
    Write-Host "Role:                  $($_.Role)"
    Write-Host "Upgrade Method:        $(switch($_.UpgradeMethod){1{'Other'} 2{'Unknown'} 3{'Daughter Board'} 4{'ZIF Socket'} 5{'Replaceable Piggy Back'} 6{'None'} 7{'LIF Socket'} 8{'Slot 1'} 9{'Slot 2'} 10{'370 Pin Socket'} 11{'Slot A'} 12{'Slot M'} 13{'Socket 423'} 14{'Socket A (Socket 462)'} 15{'Socket 478'} 16{'Socket 754'} 17{'Socket 940'} 18{'Socket 939'} 19{'Socket mPGA604'} 20{'Socket LGA771'} 21{'Socket LGA775'} 22{'Socket S1'} 23{'Socket AM2'} 24{'Socket F (1207)'} 25{'Socket LGA1366'} 26{'Socket G34'} 27{'Socket AM3'} 28{'Socket C32'} 29{'Socket LGA1156'} 30{'Socket LGA1567'} 31{'Socket PGA988A'} 32{'Socket BGA1288'} 33{'Socket rPGA988B'} 34{'Socket BGA1023'} 35{'Socket BGA1224'} 36{'Socket LGA1155'} 37{'Socket LGA1356'} 38{'Socket LGA2011'} 39{'Socket FS1'} 40{'Socket FS2'} 41{'Socket FM1'} 42{'Socket FM2'} default{'Unknown'}})"
}

# Advanced Information using Get-ComputerInfo
Write-Host "`nAdvanced information"
try {
    $compInfo = Get-ComputerInfo
    Write-Host "Hyper-V Requirements:   $(if($compInfo.CsHypervisorPresent){'Present'} else {'Not Present'})"
    Write-Host "Virtualization Firmware:$(if($compInfo.CsVirtualizationFirmwareEnabled){'Enabled'} else {'Disabled'})"
} catch {
    Write-Host "Advanced Info:         Not Available"
}

# Processor Features (if available)
Write-Host "`nProcessor features"
try {
    $features = Get-WmiObject -Class Win32_Processor | Select-Object *
    if ($features -ne $null) {
        if ($features.VirtualizationFirmwareEnabled -ne $null) {
            Write-Host "Virtualization:        $(if($features.VirtualizationFirmwareEnabled){'Enabled'} else {'Disabled'})"
        }
        if ($features.SecondLevelAddressTranslationExtensions -ne $null) {
            Write-Host "SLAT (EPT/RVI):        $(if($features.SecondLevelAddressTranslationExtensions){'Yes'} else {'No'})"
        }
    }
} catch {
    Write-Host "Features Info:         Not Available"
}