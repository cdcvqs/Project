@echo off
setlocal enabledelayedexpansion
title Windows Optimization Tool

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run as Administrator
    echo Right-click and choose "Run as administrator"
    pause
    exit
)

:MENU
cls
echo.
echo                                                           \\!//
echo                                                           (o o)
echo                        -------------------------------oOOo-(_)-oOOo-------------------------------
echo.
echo                            [1] Performance                                       [2] Security
echo.
echo                            [3] Network                                           [4] Programs
echo.
echo                            [5] Customization                                     [6] System
echo.
echo                            [7] Tools                                             [8] Other
echo.
echo                                                          [0] Exit
echo.
echo                        ---------------------------------------------------------------------------
echo.
echo.

set /p choice="Select an option: "
if "%choice%"=="1" goto PERFORMANCE_MENU
if "%choice%"=="2" goto PRIVACY_SECURITY_MENU
if "%choice%"=="3" goto NETWORK_MENU
if "%choice%"=="4" goto PROGRAMS_MENU
if "%choice%"=="5" goto CUSTOMIZATION_MENU
if "%choice%"=="6" goto SYSTEM_MENU
if "%choice%"=="7" goto TOOLS_MENU
if "%choice%"=="8" goto OTHER_MENU
if "%choice%"=="0" exit

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-8)
pause
goto MENU

:PERFORMANCE_MENU
cls & echo. & echo.
echo                        ------------------------------- Performance ------------------------------
echo.
echo                          [1] Services                                       [2] Scheduler task
echo.
echo                          [3] Speed up boot                                  [4] BCD
echo.
echo                          [5] Clean up                                       [6] Power plan 
echo.
echo                          [7] Visual effects                                 [8] Hrdware info
echo.
echo                                                         [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" goto SERVICES_MENU
if "%choice%"=="2" (
    set Routine=TASK_TWEAKS
    set Rev_Routine=REV_TASK
    set Apply=Disable unnecessary scheduled tasks
	set Revert=Reset scheduled tasks to default settings
    set menu=PERFORMANCE_MENU
    goto SUB_MENU
)
if "%choice%"=="3" (
    set Routine=BOOT
    set Rev_Routine=REV_BOOT
    set Apply=Speed up system startup
	set Revert=Set boot settings to default
    set menu=PERFORMANCE_MENU
    goto SUB_MENU
)
if "%choice%"=="4" (
    set Routine=BCD
    set Rev_Routine=REV_BCD
    set Apply=BCD tweaks
	set Revert=Default BCD
    set menu=PERFORMANCE_MENU
    goto SUB_MENU
)
if "%choice%"=="5" goto CLEAN_UP
if "%choice%"=="6" goto POWER_PLAN_MENU
if "%choice%"=="7" goto VISUAL_EFFECTS
if "%choice%"=="8" goto HW_INFO
if "%choice%"=="0" goto MENU
echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-8)
pause
goto PERFORMANCE_MENU

:SERVICES_MENU
cls & echo. & echo.
echo                        -------------------------------- Services ---------------------------------
echo.
echo                          [1] Services Tweaks                                [2] Services Tweaks(Safe)
echo.
echo                          [3] Default services                               [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" (
    set Log=Service_Tweaks
    set File=%~dp0Files\Performance\Services_Tweaks.txt
    goto SET_SERVICES
)
if "%choice%"=="2" (
    set Log=Service_Tweaks_Safe
    set File=%~dp0Files\Performance\Services_Tweaks_Safe.txt
    goto SET_SERVICES
)
if "%choice%"=="3" (
    set Log=Restore_Services
    set File=%~dp0Files\Performance\Default_Services.txt
    goto SET_SERVICES
)
if "%choice%"=="4" goto HW_INFO
echo. & echo [ERROR] Invalid selection. Please choose a valid option between 
pause
goto MENU "(0-3)" "PERFORMANCE_MENU"

:SET_SERVICES
cls & echo Configure system services...
call :PATH "Services" "%Log%"

for /f "usebackq tokens=1,2 delims=," %%A in ("%File%") do (
    if not "%%A"=="" (
        if not "%%A:~0,1%"=="#" (
            set "SVC=%%A"
            set "MODE=%%B"
			
            echo !SVC! -> !MODE!
            
            set "RESULT=SUCCESS"
            
            if /I "!MODE!"=="Automatic" (
                sc config "!SVC!" start= auto >nul 2>&1
                if errorlevel 1 (
                    sc query "!SVC!" >nul 2>&1
                    if errorlevel 1 (
                        set "RESULT=NOT_FOUND"
                    ) else (
                        set "RESULT=FAILED"
                    )
                )
            ) else if /I "!MODE!"=="Manual" (
                sc config "!SVC!" start= demand >nul 2>&1
                if errorlevel 1 (
                    sc query "!SVC!" >nul 2>&1
                    if errorlevel 1 (
                        set "RESULT=NOT_FOUND"
                    ) else (
                        set "RESULT=FAILED"
                    )
                )
            ) else if /I "!MODE!"=="Disabled" (
                sc config "!SVC!" start= disabled >nul 2>&1
                if errorlevel 1 (
                    sc query "!SVC!" >nul 2>&1
                    if errorlevel 1 (
                        set "RESULT=NOT_FOUND"
                    ) else (
                        set "RESULT=FAILED"
                    )
                )
            ) else if /I "!MODE!"=="AutomaticDelayedStart" (
                sc config "!SVC!" start= delayed-auto >nul 2>&1
                if errorlevel 1 (
                    sc query "!SVC!" >nul 2>&1
                    if errorlevel 1 (
                        set "RESULT=NOT_FOUND"
                    ) else (
                        set "RESULT=FAILED"
                    )
                )
            )          
            echo !SVC! _ !MODE!  : !RESULT! >> "!LogFile!"
        )
    )
)

call :GO SERVICES_MENU

:TASK_TWEAKS
cls & echo Disable unnecessary scheduled tasks...
call :PATH "Scheduled_Tasks" "Disable_Scheduled_Tasks"

for /f "tokens=*" %%i in (%~dp0Files\Performance\Tasks_List.txt) do (

    set "TASK_NAME=%%i"
    set "TASK_RESULT=SUCCESS"
    
    schtasks /change /tn "%%i" /disable >nul 2>&1
    if errorlevel 1 (
        schtasks /query /tn "%%i" >nul 2>&1
        if errorlevel 1 (
            set "TASK_RESULT=NOT_FOUND"
        ) else (
            set "TASK_RESULT=FAILED"
        )
    )
    
    echo !TASK_NAME!: !TASK_RESULT! >> "%LogFile%" 2>&1
)

call :GO PERFORMANCE_MENU

:REV_TASK
cls & echo Enable scheduled tasks...
call :PATH "Scheduled_Tasks" "Restore_Scheduled_Tasks"

for /f "tokens=*" %%i in (%~dp0Files\Performance\Tasks_List.txt) do (
    set "TASK_NAME=%%i"
    set "TASK_RESULT=SUCCESS"
    
    schtasks /change /tn "%%i" /enable >nul 2>&1
    if errorlevel 1 (
        schtasks /query /tn "%%i" >nul 2>&1
        if errorlevel 1 (
            set "TASK_RESULT=NOT_FOUND"
        ) else (
            set "TASK_RESULT=FAILED"
        )
    )
    
    echo !TASK_NAME!: !TASK_RESULT! >> "%LogFile%" 2>&1
)

call :GO PERFORMANCE_MENU

:BOOT
cls & echo Applying Boot Optimizations

bcdedit /timeout 2 >nul 2>&1
bcdedit /set bootux Disabled >nul 2>&1
 
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 2000 /f >nul 2>&1

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul 2>&1

reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /va /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /va /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /va /f >nul 2>&1
reg delete "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /va /f >nul 2>&1

del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*.lnk" >nul 2>&1
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\*.lnk" >nul 2>&1

call :GO PERFORMANCE_MENU

:REV_BOOT
cls & echo Restoring Default Boot Settings

bcdedit /timeout 10 >nul 2>&1
bcdedit /deletevalue bootux >nul 2>&1

reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 5000 /f >nul 2>&1

reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /f >nul 2>&1

call :GO PERFORMANCE_MENU

:BCD
cls & echo Creating backup of BCD settings
call :PATH "BCD" "BCD_Tweaks"

bcdedit /export %ProgramData%\Windows_Optimization_Script\BCD\BCD_Backup >> "%LogFile%" 2>&1

echo Removing useplatformclock setting
bcdedit /deletevalue useplatformclock >> "%LogFile%" 2>&1

echo Removing disabledynamictick setting
bcdedit /deletevalue disabledynamictick >> "%LogFile%" 2>&1

echo Setting TSC sync policy to Enhanced
bcdedit /set tscsyncpolicy Enhanced >> "%LogFile%" 2>&1

echo Enabling x2APIC policy
bcdedit /set x2apicpolicy Enable >> "%LogFile%" 2>&1

echo Setting config access policy to Default
bcdedit /set configaccesspolicy Default >> "%LogFile%" 2>&1

echo Setting MSI to Default
bcdedit /set MSI Default >> "%LogFile%" 2>&1

echo Disabling use of physical destination
bcdedit /set usephysicaldestination No >> "%LogFile%" 2>&1

echo Disabling use of firmware PCI settings
bcdedit /set usefirmwarepcisettings No >> "%LogFile%" 2>&1

echo Applying useplatformtick
bcdedit /set useplatformtick yes >> "%LogFile%" 2>&1

echo Applying uselegacyapicmode
bcdedit /set uselegacyapicmode no >> "%LogFile%" 2>&1

echo Applying testsigning
bcdedit /set testsigning No >> "%LogFile%" 2>&1

echo All performance optimizations applied successfully
call :GO PERFORMANCE_MENU

:REV_BCD
cls & echo Restoring original BCD settings
call :PATH "BCD" "Default_BCD"

bcdedit /import %ProgramData%\Windows_Optimization_Script\BCD\BCD_Backup >> "%LogFile%" 2>&1

if %errorlevel% neq 0 (
    echo BCD file import failed. Executing alternative commands
    echo Removing useplatformclock setting
    bcdedit /deletevalue useplatformclock >> "%LogFile%" 2>&1
	
    echo Removing disabledynamictick setting
    bcdedit /deletevalue disabledynamictick >> "%LogFile%" 2>&1
	
    echo Removing tscsyncpolicy setting
    bcdedit /deletevalue tscsyncpolicy >> "%LogFile%" 2>&1
	
    echo Removing x2apicpolicy setting
    bcdedit /deletevalue x2apicpolicy >> "%LogFile%" 2>&1
	
    echo Removing configaccesspolicy setting
    bcdedit /deletevalue configaccesspolicy >> "%LogFile%" 2>&1
	
    echo Removing MSI setting
    bcdedit /deletevalue MSI >> "%LogFile%" 2>&1
	
    echo Enabling use of physical destination
    bcdedit /set usephysicaldestination Yes >> "%LogFile%" 2>&1
	
    echo Enabling use of firmware PCI settings
    bcdedit /set usefirmwarepcisettings Yes >> "%LogFile%" 2>&1
	
	echo Restoring useplatformtick
    bcdedit /deletevalue useplatformtick >> "%LogFile%" 2>&1

    echo Restoring uselegacyapicmode
    bcdedit /deletevalue uselegacyapicmode >> "%LogFile%" 2>&1

    echo Restoring testsigning
    bcdedit /deletevalue testsigning >> "%LogFile%" 2>&1
	
    echo Successfully restored to default settings
) else (
    echo Original BCD settings restored successfully
)

call :GO PERFORMANCE_MENU

:CLEAN_UP
cls & 	echo Cleaning Temp
for %%F in (
	"%LOCALAPPDATA%\Temp"
	"%SystemDrive%\Temp"
    "%TEMP%"
    "%AppData%\Temp"
    "%HomePath%\AppData\LocalLow\Temp"
) do (
    rd /s /q "%%~F" >nul 2>&1
    del /s /f /q "%%~F\*.*" >nul 2>&1
	md "%%~F" >nul 2>&1
)

echo Cleaning Recent Files
del /q "%APPDATA%\Microsoft\Windows\Recent\*.lnk" >nul 2>&1

echo Cleaning Thumbnail and icons cache
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache*.db" >nul 2>&1
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" >nul 2>&1

echo Cleaning Update Files
sc stop wuauserv >nul 2>&1
sc stop bits >nul 2>&1

rd /s /q "%WINDIR%\SoftwareDistribution" >nul 2>&1
md "%WINDIR%\SoftwareDistribution" >nul 2>&1

sc start wuauserv >nul 2>&1
sc start bits >nul 2>&1

set "BROWSERS=chrome.exe brave.exe msedge.exe firefox.exe"
set BROWSERS_OPEN=0

for %%B in (%BROWSERS%) do (
    tasklist /FI "IMAGENAME eq %%B" 2>nul | find /I "%%B" >nul
    if not errorlevel 1 (
        set BROWSERS_OPEN=1
    )
)

if !BROWSERS_OPEN! equ 1 (
    set /p CLOSE_BROWSERS="Browsers are currently open. Do you want to close them? (y/n): "
    if /i "!CLOSE_BROWSERS!"=="y" (
        echo Closing browsers...
        for %%B in (%BROWSERS%) do (
            taskkill /IM "%%B" /F /T >nul 2>&1
        )
        timeout /t 2 >nul
    ) else (
        echo Skipping files currently used by browsers
    )
) else (
    echo No browsers are currently running
)

if exist "%LOCALAPPDATA%\Google\Chrome\User Data" (
    echo  Cleaning Google Chrome
    for /d %%p in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
        rd /s /q "%%p\Cache" >nul 2>&1
        rd /s /q "%%p\Cache2" >nul 2>&1
        rd /s /q "%%p\Code Cache" >nul 2>&1
        rd /s /q "%%p\GPUCache" >nul 2>&1
    )
)

if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data" (
    echo  Cleaning Brave Browser
    for /d %%p in ("%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\*") do (
        rd /s /q "%%p\Cache" >nul 2>&1
        rd /s /q "%%p\Cache2" >nul 2>&1
        rd /s /q "%%p\Code Cache" >nul 2>&1
        rd /s /q "%%p\GPUCache" >nul 2>&1
    )
)

if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data" (
    echo  Cleaning Microsoft Edge
    for /d %%p in ("%LOCALAPPDATA%\Microsoft\Edge\User Data\*") do (
        rd /s /q "%%p\Cache" >nul 2>&1
        rd /s /q "%%p\Cache2" >nul 2>&1
        rd /s /q "%%p\Code Cache" >nul 2>&1
        rd /s /q "%%p\GPUCache" >nul 2>&1
    )
)

if exist "%APPDATA%\Mozilla\Firefox\Profiles" (
    echo  Cleaning Firefox
    for /d %%p in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
        rd /s /q "%%p\cache2" >nul 2>&1
        rd /s /q "%%p\startupCache" >nul 2>&1
        rd /s /q "%%p\thumbnails" >nul 2>&1
    )
)

choice /C YN /N /M "Do you want to run the Disk Cleanup to complete the cleaning? (Y/N): "
if !errorlevel! equ 1 (
    echo Running Disk Cleanup
    cleanmgr /d C
)

echo Empty Recycle Bin
powershell -command "Clear-RecycleBin -Force -Confirm:$false"

call :GO PERFORMANCE_MENU

:VISUAL_EFFECTS
cls & echo Opening Visual effects Performance Options
start SystemPropertiesPerformance
call :GO PERFORMANCE_MENU


:POWER_PLAN_MENU
cls & echo. & echo.
echo                        ------------------------------- Power Plan --------------------------------
echo.
echo                          [1] High Performance                                  [2] Balanced
echo.
echo                          [3] Power Saver                                       [4] Active Plan
echo.
echo                                                         [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" goto PLAN_HIGH
if "%choice%"=="2" goto PLAN_BALANCED
if "%choice%"=="3" goto PLAN_SAVER
if "%choice%"=="4" goto ACTIVE_PLAN
if "%choice%"=="0" goto PERFORMANCE_MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-3)
pause
goto POWER_PLAN_MENU

:PLAN_HIGH
cls & echo Activating High Performance power plan
powercfg /setactive SCHEME_MIN >nul
call :GO POWER_PLAN_MENU

:PLAN_BALANCED
cls & echo Activating Balanced power plan
powercfg /setactive SCHEME_BALANCED >nul
call :GO POWER_PLAN_MENU

:PLAN_SAVER
cls & echo Activating Power Saver plan
powercfg /setactive SCHEME_MAX >nul
call :GO POWER_PLAN_MENU

:ACTIVE_PLAN
cls
set "TMP_FILE=%TEMP%\active_power_plan.guid"
powercfg /getactivescheme > "%TMP_FILE%" 2>&1

for /f "tokens=4" %%A in (%TMP_FILE%) do (
    set "PLAN_GUID=%%A"
)

set "PLAN_GUID=%PLAN_GUID: =%"

if /I "!PLAN_GUID!"=="381b4222-f694-41f0-9685-ff5bb260df2e" (
    set "PLAN_NAME=Balanced"
) else if /I "!PLAN_GUID!"=="8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" (
    set "PLAN_NAME=High Performance"
) else if /I "!PLAN_GUID!"=="a1841308-3541-4fab-bc81-f71556f20b4a" (
    set "PLAN_NAME=Power Saver"
) else if /I "!PLAN_GUID!"=="e9a42b02-d5df-448d-aa00-03f14749eb61" (
    set "PLAN_NAME=Ultimate Performance"
) else (
    set "PLAN_NAME=Unknown Power Plan"
)

echo Active Power Plan GUID : !PLAN_GUID!
echo Active Power Plan Name : !PLAN_NAME!

del "%TMP_FILE%" >nul 2>&1
call :GO POWER_PLAN_MENU


:HW_INFO
cls & echo. & echo.
echo                        -------------------------------- HW Info ----------------------------------
echo.
echo                          [1] CPU                                                   [2] GPU
echo. 
echo                          [3] Hard Disk                                             [4] RAM
echo. 
echo                          [5] Battery                                               [0] Back
echo.
echo                        ---------------------------------------------------------------------------
echo.
set /p choice="Select an option: "

if "%choice%"=="1" goto CPU
if "%choice%"=="2" goto GPU
if "%choice%"=="3" goto HARD_DISK
if "%choice%"=="4" goto RAM
if "%choice%"=="5" goto BATTERY
if "%choice%"=="0" goto PERFORMANCE_MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-5)
pause
goto HW_INFO

:CPU
cls & powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Files\Performance\CPU_Info.ps1"
call :GO HW_INFO

:GPU
cls & powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Files\Performance\GPU_Info.ps1"
call :GO HW_INFO

:HARD_DISK
cls & echo Physical disks:
wmic diskdrive list brief

wmic diskdrive get model, size

wmic diskdrive get model, size, partitions, interfaceType, status

call :GO HW_INFO

:RAM
cls & echo Memory usage

wmic OS get TotalVisibleMemorySize, FreePhysicalMemory

wmic memorychip get Capacity, Speed

call :GO HW_INFO

:BATTERY
cls & echo Creating battery report...
powercfg /batteryreport /output "battery-report.html"
call :GO HW_INFO


:PRIVACY_SECURITY_MENU
cls & echo. & echo.
echo                        --------------------------- Privacy and security --------------------------
echo.
echo                          [1] Disable Telemetry                             [2] Privacy Cleanup
echo.
echo                          [3] Windows Updates                               [4] Windows Defender
echo.
echo                          [5] Enhance Security                              [6] Security Information
echo.
echo                                                         [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo.& set /p choice="Select an option: "
if "%choice%"=="1" goto DISABLE_TELEMETRY
if "%choice%"=="2" goto PRIVACY_CLEANUP
if "%choice%"=="3" (
    set Routine=DISABLE_UPDATES
    set Rev_Routine=ENABLE_UPDATES
    set Apply=Disable Windows updates
	set Revert=Enable Windows updates
    set menu=PRIVACY_SECURITY_MENU
    goto SUB_MENU
)
if "%choice%"=="4" (
    set Routine=DISABLE_DEFENDER
    set Rev_Routine=ENABLE_DEFENDER
    set Apply=Disable Windows Defender
	set Revert=Enable Windows Defender
    set menu=PRIVACY_SECURITY_MENU
    goto SUB_MENU
)
if "%choice%"=="5" (
    set Routine=ENHANCE_SECURITY
    set Rev_Routine=REV_ENHANCE_SECURITY
    set Apply=Enhance system security
	set Revert=Set settings to default
    set menu=PRIVACY_SECURITY_MENU
    goto SUB_MENU
)
if "%choice%"=="6" goto SECURITY_INFO
if "%choice%"=="0" goto MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-6)
pause
goto PRIVACY_SECURITY_MENU

:DISABLE_TELEMETRY
cls
call :PATH "Telemetry" "Disable_Telemetry"

echo Disabling telemetry services
for %%S in (
    DiagTrack
    dmwappushsvc
    DiagSvcs
    WerSvc
    CDPUserSvc
) do (
    sc query "%%S" >nul 2>&1
    if not errorlevel 1 (
        sc config "%%S" start= disabled >nul 2>&1
        if not errorlevel 1 (
            echo [SUCCESS] %%S>>"%LogFile%" 2>&1
        ) else (
            echo [FAILED] %%S>>"%LogFile%" 2>&1
        )
    ) else (
        echo [NOT FOUND] %%S>>"%LogFile%" 2>&1
    )
)

echo Disable telemetry scheduled tasks
for /f "tokens=*" %%i in ("%~dp0Files\Security\Scheduled_tasks_telemetry.txt") do (
    set "TASK_NAME=%%i"
    set "TASK_RESULT=SUCCESS"
    
    schtasks /change /tn "%%i" /disable >nul 2>&1
    if errorlevel 1 (
        schtasks /query /tn "%%i" >nul 2>&1
        if errorlevel 1 (
            set "TASK_RESULT=NOT_FOUND"
        ) else (
            set "TASK_RESULT=FAILED"
        )
    )
    
    echo !TASK_NAME!: !TASK_RESULT! >> "%LogFile%" 2>&1
)

echo Disable telemetry from registry
reg import "%~dp0Files\Security\Disable_Telemetry.reg" >> "%LogFile%" 2>&1

echo Disable Powershell 7 Telemetry
powershell -Command "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')"

echo Block Domains in hosts file
set "hostsPath=%SystemRoot%\System32\drivers\etc\hosts"

findstr /i /c:"# Tracking and trash Domains" "%hostsPath%" >nul || (
    echo.>>"%hostsPath%"
    echo # Tracking and trash Domains>>"%hostsPath%"
)

for /f "usebackq delims=" %%l in ("%~dp0Files\Security\Tracking_Domins.txt") do (
    if not "%%l"=="" (
        findstr /i /c:"%%l" "%hostsPath%" >nul || (
            echo %%l>>"%hostsPath%"
        )
    )
)

ipconfig /flushdns >nul
call :GO PRIVACY_SECURITY_MENU

:PRIVACY_CLEANUP
cls & 	echo Cleaning Temp
for %%F in (
	"%LOCALAPPDATA%\Temp"
	"%WINDIR%\Temp"
	"%SystemDrive%\Temp"
	"%ALLUSERSPROFILE%\Temp"
    "%TEMP%"
    "%AppData%\Temp"
    "%HomePath%\AppData\LocalLow\Temp"
) do (
    rd /s /q "%%~F" >nul 2>&1
    del /s /f /q "%%~F\*.*" >nul 2>&1
	md "%%~F" >nul 2>&1
)

echo Cleaning Privacy-related files
del /f /s /q "%APPDATA%\Microsoft\Windows\Recent\*.*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*.*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*.*" >nul 2>&1
del /q /f "%WINDIR%\Logs\*.*" >nul 2>&1
del /q /f "%WINDIR%\System32\LogFiles\*.*" >nul 2>&1
del /q /f "%SystemRoot%\Prefetch\*.*" >nul 2>&1
del /q /f "%userprofile%\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt") >nul 2>&1
del /q /f "%SystemRoot%\AppCompat\Programs\Amcache.hve" >nul 2>&1
del /q /f "%LOCALAPPDATA%\Microsoft\Windows\SRU\SRUDB.dat" >nul 2>&1
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache*.db" >nul 2>&1
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" >nul 2>&1

echo Clearing Windows Event Logs
for %%L in (Application Security System Setup) do (
    wevtutil clear-log %%L /quiet >nul 2>&1
)

echo Cleaning registry entries
reg import "%~dp0Files\Security\privacy_cleanup.reg" >> "%LogFile%" 2>&1

set "BROWSERS=chrome.exe brave.exe msedge.exe firefox.exe"
set BROWSERS_OPEN=0

for %%B in (%BROWSERS%) do (
    tasklist /FI "IMAGENAME eq %%B" 2>nul | find /I "%%B" >nul
    if not errorlevel 1 (
        set BROWSERS_OPEN=1
    )
)

if !BROWSERS_OPEN! equ 1 (
    set /p CLOSE_BROWSERS="Browsers are currently open. Do you want to close them? (y/n): "
    if /i "!CLOSE_BROWSERS!"=="y" (
        echo Closing browsers
        for %%B in (%BROWSERS%) do (
            taskkill /IM "%%B" /F /T >nul 2>&1
        )
        timeout /t 2 >nul
    ) else (
        echo Skipping files currently used by browsers
    )
) else (
    echo No browsers are currently running
)

if exist "%LOCALAPPDATA%\Google\Chrome\User Data" (
    for /d %%p in ("%LOCALAPPDATA%\Google\Chrome\User Data\*") do (
        rd /s /q "%%p\Cache" >nul 2>&1
        rd /s /q "%%p\GPUCache" >nul 2>&1
        rd /s /q "%%p\Code Cache" >nul 2>&1
        rd /s /q "%%p\ShaderCache" >nul 2>&1
        rd /s /q "%%p\Service Worker" >nul 2>&1
        del /q /f /s "%%p\*.tmp" "%%p\*.temp" "%%p\*.log" >nul 2>&1
        del /q /f "%%p\History" "%%p\Cookies" "%%p\Web Data" "%%p\Login Data" >nul 2>&1
    )
)

if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data" (
    for /d %%p in ("%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\*") do (
        rd /s /q "%%p\Cache" >nul 2>&1
        rd /s /q "%%p\GPUCache" >nul 2>&1
        rd /s /q "%%p\Code Cache" >nul 2>&1
        rd /s /q "%%p\ShaderCache" >nul 2>&1
        rd /s /q "%%p\Service Worker" >nul 2>&1
        del /q /f /s "%%p\*.tmp" "%%p\*.temp" "%%p\*.log" >nul 2>&1
        del /q /f "%%p\History" "%%p\Cookies" "%%p\Web Data" "%%p\Login Data" >nul 2>&1
    )
)

if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data" (
    for /d %%p in ("%LOCALAPPDATA%\Microsoft\Edge\User Data\*") do (
        rd /s /q "%%p\Cache" >nul 2>&1
        rd /s /q "%%p\GPUCache" >nul 2>&1
        rd /s /q "%%p\Code Cache" >nul 2>&1
        rd /s /q "%%p\ShaderCache" >nul 2>&1
        rd /s /q "%%p\Service Worker" >nul 2>&1
        del /q /f /s "%%p\*.tmp" "%%p\*.temp" "%%p\*.log" >nul 2>&1
        del /q /f "%%p\History" "%%p\Cookies" "%%p\Web Data" "%%p\Login Data" >nul 2>&1
    )
)

if exist "%APPDATA%\Mozilla\Firefox\Profiles" (
    for /d %%F in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
        rd /s /q "%%F\cache2" >nul 2>&1
        del /q /f "%%F\places.sqlite" "%%F\cookies.sqlite" "%%F\formhistory.sqlite" "%%F\sessionstore-backups\*" >nul 2>&1
    )
)

echo Clearing DNS Cache
ipconfig /flushdns >nul 2>&1

echo Clearing Clipboard
echo. | clip >nul

choice /C YN /N /M "Do you want to run the Disk Cleanup to complete the cleaning? (Y/N): "
if !errorlevel! equ 1 (
    echo Running Disk Cleanup
    cleanmgr /d C
)

echo Empty Recycle Bin
powershell -command "Clear-RecycleBin -Force -Confirm:$false"
call :GO PRIVACY_SECURITY_MENU


:DISABLE_UPDATES
cls & echo Disabling Windows updates
call :PATH "Windows_Updates" "Disable"

echo Disabling Windows Update services
for %%S in (
    BITS
    dosvc
    wuauserv
    UsoSvc
    WaaSMedicSvc
) do (
    sc query "%%S" >nul 2>&1
    if not errorlevel 1 (
        sc config "%%S" start= disabled >nul 2>&1
        if not errorlevel 1 (
            echo [SUCCESS] %%S>>"%LogFile%" 2>&1
        ) else (
            echo [FAILED] %%S>>"%LogFile%" 2>&1
        )
    ) else (
        echo [NOT FOUND] %%S>>"%LogFile%" 2>&1
    )
)

echo Disable windows update from registry
reg import "%~dp0Files\Security\Disable_Update.reg" >> "%LogFile%" 2>&1

call :GO PRIVACY_SECURITY_MENU

:ENABLE_UPDATES
cls & echo Enabling automatic Windows updates
call :PATH "Windows_Updates" "Enable"

echo Enabling Windows Update Services
for %%S in (
    BITS
    dosvc
    wuauserv
    UsoSvc
    WaaSMedicSvc
) do (
    sc query "%%S" >nul 2>&1
    if not errorlevel 1 (
        sc config "%%S" start= demand >nul 2>&1
        if not errorlevel 1 (
            echo [SUCCESS] %%S>>"%LogFile%" 2>&1
        ) else (
            echo [FAILED] %%S>>"%LogFile%" 2>&1
        )
    ) else (
        echo [NOT FOUND] %%S>>"%LogFile%" 2>&1
    )
)

echo Restoring Original Update Registry
reg import "%~dp0Files\Security\Enable_Update.reg" >> "%LogFile%" 2>&1

call :GO PRIVACY_SECURITY_MENU

:DISABLE_DEFENDER
cls & echo WARNING: This will disable Windows Defender
choice /C YN /N /M "Do you want to continue anyway? (Y/N): "
if errorlevel 2 goto PRIVACY_SECURITY_MENU

call :PATH "Windows Defender" "Disable"

echo Disable Windows Defender services
for %%S in (WinDefend WdNisSvc SecurityHealthService Sense SgrmAgent SgrmBroker webthreatdefsvc webthreatdefusersvc) do sc query "%%S" >nul 2>&1 && (
    echo Disabling service: %%S>>"%LogFile%" 2>&1
    sc config "%%S" start= disabled >nul 2>&1 && (echo [SUCCESS - SC] %%S>>"%LogFile%" 2>&1) || (
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul 2>&1 && (echo [SUCCESS - REG] %%S>>"%LogFile%" 2>&1) || (echo [FAILED] %%S>>"%LogFile%" 2>&1)
    )
) || (echo [NOT FOUND] %%S>>"%LogFile%" 2>&1)

echo Applying registry modifications
reg import "%~dp0Files\Security\Disable_Def.reg" >> "%LogFile%" 2>&1

echo. & echo System restart is required for all changes to take effect.
call :GO PRIVACY_SECURITY_MENU

:ENABLE_DEFENDER
cls
call :PATH "Windows Defender" "Enabled"

echo Enable Windows Defender services
for %%S in (WinDefend WdNisSvc SecurityHealthService Sense SgrmAgent SgrmBroker webthreatdefsvc webthreatdefusersvc) do sc query "%%S" >nul 2>&1 && (
    echo Configuring service: %%S>>"%LogFile%" 2>&1
    sc config "%%S" start= auto >nul 2>&1 || reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
    echo Starting service: %%S>>"%LogFile%" 2>&1
    sc start "%%S" >nul 2>&1 && (echo [SUCCESS] %%S>>"%LogFile%" 2>&1) || (echo [WARNING] Failed to start %%S>>"%LogFile%" 2>&1)
) || (echo [NOT FOUND] %%S>>"%LogFile%" 2>&1)

echo Restoring default registry settings
reg import "%~dp0Files\Security\Enable_Def.reg" >> "%LogFile%" 2>&1

echo Enable Tamper Protection via PowerShell
powershell -Command "Set-MpPreference -DisableTamperProtection 0" >nul 2>&1
if !errorlevel! equ 0 (echo [SUCCESS] Tamper Protection enabled >> "%LogFile%" 2>&1) else (echo [WARNING] Tamper Protection could not be enabled via PowerShell >> "%LogFile%" 2>&1)

echo Attempting to update Defender signatures
powershell -NoProfile -ExecutionPolicy Bypass -Command "Try { Update-MpSignature -ErrorAction Stop; Write-Host '[SUCCESS] Defender: Virus definitions updated.' } Catch { Write-Warning '[WARNING] Signature update failed or Defender not ready yet.' }" >> "%LogFile%" 2>&1

echo. & echo Restart your computer to ensure all services and policies apply correctly 
echo Check Windows Security app to confirm real-time protection is ON
call :GO PRIVACY_SECURITY_MENU

:ENHANCE_SECURITY
cls & echo Applying security hardening settings
call :PATH "Enhance_Security" "Enhance"

echo configure registry settings
reg import "%~dp0Files\Security\Enhance_Security.reg" >> "%LogFile%" 2>&1

echo Disabling vulnerable Windows features
for %%f in ("MicrosoftWindowsPowerShellV2" "MicrosoftWindowsPowerShellV2Root" "SMB1Protocol" "SmbDirect" "TFTP" "TelnetClient" "WCF-TCP-PortSharing45") do (
    echo Disabling feature: %%f >> "%LogFile%" 2>&1
    dism /Online /Disable-Feature /FeatureName:%%f /NoRestart /Quiet >> "%LogFile%" 2>&1
)

echo Disabling Windows services
for %%S in (
    mrxsmb10
    RemoteRegistry
    SNMP
    SNMPTRAP
) do (
    sc query "%%S" >nul 2>&1 && (
        sc config "%%S" start= disabled >nul 2>&1 && (
            echo [SUCCESS] %%S >> "%LogFile%" 2>&1
        ) || (
            echo [FAILED] %%S >> "%LogFile%" 2>&1
        )
    ) || (
        echo [NOT FOUND] %%S >> "%LogFile%" 2>&1
    )
)

echo Removing default user account
net user defaultuser0 /delete >> "%LogFile%" 2>&1

echo. & echo System restart is required for all changes to take effect
call :GO PRIVACY_SECURITY_MENU

:REV_ENHANCE_SECURITY
cls & echo Restoring default security settings
call :PATH "Enhance_Security" "Rev_Enhance"

reg import "%~dp0Files\Security\Rev_Enhance_Security.reg" >> "%LogFile%" 2>&1

echo Restoration completed
call :GO PRIVACY_SECURITY_MENU

:SECURITY_INFO
cls & echo TCP Ports and owning processes:
powershell -Command "Get-NetTCPConnection -State Listen | Select-Object LocalPort, OwningProcess -Unique | ForEach-Object { $p = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName; 'TCP Port: ' + $_.LocalPort + ' | Process: ' + $p }"

echo. & echo UDP Ports and owning processes:
powershell -Command "Get-NetUDPEndpoint | Select-Object LocalPort, OwningProcess -Unique | ForEach-Object { $p = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName; 'UDP Port: ' + $_.LocalPort + ' | Process: ' + $p }"

echo. & echo Checking Firewall status
powershell -Command "Get-NetFirewallProfile | ForEach-Object { Write-Host ($_.Name + ': ' + ($_.Enabled -replace 'True','ENABLED' -replace 'False','DISABLED')) }"

echo. & echo Checking Remote Desktop status
powershell -Command "$rdp=(Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections; if ($rdp -eq 0) { 'Enabled' } else { 'Disabled' }"

echo. & echo Listing shared folders
powershell -Command "Get-SmbShare | Select-Object Name,Path,Description"

echo. & echo Listing Administrators group members
powershell -NoProfile -Command "Get-LocalUser | ForEach-Object { $u=$_.Name; $groups=(Get-LocalGroup | ForEach-Object { if (Get-LocalGroupMember $_.Name -ErrorAction SilentlyContinue | Where-Object {$_.Name -like \"*$u\"}) { $_.Name } }); [PSCustomObject]@{User=$u; Enabled=$_.Enabled; PasswordRequired=$_.PasswordRequired; LastLogon=if ($_.LastLogon) {$_.LastLogon} else {'Never'}; Groups=($groups -join ', ')} } | Format-Table -AutoSize"

echo. & echo Checking failed/success login attempts (last 30 days)
powershell -Command "$start=(Get-Date).AddDays(-30); Get-EventLog -LogName Security -After $start | Where-Object { $_.EventID -in 4624,4625 } | ForEach-Object { $u=$_.ReplacementStrings[5]; if($u -and $u -notmatch '^(SYSTEM|LOCAL SERVICE|NETWORK SERVICE|DWM-\d+|UMFD-\d+|\$)$'){ [PSCustomObject]@{Time=$_.TimeGenerated; Event=($(if($_.EventID -eq 4624){'Success'}else{'Failure'})); User=$u} } } | Sort-Object Time -Descending | Select-Object -First 20"

echo. & echo Checking Windows Defender status
powershell -NoProfile -Command "$svc=Get-Service -Name WinDefend -ErrorAction SilentlyContinue; if($svc){ 'Service: ' + $svc.Status } else { 'Service not found' }"

echo. & echo Checking SmartScreen status
powershell -Command "$s=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -ErrorAction SilentlyContinue).SmartScreenEnabled; if ($s -eq 'Off') { 'Disabled' } elseif ($s) { 'Enabled' } else { 'Unknown or Not Set' }"

echo. & echo Checking UAC status
powershell -Command "$uac = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System').EnableLUA; if ($uac -eq 1) { 'Enabled' } else { 'Disabled' }"

echo. & echo Checking LSA protection
powershell -Command "$lsappl = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'RunAsPPL' -ErrorAction SilentlyContinue).RunAsPPL; if ($lsappl -eq 1) { 'Enabled' } else { 'Disabled or Not Set' }"

echo. & echo Checking BitLocker status per drive
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object { Write-Host ''; Write-Host \"Drive $($_.DeviceID)\"; try { $bitlockerInfo = manage-bde -status $_.DeviceID 2>$null; if ($bitlockerInfo) { $bitlockerInfo | Select-String 'Protection Status|Lock Status|Encryption Method|Conversion Status|Percentage Encrypted|Key Protectors' | ForEach-Object { Write-Host $_.Line.Trim() } } else { Write-Host 'BitLocker: Not encrypted or not available' } } catch { Write-Host 'Error: Cannot check BitLocker status' } }"

echo. & echo Checking last Windows Update installed
powershell -Command "$last = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1; if ($last) { $last | Select-Object HotFixID,Description,@{n='InstalledOn';e={$_.InstalledOn.ToString('dd/MM/yyyy HH:mm')}} } else { 'No updates found' }"

echo. & echo Checking virtualization support
powershell -Command "systeminfo | findstr /i 'Hyper-V'"

echo. & echo Checking BSOD events (Event ID 41)
powershell -Command "Get-WinEvent -FilterHashtable @{LogName='System';ID=41} | Select-Object -First 10 TimeCreated,Id,Message"
call :GO PRIVACY_SECURITY_MENU


:NETWORK_MENU
cls & echo. & echo.
echo                        --------------------------------- Network ---------------------------------
echo.
echo                          [1] Improve Network                                [2] Reset Network
echo.
echo                          [3] Wi-Fi Passwords                                [4] Change DNS                        
echo.
echo                          [5] Network Info                                   [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" (
    set Routine=IMPROVE_NET
    set Rev_Routine=REV_IMPROVE_NET
    set Apply=Improve Network seeting
	set Revert=Default Network seeting
    set menu=NETWORK_MENU
    goto SUB_MENU
)
if "%choice%"=="2" goto NETWORK_RESET
if "%choice%"=="3" goto WIFI_PASSWORDS
if "%choice%"=="4" goto DNS_MENU
if "%choice%"=="5" goto NETWORK_INFO
if "%choice%"=="0" goto MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-5)
pause
goto NETWORK_MENU

:IMPROVE_NET
cls & echo Enable WlanSvc service
sc config WlanSvc start= auto >nul 2>&1
sc start WlanSvc >nul 2>&1

echo Importing network improve registry file
reg import "%~dp0Files\Network\Improve_net.reg" >nul

echo Applying TCP/IP optimizations
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
netsh int tcp set global ecncapability=disabled >nul 2>&1
netsh int tcp set global fastopen=enabled >nul 2>&1
netsh int tcp set global fastopenfallback=enabled >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global timestamps=disabled >nul 2>&1

echo Setting DNS on all connected dedicated interfaces
for /f "tokens=3,*" %%a in ('netsh interface show interface ^| findstr "Connected"') do (
    echo Setting: %%b    
    netsh interface ipv4 set dns name="%%b" static 1.1.1.1 primary >nul
    netsh interface ipv4 add dns name="%%b" 1.0.0.1 index=2 >nul
	
    netsh interface ipv6 set dns name="%%b" static 2606:4700:4700::1111 primary >nul
    netsh interface ipv6 add dns name="%%b" 2606:4700:4700::1001 index=2 >nul
)

echo Flushing DNS cache and resetting Winsock
ipconfig /flushdns >nul 2>&1
netsh winsock reset >nul 2>&1
call :GO NETWORK_MENU

:REV_IMPROVE_NET
cls & echo Enable WlanSvc service
sc config WlanSvc start= auto >nul 2>&1
sc start WlanSvc >nul 2>&1

echo Importing default network settings registry file
reg import "%~dp0Files\Network\Rev_Improve_net.reg" >nul

echo Restoring TCP/IP defaults
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global chimney=default >nul 2>&1
netsh int tcp set global ecncapability=default >nul 2>&1
netsh int tcp set global fastopen=default >nul 2>&1
netsh int tcp set global fastopenfallback=default >nul 2>&1
netsh int tcp set global rss=default >nul 2>&1
netsh int tcp set global timestamps=default >nul 2>&1

echo Restoring DNS (IPv4 / IPv6) to Automatic
for /f "tokens=3,*" %%a in ('netsh interface show interface ^| findstr "Connected"') do (
    echo - Resetting DNS on: %%b
    netsh interface ipv4 set source=dns name="%%b" dhcp >nul
    netsh interface ipv6 set source=dns name="%%b" dhcp >nul
)

echo Resetting Winsock and flushing DNS
netsh winsock reset >nul 2>&1
ipconfig /flushdns >nul 2>&1
call :GO NETWORK_MENU

:NETWORK_RESET
cls
call :PATH "Network" "Network Reset"

echo Restart WlanSvc service
sc stop WlanSvc >> "%LogFile%" 2>&1
sc config WlanSvc start= auto >> "%LogFile%" 2>&1
sc start WlanSvc >> "%LogFile%" 2>&1

echo Releasing IP addresses
ipconfig /release >> "%LogFile%" 2>&1

echo Flushing DNS resolver cache
ipconfig /flushdns >> "%LogFile%" 2>&1

echo Clearing ARP cache
arp -d * >> "%LogFile%" 2>&1

echo Resetting Winsock catalog
netsh winsock reset >> "%LogFile%" 2>&1

echo Resetting TCP/UDP/IP stack
netsh int ip reset >> "%LogFile%" 2>&1
netsh int tcp reset >> "%LogFile%" 2>&1
netsh int udp reset >> "%LogFile%" 2>&1

echo Reloading the NetBIOS name cache
nbtstat -R >> "%LogFile%" 2>&1

echo Sending NetBIOS name update
nbtstat -RR >> "%LogFile%" 2>&1

echo Restart network adapters
for /f "tokens=3,*" %%a in ('netsh interface show interface ^| findstr "Connected"') do (
    echo - Processing adapter: %%b
    netsh interface set interface name="%%b" admin=disabled >nul 2>&1
    timeout /t 2 >nul
    netsh interface set interface name="%%b" admin=enabled >nul 2>&1
)

echo Renewing IP addresses
ipconfig /renew >> "%LogFile%" 2>&1

echo Registering DNS name
ipconfig /registerdns >> "%LogFile%" 2>&1

echo. & echo Restart your computer for all changes to take effect.
call :GO NETWORK_MENU

:WIFI_PASSWORDS
cls & echo Showing Saved Networks and Passwords
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $raw = netsh wlan show profiles 2>$null; if (-not $raw) { Write-Host 'No Wi-Fi profiles found or netsh failed.'; exit 0 }; $profiles = $raw | Where-Object { $_ -match ':' -and $_ -match '(?i)All User Profile|All User Profiles|All Users Profile|Profile|Perfil|Profil' } | ForEach-Object { ($_ -split ':',2)[1].Trim() } | Where-Object { $_ -ne '' }; if (-not $profiles) { Write-Host 'No Wi-Fi profiles found.'; exit 0 }; foreach ($p in $profiles) { try { $info = netsh wlan show profile name=\"$p\" key=clear 2>$null } catch { $info = @() }; $keyPatterns = @('Key Content','Contenido de la clave','Contenu de la clé','Schlüsselinhalt','Contenuto chiave','Clave'); $pwd = 'N/A'; foreach ($pat in $keyPatterns) { $m = $info | Select-String -SimpleMatch $pat; if ($m) { $pwd = ($m.Line -split ':',2)[1].Trim(); break } }; if ($pwd -eq 'N/A') { $m = $info | Where-Object { $_ -match ':\s*\S+' -and ($_.Split(':')[0] -match '(?i)key|clave|clé|schlüssel') } | Select-Object -First 1; if ($m) { $pwd = ($m -split ':',2)[1].Trim() } }; Write-Host \"---------------------------------------`nSSID: $p`nPassword: $pwd`n---------------------------------------\" } } catch { Write-Error \"Unexpected error: $_\" }"
call :GO NETWORK_MENU

:DNS_MENU
cls & echo. & echo.
echo                        ------------------------------- DNS Server --------------------------------
echo.
echo                          [1] Google Public                                    [2] Cloudflare
echo.
echo                          [3] Cloudflare Family                                [4] AdGuard DNS                       
echo.
echo                          [5] Clean Browsing                                   [6] Quad9
echo.
echo                          [7] OpenDNS                                          [8] DNS status
echo.
echo                          [9] Default Setting                                  [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" (
    set DNS_IPv4_1=8.8.8.8
    set DNS_IPv4_2=8.8.4.4
    set DNS_IPv6_1=2001:4860:4860::8888
    set DNS_IPv6_2=2001:4860:4860::8844
    goto SET_DNS
)
if "%choice%"=="2" (
    set DNS_IPv4_1=1.1.1.1
    set DNS_IPv4_2=1.0.0.1
    set DNS_IPv6_1=2606:4700:4700::1111
    set DNS_IPv6_2=2606:4700:4700::1001
    goto SET_DNS
)
if "%choice%"=="3" (
    set DNS_IPv4_1=1.1.1.3
    set DNS_IPv4_2=1.0.0.3
    set DNS_IPv6_1=2606:4700:4700::1113
    set DNS_IPv6_2=2606:4700:4700::1003
    goto SET_DNS
)
if "%choice%"=="4" (
    set DNS_IPv4_1=94.140.14.15
    set DNS_IPv4_2=94.140.15.16
    set DNS_IPv6_1=2a10:50c0::bad:ff
    set DNS_IPv6_2=2a10:50c0::b0d:ff
    goto SET_DNS
)
if "%choice%"=="5" (
    set DNS_IPv4_1=185.228.168.168
    set DNS_IPv4_2=185.228.169.168
    set DNS_IPv6_1=2a0d:2a00:1::
    set DNS_IPv6_2=2a0d:2a00:2::
    goto SET_DNS
)
if "%choice%"=="6" (
    set DNS_IPv4_1=9.9.9.9
    set DNS_IPv4_2=149.112.112.112
    set DNS_IPv6_1=2620:fe::fe
    set DNS_IPv6_2=2620:fe::9
    goto SET_DNS
)
if "%choice%"=="7" (
    set DNS_IPv4_1=208.67.222.222
    set DNS_IPv4_2=208.67.220.220
    set DNS_IPv6_1=2620:119:35::35
    set DNS_IPv6_2=2620:119:53::53
    goto SET_DNS
)
if "%choice%"=="8" goto DNS_STATUS
if "%choice%"=="9" goto DHCP
if "%choice%"=="0" goto NETWORK_MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-9)
pause
goto DNS_MENU

:SET_DNS
for /f "tokens=3,*" %%a in ('netsh interface show interface ^| findstr "Connected"') do (
    echo  - Setting: %%b
    netsh interface ipv4 set dns name="%%b" static %DNS_IPv4_1% primary >nul
    netsh interface ipv4 add dns name="%%b" %DNS_IPv4_2% index=2 >nul
    
    netsh interface ipv6 set dns name="%%b" static %DNS_IPv6_1% primary >nul
    netsh interface ipv6 add dns name="%%b" %DNS_IPv6_2% index=2 >nul
)

echo Flushing DNS cache
ipconfig /flushdns >nul
call :GO DNS_MENU

:DNS_STATUS
cls & powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Files\Network\Dns_Status.ps1"
call :GO DNS_MENU

:DHCP
echo Restoring DNS (IPv4 / IPv6) to Automatic
for /f "tokens=3,*" %%a in ('netsh interface show interface ^| findstr "Connected"') do (
    echo - Resetting DNS on: %%b
    netsh interface ipv4 set source=dns name="%%b" dhcp >nul
    netsh interface ipv6 set source=dns name="%%b" dhcp >nul
)

echo Flushing DNS cache
ipconfig /flushdns >nul
call :GO DNS_MENU

:NETWORK_INFO
cls & powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Files\Network\Network_Info.ps1"
call :GO NETWORK_MENU


:PROGRAMS_MENU
cls & echo. & echo.
echo                        ------------------------------ Program manager ----------------------------
echo.
echo                         [1] Download Programs                                 [2] Update Programs
echo.
echo                         [3] Program Information                               [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" goto DOWNLOAD_PROGRAMS
if "%choice%"=="2" goto UPDATE_PROGRAMS
if "%choice%"=="3" goto PROGRAM_INFO
if "%choice%"=="0" goto MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-3)
pause
goto PROGRAMS_MENU

:DOWNLOAD_PROGRAMS
where choco >nul 2>&1
if %errorlevel%==0 goto PROGRAMS_MENU_MAIN

echo Installing Chocolatey package manager...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Chocolatey installation failed
    echo Please install it manually from: https://chocolatey.org/install
	call :GO PROGRAMS_MENU
)

echo refresh environment
if defined ChocolateyInstall (
    if exist "%ChocolateyInstall%\bin\refreshenv.cmd" call "%ChocolateyInstall%\bin\refreshenv.cmd"
)

:PROGRAMS_MENU_MAIN
set "on=(YES)"
set "off=(NO)"

for %%A in (1 2 3 4 5 6 7 8 9 10 11 12) do set "opt%%A=%off%"

:PROGRAMS_MENU_LOOP
cls
echo.
echo                        ------------------------------- Programs ---------------------------------
echo.
echo                             [1] Google Chrome                             [7] XnViewMP
echo.
echo                             [2] Brave Browser                             [8] Notepad++
echo.
echo                             [3] WinRAR                                    [9] Visual Studio Code
echo.
echo                             [4]  7-Zip                                   [10] Sumatra PDF
echo. 
echo                             [5] K-Lite Codec                             [11] qbittorrent
echo.
echo                             [6]  IrfanView                               [12] Virtual Box
echo.
echo                                                        [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & echo   Selected Programs:
call :ShowSelected

echo.
set /p "user_input=--> Select an option and press [S] to Start: "

if "%user_input%"=="" goto PROGRAMS_MENU_LOOP
if /i "%user_input%"=="S" goto INSTALL_PROGRAMS
if /i "%user_input%"=="0" goto PROGRAMS_MENU

set "tokens=%user_input:,= %"
for %%G in (%tokens%) do (
    for %%N in (1 2 3 4 5 6 7 8 9 10 11 12) do (
        if "%%G"=="%%N" call :ToggleSingle opt%%N
    )
)

goto PROGRAMS_MENU_LOOP

:INSTALL_PROGRAMS
cls
call :IsOn opt1 && (
    echo Installing Google Chrome...
    choco install googlechrome -y
)
call :IsOn opt2 && (
    echo Installing Brave Browser...
    choco install brave -y 
)
call :IsOn opt3 && (
    echo Installing WinRAR...
    choco install winrar -y 
)
call :IsOn opt4 && (
    echo Installing 7-Zip...
    choco install 7zip -y  
)
call :IsOn opt5 && (
    echo Installing K-Lite Codec Pack Mega...
    choco install k-litecodecpackmega -y
)
call :IsOn opt6 && (
    echo Installing IrfanView...
    choco install irfanview -y
)
call :IsOn opt7 && (
    echo Installing XnView MP...
    choco install xnviewmp -y
)
call :IsOn opt8 && (
    echo Installing Notepad++...
    choco install notepadplusplus -y
)
call :IsOn opt9 && (
    echo Installing Visual Studio Code...
    choco install vscode -y
)
call :IsOn opt10 && (
    echo Installing Sumatra PDF...
    choco install sumatrapdf -y
)
call :IsOn opt11 && (
    echo Installing qbittorrent...
    choco install qbittorrent -y
)
call :IsOn opt12 && (
    echo Installing Virtual Box...
    choco install virtualbox -y
)
call :GO PROGRAMS_MENU_LOOP

:IsOn
if "!%1!"=="%on%" exit /b 0
exit /b 1

:ToggleSingle
if "!%1!"=="%on%" (
    set "%1=%off%"
) else (
    set "%1=%on%"
)
goto :eof

:ShowSelected
set "any=0"
if "!opt1!"=="%on%"  (echo   - Google Chrome & set "any=1")
if "!opt2!"=="%on%"  (echo   - Brave Browser & set "any=1")
if "!opt3!"=="%on%"  (echo   - WinRAR & set "any=1")
if "!opt4!"=="%on%" (echo   - 7-Zip & set "any=1")
if "!opt5!"=="%on%"  (echo   - K-Lite Codec Pack Mega & set "any=1")
if "!opt6!"=="%on%" (echo   - IrfanView & set "any=1")
if "!opt7!"=="%on%"  (echo   - XnView MP & set "any=1")
if "!opt8!"=="%on%"  (echo   - Notepad++ & set "any=1")
if "!opt9!"=="%on%"  (echo   - Visual Studio Code & set "any=1")
if "!opt10!"=="%on%"  (echo   - Sumatra PDF & set "any=1")
if "!opt11!"=="%on%"  (echo   - qbittorrent & set "any=1")
if "!opt12!"=="%on%" (echo   - Virtual Box & set "any=1")
if "!any!"=="0" echo   No programs selected
goto :eof

:UPDATE_PROGRAMS
cls & echo Upgrading All Installed Packages
where choco >nul 2>&1 || (
    echo Chocolatey not found. Try manual updates
    call :GO PROGRAMS_MENU
)

choco upgrade all -y
call :GO PROGRAMS_MENU

:PROGRAM_INFO
cls & echo Startup Programs
powershell -NoLogo -NoProfile -Command "Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location | Format-Table -AutoSize"

echo. & echo All Installed Programs
powershell -NoLogo -NoProfile -Command "$paths = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'); Get-ItemProperty $paths | Where-Object { $_.DisplayName -and $_.DisplayName -ne '' } | Select-Object DisplayName,Publisher,@{Name='InstallDate';Expression={if($_.InstallDate){'{0:dd/MM/yyyy}' -f ([datetime]::ParseExact($_.InstallDate.ToString(),'yyyyMMdd',$null))}}} | Sort-Object DisplayName | Format-Table -AutoSize"
call :GO PROGRAMS_MENU

:CUSTOMIZATION_MENU
cls & echo. & echo. 
echo                        ------------------------------ Customization ------------------------------
echo.
echo                          [1] File Explorer                                    [2] Dark Mode
echo.
echo                          [3] Power seeting                                    [4] Shortcut arrow
echo.
echo                          [5] Classic Photo Viewer                             [6] Trash options 
echo.
echo                          [7] Num Lock                                         [8] Context menu
echo.
echo                                                          [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p "choice=Select an option: "
if "%choice%"=="1" goto FILE_EXPLORER
if "%choice%"=="2" (
    set Routine=DARK_MODE
    set Rev_Routine=LIGHT_MODE
    set Apply=Activate Dark mode
	set Revert=Activate Light mode
    set menu=CUSTOMIZATION_MENU
    goto SUB_MENU
)
if "%choice%"=="3" (
    set Routine=POWER_SETTINGS
    set Rev_Routine=REV_POWER_SETTINGS
    set Apply=Activate Power settings
	set Revert=Activate Power settings
    set menu=CUSTOMIZATION_MENU
    goto SUB_MENU
)
if "%choice%"=="4" (
    set Routine=SHORTCUT_ARROW
    set Rev_Routine=REV_SHORTCUT_ARROW
    set Apply=Remove arrow from shortcut
	set Revert=Default arrow shortcut
    set menu=CUSTOMIZATION_MENU
    goto SUB_MENU
)
if "%choice%"=="5" (
    set Routine=PHOTO_VIEWER
    set Rev_Routine=REV_PHOTO_VIEWER
    set Apply=Restore classic Windows Photo Viewer
	set Revert=Remove classic Windows Photo Viewer
    set menu=CUSTOMIZATION_MENU
    goto SUB_MENU
)
if "%choice%"=="6" (
    set Routine=TRASH_OPTIONS
    set Rev_Routine=REV_TRASH_OPTIONS
    set Apply=Disable unnecessary Windows features
	set Revert=Default Windows features
    set menu=CUSTOMIZATION_MENU
    goto SUB_MENU
)
if "%choice%"=="7" (
    set Routine=NUM_LOCK
    set Rev_Routine=REV_NUM_LOCK
    set Apply=Disable Num Lock, Caps Lock, and Scroll Lock when logging in
	set Revert=Default Num Lock, Caps Lock, and Scroll Lock when logging in
    set menu=CUSTOMIZATION_MENU
    goto SUB_MENU
)
if "%choice%"=="8" goto CONTEXT_MENU
if "%choice%"=="0" goto MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-8)
pause
goto CUSTOMIZATION_MENU

:FILE_EXPLORER
cls & echo. & echo.
echo                        ----------------------------- File explorer -------------------------------
echo.
echo                          [1] File Extensions                                 [2] Hidden files
echo.
echo                          [3] Recent Files                                    [4] Open on this PC
echo.
echo                          [5] Path in Title Bar                               [0] Back
echo.
echo                        ---------------------------------------------------------------------------


echo. & set /p choice="Select an option: "
if "%choice%"=="1" (
    set Routine=SHOW_EXTENSIONS
    set Rev_Routine=REV_SHOW_EXTENSIONS
    set Apply=Show files extensions
	set Revert=Disable display of files extensions
    set menu=FILE_EXPLORER
    goto SUB_MENU
)
if "%choice%"=="2" (
    set Routine=SHOW_HIDDEN
    set Rev_Routine=REV_SHOW_SHOW_HIDDEN
    set Apply=Show hidden files
	set Revert=Disable display of hidden files
    set menu=FILE_EXPLORER
    goto SUB_MENU
)
if "%choice%"=="3" (
    set Routine=SHOW_RESENT
    set Rev_Routine=REV_SHOW_RESENT
    set Apply=Show resent files
	set Revert=Disable display of resente files
    set menu=FILE_EXPLORER
    goto SUB_MENU
)
if "%choice%"=="4" (
    set Routine=THIS_PC_OPEN
    set Rev_Routine=REV_THIS_PC_OPEN
    set Apply=Open File Explorer on this PC
	set Revert=Open File Explorer on Quick Access
    set menu=FILE_EXPLORER
    goto SUB_MENU
)
if "%choice%"=="5" (
    set Routine=FULL_PATH
    set Rev_Routine=REV_FULL_PATH
    set Apply=Display full path in the file explorer bar
	set Revert=Display shortcut path in the file explorer bar
    set menu=FILE_EXPLORER
    goto SUB_MENU
)
if "%choice%"=="0" goto CUSTOMIZATION_MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-5)
pause
goto FILE_EXPLORER

:SHOW_EXTENSIONS
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul
call :GO FILE_EXPLORER

:REV_SHOW_EXTENSIONS
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f >nul
call :GO FILE_EXPLORER

:SHOW_HIDDEN
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSuperHidden /t REG_DWORD /d 1 /f >nul
call :GO FILE_EXPLORER

:REV_SHOW_SHOW_HIDDEN
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSuperHidden /t REG_DWORD /d 0 /f >nul
call :GO FILE_EXPLORER

:SHOW_RESENT
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v NoRecentDocsHistory /t REG_DWORD /d 0 /f >nul
call :GO FILE_EXPLORER

:REV_SHOW_RESENT
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v NoRecentDocsHistory /t REG_DWORD /d 1 /f >nul
call :GO FILE_EXPLORER

:THIS_PC_OPEN
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f >nul
call :GO FILE_EXPLORER

:REV_THIS_PC_OPEN
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 2 /f >nul
call :GO FILE_EXPLORER

:FULL_PATH
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v FullPathAddress /t REG_DWORD /d 1 /f >nul
call :GO FILE_EXPLORER

:REV_FULL_PATH
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v FullPathAddress /t REG_DWORD /d 0 /f >nul
call :GO FILE_EXPLORER

:DARK_MODE
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul
call :GO CUSTOMIZATION_MENU

:LIGHT_MODE
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul
call :GO CUSTOMIZATION_MENU

:POWER_SETTINGS
mkdir "%USERPROFILE%\Desktop\Powerful Settings.{ED7BA470-8E54-465E-825C-99712043E01C}" >nul
call :GO CUSTOMIZATION_MENU

:REV_POWER_SETTINGS
set "folderPath=%USERPROFILE%\Desktop\Powerful Settings.{ED7BA470-8E54-465E-825C-99712043E01C}"
if exist "%folderPath%" rd /s /q "%folderPath%" >nul
call :GO CUSTOMIZATION_MENU

:SHORTCUT_ARROW
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /d "C:\Windows\System32\imageres.dll,197" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v link /t REG_BINARY /d 00000000 /f >nul
call :GO CUSTOMIZATION_MENU

:REV_SHORTCUT_ARROW
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" /v 29 /f >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v link /f >nul
call :GO CUSTOMIZATION_MENU

:PHOTO_VIEWER
reg import "%~dp0Files\Customization\Restore_Photo_Viewer.reg" >nul
call :GO CUSTOMIZATION_MENU

:REV_PHOTO_VIEWER
reg import "%~dp0Files\Customization\Removing_Photo_Viewer.reg" >nul
call :GO CUSTOMIZATION_MENU

:TRASH_OPTIONS
reg import "%~dp0Files\Customization\Disable_Trash.reg" >nul 2>&1
call :GO CUSTOMIZATION_MENU

:REV_TRASH_OPTIONS
reg import "%~dp0Files\Customization\Default_Trash.reg" >nul 2>&1
call :GO CUSTOMIZATION_MENU

:NUM_LOCK
reg import "%~dp0Files\Customization\Disable_Num_Lock.reg" >nul

:REV_NUM_LOCK
reg import "%~dp0Files\Customization\Default_Num_Lock.reg" >nul

:CONTEXT_MENU
cls & echo. & echo.
echo                        ------------------------------- Context menu ------------------------------
echo.
echo                          [1] Add CMD                                       [2] Add Restart Explorer
echo. 
echo                          [3] Add Killing frozen                            [0] Back
echo.    
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" (
    set Routine=CMD_CONTEXT
    set Rev_Routine=REV_CMD_CONTEXT
    set Apply=Add Command Prompt context menu options
	set Revert=Remove Command Prompt context menu options
    set menu=CONTEXT_MENU
    goto SUB_MENU
)
if "%choice%"=="2" (
    set Routine=EXPLORER_RESTART
    set Rev_Routine=REV_EXPLORER_RESTART
    set Apply=Add Explorer restart context menu option
	set Revert=Remove Explorer restart context menu option
    set menu=CONTEXT_MENU
    goto SUB_MENU
)
if "%choice%"=="3" (
    set Routine=FROZEN
    set Rev_Routine=REV_FROZEN
    set Apply=Add Killing frozen process context menu option
	set Revert=Remove Killing frozen process context menu option
    set menu=CONTEXT_MENU
    goto SUB_MENU
)
if "%choice%"=="0" goto CUSTOMIZATION_MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-3)
pause
goto CONTEXT_MENU

:CMD_CONTEXT
reg add "HKCR\Directory\shell\OpenCmdHere" /ve /d "Open Command Prompt Here (Admin)" /f >nul
reg add "HKCR\Directory\shell\OpenCmdHere" /v "HasLUAShield" /t REG_SZ /d "" /f >nul
reg add "HKCR\Directory\shell\OpenCmdHere" /v "Icon" /d "cmd.exe" /f >nul
reg add "HKCR\Directory\shell\OpenCmdHere\command" /ve /d "powershell -Command \"Start-Process cmd -ArgumentList '/s','/k','pushd %%V' -Verb RunAs\"" /f >nul

reg add "HKCR\Directory\Background\shell\OpenCmdHere" /ve /d "Open Command Prompt Here (Admin)" /f >nul
reg add "HKCR\Directory\Background\shell\OpenCmdHere" /v "HasLUAShield" /t REG_SZ /d "" /f >nul
reg add "HKCR\Directory\Background\shell\OpenCmdHere" /v "Icon" /d "cmd.exe" /f >nul
reg add "HKCR\Directory\Background\shell\OpenCmdHere\command" /ve /d "powershell -Command \"Start-Process cmd -ArgumentList '/s','/k','pushd %%V' -Verb RunAs\"" /f >nul
call :GO CONTEXT_MENU

:REV_CMD_CONTEXT
reg delete "HKCR\Directory\shell\OpenCmdHere" /f >nul
reg delete "HKCR\Directory\Background\shell\OpenCmdHere" /f >nul
call :GO CONTEXT_MENU

:EXPLORER_RESTART
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\RestartExplorer" /ve /d "Restart Explorer" /f >nul
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\RestartExplorer" /v "Icon" /d "explorer.exe,0" /f >nul
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\RestartExplorer\command" /ve /d "cmd.exe /c taskkill /f /im explorer.exe && start explorer.exe" /f >nul
call :GO CONTEXT_MENU

:REV_EXPLORER_RESTART
reg delete "HKEY_CLASSES_ROOT\DesktopBackground\Shell\RestartExplorer" /f >nul
call :GO CONTEXT_MENU

:FROZEN
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\KillNotResponding" /v "MUIVerb" /d "Kill frozen process" /f >nul
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\KillNotResponding" /v "Icon" /d "%SystemRoot%\\System32\\Taskmgr.exe" /f >nul
reg add "HKEY_CLASSES_ROOT\DesktopBackground\Shell\KillNotResponding\Command" /ve /d "cmd.exe /K taskkill.exe /F /FI \"status eq NOT RESPONDING\"" /f >nul
call :GO CONTEXT_MENU

:REV_FROZEN
reg delete "HKEY_CLASSES_ROOT\DesktopBackground\Shell\KillNotResponding" /f >nul
call :GO CONTEXT_MENU

:SYSTEM_MENU
cls & echo. & echo.
echo                        --------------------------------- System ----------------------------------
echo.
echo                          [1] Restore point                                   [2] Registry Backup
echo.
echo                          [3] Activate windows                                [4] Information
echo.
echo                                                         [0] Back
echo.  
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" goto RESTORE_POINT
if "%choice%"=="2" goto REGISTRY_BACKUP
if "%choice%"=="3" goto ACTIVATION
if "%choice%"=="4" goto SYSTEM_INFO
if "%choice%"=="0" goto MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-4)
pause
goto SYSTEM_MENU

:RESTORE_POINT
cls & echo Creating a System Restore Point
call :PATH "Restore_Point" "Restore_Point"

echo Configuring Restore Point Services
for %%S in (
    VSS
    swprv
    Schedule
    srservice
    WaaSMedicSvc
) do (
    sc query "%%S" >nul 2>&1
    if not errorlevel 1 (
        sc config "%%S" start= demand >nul 2>&1
        if not errorlevel 1 (
            echo [SUCCESS] %%S>>"%LogFile%" 2>&1
			sc start "%%S" >>"%LogFile%" 2>&1 
        ) else (
            echo [FAILED] %%S>>"%LogFile%" 2>&1
        )
    ) else (
        echo [NOT FOUND] %%S>>"%LogFile%" 2>&1
    )
)

echo Enabling System Restore from registry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR /t REG_DWORD /d 0 /f >>"%LogFile%" 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableConfig /t REG_DWORD /d 0 /f >>"%LogFile%" 2>&1

echo Enabling System Restore on C: drive
powershell.exe -Command "Enable-ComputerRestore -Drive 'C:\'" >>"%LogFile%" 2>&1

echo Creating restore point
powershell.exe -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'Hello world' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop" >>"%LogFile%" 2>&1

if %errorLevel% neq 0 (
    echo ERROR: Failed to create restore point. Error code: %errorLevel%
    call :GO SYSTEM_MENU
)

timeout /t 5 >nul
set "LAST_RP="
for /f "delims=" %%A in ('powershell.exe -ExecutionPolicy Bypass -Command "(Get-ComputerRestorePoint -LastStatus | Sort-Object SequenceNumber -Descending | Select-Object -First 1).Description" 2^>nul') do set "LAST_RP=%%A"

if /I "%LAST_RP%"=="Hello world" (
    echo Restore point created successfully
) else (
    echo Restore point creation verification failed
    echo Last restore point description: "%LAST_RP%"
)

echo Stopping temporary services
sc stop VSS >>"%LogFile%" 2>&1
sc stop swprv >>"%LogFile%" 2>&1

echo Restore point creation completed
call :GO SYSTEM_MENU

:REGISTRY_BACKUP
cls & echo Creating a Full Registry Backup
set "BACKUP_DIR=%ProgramData%\By Windows Optimization Script\Registry Backup"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1 || (echo [ERROR] Failed to create backup directory: %BACKUP_DIR% & call :GO SYSTEM_MENU)

for %%H in (
"HKLM\SYSTEM"
"HKLM\SAM"
"HKU\.DEFAULT"
"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
"HKCU\SOFTWARE\Policies"
"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
) do (
    set "hive=%%~H"
    set "safe=!hive:\=_!"
    set "safe=!safe::=!"
    set "outfile=%BACKUP_DIR%\!safe!.reg"

    echo.
    echo Exporting !hive!
    reg export "!hive!" "!outfile!" /y >nul 2>&1 && (
        echo [SUCCESS]
    ) || (
        echo [FAILED]
    )
)

set "original_size=0.00"
for /f "delims=" %%S in ('powershell -NoProfile -Command "Get-ChildItem -Path '%BACKUP_DIR%' -Filter *.reg | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum | ForEach-Object { '{0:N2}' -f ($_/1MB) }"') do set "original_size=%%S"

echo. & echo Compressing registry backup files (%original_size% MB)
set "ZIPFILE=%BACKUP_DIR%\Registry Backup.zip"

powershell -NoProfile -Command "$files=Get-ChildItem -Path '%BACKUP_DIR%' -Filter *.reg; if($files){Compress-Archive -Path $files.FullName -DestinationPath '%ZIPFILE%' -Force; if(Test-Path '%ZIPFILE%'){ $size=(Get-Item '%ZIPFILE%').Length/1MB; Write-Host 'Registry files compressed successfully' ($size.ToString('N2')) 'MB'; $files|Remove-Item -Force } else { Write-Host 'Compression failed' }} else { Write-Host 'No files to compress' }"

echo. & echo Registry Backup : %ZIPFILE%
call :GO SYSTEM_MENU

:ACTIVATION
cls & echo. & echo.
echo                        -------------------------------- Activation -------------------------------
echo.
echo                          [1] Windows and office                                    [2] Status
echo. 
echo                                                          [0]Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" goto RUN_ACTIVATION
if "%choice%"=="2" goto CHECK_ACTIVATION
if "%choice%"=="0" goto SYSTEM_MENU 

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-2)
pause
goto ACTIVATION

:RUN_ACTIVATION
cls & echo Attempting ACTIVATION using MAS script
powershell -NoP -EP Bypass -c "irm https://get.activated.win | iex"
call :GO ACTIVATION

:CHECK_ACTIVATION
cls & echo Checking current Windows ACTIVATION status
powershell -Command "$lic = Get-CimInstance -Class SoftwareLicensingProduct | Where-Object { $_.PartialProductKey } | Select-Object -First 1; if ($lic) { Write-Host 'Description: ' $lic.Description; Write-Host 'Partial Product Key: ' $lic.PartialProductKey; $xpr = cscript //nologo slmgr.vbs /xpr; if ($xpr -match 'permanently activated') { Write-Host $xpr } else { Write-Host 'Remaining Grace Period (hrs): ' $lic.RemainingGracePeriod; Write-Host $xpr } } else { Write-Host 'No license information found.' }"
call :GO ACTIVATION

:SYSTEM_INFO
cls & powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Files\System\System_Info.ps1"
call :GO SYSTEM_MENU


:TOOLS_MENU
cls & echo. & echo.
echo                        ---------------------------------- Tools ----------------------------------
echo.
echo                          [1] SFC Scan                                          [2] DISM Tools
echo.  
echo                          [3] Defragment Drive                                  [4] Check Disk 
echo. 
echo                          [5] Memory Diagnostic                                 [6] Disk Cleanup
echo.
echo                                                          [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" goto SFC
if "%choice%"=="2" goto DISM_MENU
if "%choice%"=="3" goto DEFRAG
if "%choice%"=="4" goto CHKDSK
if "%choice%"=="5" goto MEMORY_DIAG
if "%choice%"=="6" goto CLEAN_MGR
if "%choice%"=="0" goto MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-6)
pause
goto TOOLS_MENU

:SFC
cls & echo Running sfc scan
sfc /scannow
call :GO TOOLS_MENU

:DISM_MENU
cls & echo. & echo.
echo                        ------------------------------- DISM Tools -------------------------------
echo.
echo                           [1] Fast check                                     [2] Deep check
echo.                    
echo                           [3] Fix corruption                                 [4] Full Cleanup
echo.
echo                                                         [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: " 
if "%choice%"=="1" goto DISM_CHECK_HEALTH
if "%choice%"=="2" goto DISM_SCAN_HEALTH
if "%choice%"=="3" goto DISM_RESTORE_HEALTH
if "%choice%"=="4" goto DISM_COMPONENT_CLEANUP
if "%choice%"=="0" goto TOOLS_MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-4)
pause
goto DISM_MENU

:DISM_RESTORE_HEALTH
cls & echo Repairing Windows component store
dism /Online /Cleanup-Image /RestoreHealth
call :GO DISM_MENU

:DISM_COMPONENT_CLEANUP
cls & echo Removing outdated updates
choice /c YN /n /m "Continue with cleanup? (Y/N): "
if errorlevel 2 goto DISM_MENU

dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
dism /Online /Cleanup-Image /SPSuperseded
call :GO DISM_MENU

:DISM_SCAN_HEALTH
cls & echo Scanning component store health

dism /Online /Cleanup-Image /ScanHealth
call :GO DISM_MENU

:DISM_CHECK_HEALTH
cls & echo Checking component store health
dism /Online /Cleanup-Image /CheckHealth
call :GO DISM_MENU

:DEFRAG
cls & echo Drive Optimization Utility

set "hasSSD=false"

for /f "tokens=*" %%A in ('powershell -nologo -command "Get-PhysicalDisk | Where-Object MediaType -eq ''SSD''"') do set "hasSSD=true"
if "!hasSSD!"=="true" (
    echo SSD detected - Running TRIM optimization
    defrag -C /O /U /V
) else (
    echo Starting defragmentation process
    defrag -C /X /U /V
)
if !errorlevel! == 0 (echo [SUCCESS] Drive optimization completed successfully) else (echo [ERROR] Error during optimization)
call :GO TOOLS_MENU

:CHKDSK
cls & echo Disk Error Checking Utility
powershell -NoProfile -Command "try { Get-CimInstance Win32_LogicalDisk | ForEach-Object { $t=if($_.Size){[math]::Round($_.Size/1GB,2)}else{0}; $d=switch($_.DriveType){0{'Unknown'}1{'NoRoot'}2{'Removable'}3{'Local'}4{'Network'}5{'CD-ROM'}6{'RAM'}default{'Other'}}; Write-Host ('{0,-8} {1,-10} {2,8} GB' -f ('Drive '+$_.DeviceID),('['+$d+']'),$t) } } catch { Write-Host 'Logical disk information not available' }"

:SELECT_DRIVE
set /p "drive=Enter drive letter to check (e.g., C): "
set "drive=%drive:"=%"
set "drive=%drive:~0,1%"

if not defined drive goto SELECT_DRIVE
echo %drives% | find /i "%drive%" >nul
if !errorlevel! neq 0 (echo Invalid drive letter: %drive% & goto SELECT_DRIVE)

:CHECK_MENU
cls & echo. & echo.
echo                        --------------------------------- CHKDSK ----------------------------------
echo.
echo                          [1] Quick Check                                          [2] Full Check
echo.
echo                                                         [0] Back
echo.
echo                        ---------------------------------------------------------------------------

echo. & set /p choice="Select an option: "
if "%choice%"=="1" goto QUICK_CHECK
if "%choice%"=="2" goto FULL_CHECK
if "%choice%"=="0" goto TOOLS_MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-2)
pause
goto CHECK_MENU

:QUICK_CHECK
cls & echo Running Quick Check on Drive %drive%:

echo Checking if this is the system drive
for /f %%s in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).SystemDrive"') do set sysdrive=%%s
if /i "%drive%:"=="!sysdrive!" (
    echo [INFO] This is the SYSTEM drive. CHKDSK will run on next reboot.
    echo Scheduling CHKDSK for next system restart
    echo Y | chkdsk %drive%: /f >nul
) else (    
    echo Running CHKDSK with error fixing only
    chkdsk %drive%: /f /x
)

echo. & echo Quick check completed.
call :GO TOOLS_MENU

:FULL_CHECK
cls & echo Running Full Check on Drive %drive%:
for /f %%s in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).SystemDrive"') do set sysdrive=%%s
if /i "%drive%:"=="!sysdrive!" (
    echo [INFO] This is the SYSTEM drive. CHKDSK will run on next reboot.
    echo Scheduling comprehensive CHKDSK for next system restart
    echo Y | chkdsk %drive%: /r >nul
) else (
    echo Running comprehensive CHKDSK with bad sector scanning 
    chkdsk %drive%: /r
)

echo. & echo Full check completed
call :GO TOOLS_MENU

:MEMORY_DIAG
cls & echo This will schedule a comprehensive memory test
start "" mdsched.exe
call :GO TOOLS_MENU

:CLEAN_MGR
cls & echo Launching Disk Cleanup
cleanmgr /d C
call :GO TOOLS_MENU


:OTHER_MENU
cls
echo.
echo.
echo                        ----------------------------------- OTHER ---------------------------------
echo.
echo                           [1] Run Chris Titus Tool                           [2] Run OO Shutup 10
echo.
echo                           [3] Internet speed test                            [0] Back
echo.
echo                        ---------------------------------------------------------------------------
echo.

set /p other_choice="Select an option: "

if "%other_choice%"=="1" goto CHRIS_TITUS
if "%other_choice%"=="2" goto OO_SHUTUP
if "%other_choice%"=="3" goto NET_SPEED_TEST
if "%other_choice%"=="0" goto MENU

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-3)
pause
goto OTHER_MENU

:CHRIS_TITUS
cls & echo Running Chris Titus Tool...
powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb https://christitus.com/win | iex"
call :GO OTHER_MENU

:OO_SHUTUP
cls
set "OOSU_DIR=%TEMP%\OOSU10"
set "OOSU_EXE=%OOSU_DIR%\OOSU10.exe"

if not exist "%OOSU_DIR%" mkdir "%OOSU_DIR%" >nul 2>&1
if not exist "%OOSU_EXE%" (
    echo Downloading OO ShutUp10...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;(New-Object Net.WebClient).DownloadFile('https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe','%OOSU_EXE%')"
    if not exist "%OOSU_EXE%" (
        echo Failed to download OO ShutUp10
        call :GO OTHER_MENU
    )
)

echo Running OO ShutUp10
start "" "%OOSU_EXE%"
call :GO OTHER_MENU

:NET_SPEED_TEST
cls
set "TEMP_ZIP=%TEMP%\speedtest_cli.zip"
set "EXTRACT_DIR=%TEMP%\speedtest_cli"
set "EXE_PATH=%EXTRACT_DIR%\speedtest.exe"

if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%" >nul 2>&1
if not exist "%EXE_PATH%" (
    echo Downloading Speedtest CLI from Ookla...
	powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip', '%TEMP_ZIP%')"
    if not exist "%TEMP_ZIP%" (echo You can download it manually from the: %SPEEDTEST_URL% & call :GO NETWORK_MENU)

    powershell -Command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%EXTRACT_DIR%' -Force" >nul 2>&1
	    if not exist "%EXE_PATH%" (
        echo Download or Extraction failed
        call :GO OTHER_MENU
    )
    del "%TEMP_ZIP%" >nul 2>&1
)

echo Measuring your internet speed
"%EXE_PATH%" --accept-license --accept-gdpr
call :GO OTHER_MENU




:: Help functions
:PATH
set "folder=%~1"
set "Operation=%~2"
set "LogDir=%ProgramData%\Windows_Optimization_Script" 
set "LogFile=%LogDir%\%folder%\%Operation%.log"
if not exist "%LogDir%\%folder%" (mkdir "%LogDir%\%folder%" >nul 2>&1 || (echo [FAILED] Create log directory>>"%LogFile%" 2>&1 & pause & goto :eof))
(echo Start: %Operation% at %date% & echo.) > "%LogFile%" 2>&1
goto :eof


:SUB_MENU
cls & echo. & echo.

echo      [1] %Apply% 
echo.
echo      [2] %Revert%
echo.
echo      [0] Back

echo. & set /p choice="Select an option: "
if "%choice%"=="1" goto %Routine%
if "%choice%"=="2" goto %Rev_Routine%
if "%choice%"=="0" goto %menu%

echo. & echo [ERROR] Invalid selection. Please choose a valid option between (0-2)
pause
goto SUB_MENU

:GO
pause
goto %1