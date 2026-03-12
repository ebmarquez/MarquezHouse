# PowerShell Best Practices Guide

This guide outlines the PowerShell best practices for the MarquezHouse automation project.

## Table of Contents

- [Code Structure](#code-structure)
- [Documentation](#documentation)
- [Error Handling](#error-handling)
- [Security](#security)
- [Performance](#performance)
- [Audio and Mute Status Checking](#audio-and-mute-status-checking)
- [Testing](#testing)
- [Deployment](#deployment)

## Code Structure

### Function and Variable Naming

```powershell
# ✅ Good: Use approved verbs and PascalCase for functions
function Get-AudioStatus { }
function Set-AudioMute { }
function New-ScheduledAudioTask { }

# ✅ Good: Use camelCase for variables
$currentHour = (Get-Date).Hour
$businessHours = @{ Start = 8; End = 17 }

# ❌ Bad: Non-standard verbs
function CheckAudio { }
function MuteSound { }
```

### Parameter Definition

```powershell
# ✅ Good: Complete parameter definition with validation
param(
    [Parameter(Mandatory = $true, HelpMessage = "Start hour for business hours (0-23)")]
    [ValidateRange(0, 23)]
    [int]$StartHour,
    
    [Parameter(Mandatory = $true, HelpMessage = "End hour for business hours (0-23)")]
    [ValidateRange(0, 23)]
    [int]$EndHour,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)
```

### Script Headers

```powershell
<#
.SYNOPSIS
    Brief description of what the script does.

.DESCRIPTION
    Detailed description including prerequisites and behavior.

.PARAMETER ParameterName
    Description of each parameter.

.EXAMPLE
    Example 1: Basic usage
    .\Script.ps1 -Parameter "Value"
    
.EXAMPLE
    Example 2: Advanced usage with multiple parameters
    .\Script.ps1 -StartHour 9 -EndHour 18 -Force

.NOTES
    Author: [Your Name]
    Date: [Creation Date]
    Version: [Version Number]
    
.LINK
    https://github.com/username/repo

.INPUTS
    Description of input types accepted.

.OUTPUTS
    Description of output types produced.
#>
```

## Documentation

### Comment-Based Help

Always include comprehensive comment-based help at the beginning of scripts:

```powershell
<#
.SYNOPSIS
    Manages system audio based on business hours.

.DESCRIPTION
    This script automatically mutes or unmutes system audio based on predefined 
    business hours. It uses Windows API calls to control audio settings and can 
    be run as a scheduled task for automated management.

.PARAMETER StartBusinessHour
    The hour (0-23) when business hours begin. Default is 8 (8:00 AM).

.PARAMETER EndBusinessHour  
    The hour (0-23) when business hours end. Default is 17 (5:00 PM).

.PARAMETER Force
    Forces the action regardless of current time.

.EXAMPLE
    .\MuteAudio.ps1
    Runs with default business hours (8 AM to 5 PM).

.EXAMPLE
    .\MuteAudio.ps1 -StartBusinessHour 9 -EndBusinessHour 18
    Sets custom business hours from 9 AM to 6 PM.

.NOTES
    Requires: Windows 10/11, Administrative privileges
    Author: Eric Marquez
    Version: 1.0
#>
```

### Inline Comments

```powershell
# ✅ Good: Explain complex logic
# Check if current time falls within business hours
# Business hours are inclusive of start hour, exclusive of end hour
if ($CurrentHour -ge $StartBusinessHour -and $CurrentHour -lt $EndBusinessHour) {
    # Within business hours - ensure audio is unmuted
    Write-Host "Business hours detected. Unmuting audio..." -ForegroundColor Green
}

# ✅ Good: Explain API calls and magic numbers
# Send Windows message to control volume
# 0xFFFF: HWND_BROADCAST - send to all top-level windows
# 0x319: WM_APPCOMMAND - application command message
# 0x80000000: APPCOMMAND_VOLUME_MUTE - mute command
[AudioManager]::SendMessage(0xFFFF, 0x319, 0, 0x80000000)
```

## Error Handling

### Try-Catch Blocks

```powershell
# ✅ Good: Comprehensive error handling
try {
    # Add the AudioManager class
    Add-Type -TypeDefinition $AudioManagerDefinition -ErrorAction Stop
    
    # Attempt to control audio
    $result = [AudioManager]::SendMessage(0xFFFF, 0x319, 0, $command)
    
    if ($result -eq 0) {
        Write-Warning "Audio command may not have been processed successfully"
    }
}
catch [System.Exception] {
    Write-Error "Failed to load AudioManager class: $($_.Exception.Message)"
    exit 1
}
catch {
    Write-Error "Unexpected error occurred: $($_.Exception.Message)"
    exit 1
}
```

### Parameter Validation

```powershell
# ✅ Good: Validate parameters early
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 23)]
    [int]$StartHour,
    
    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 23)]
    [int]$EndHour,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Mute", "Unmute", "Toggle")]
    [string]$Action = "Auto"
)

# Additional validation logic
if ($StartHour -ge $EndHour) {
    throw "StartHour must be less than EndHour"
}
```

## Security

### Execution Policy

```powershell
# Check execution policy before running sensitive operations
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Warning "Execution policy is Restricted. Script may not run properly."
    Write-Host "Consider running: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
}
```

### Privilege Checking

```powershell
# ✅ Good: Check for required privileges
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Error "This script requires administrative privileges. Please run as Administrator."
    exit 1
}
```

### Secure String Handling

```powershell
# ✅ Good: Use SecureString for sensitive data
param(
    [Parameter(Mandatory = $false)]
    [SecureString]$ApiKey
)

# Convert SecureString to plain text only when necessary
if ($ApiKey) {
    $plainApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKey)
    )
}
```

## Performance

### Efficient Loops

```powershell
# ✅ Good: Use foreach for better performance
$services = Get-Service
foreach ($service in $services) {
    # Process each service
}

# ✅ Good: Use Where-Object with -FilterScript for complex filtering
$runningServices = $services | Where-Object -FilterScript { 
    $_.Status -eq "Running" -and $_.StartType -eq "Automatic" 
}
```

### Memory Management

```powershell
# ✅ Good: Dispose of objects when done
$process = Start-Process -FilePath "notepad.exe" -PassThru
try {
    # Work with process
}
finally {
    if ($process -and -not $process.HasExited) {
        $process.Kill()
    }
    $process.Dispose()
}
```

## Audio and Mute Status Checking

### System Audio Status

When working with audio automation, it's essential to check the current mute status before making changes. Here are best practices for audio status checking:

```powershell
# ✅ Good: Comprehensive audio status check using Windows API
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class AudioStatusChecker {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    
    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveOutGetVolume(IntPtr hwo, out uint dwVolume);
    
    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveOutSetVolume(IntPtr hwo, uint dwVolume);
    
    // Constants
    public const uint WM_APPCOMMAND = 0x319;
    public const IntPtr HWND_BROADCAST = (IntPtr)0xFFFF;
    public const int APPCOMMAND_VOLUME_MUTE = 0x80000000;
    public const int APPCOMMAND_VOLUME_UP = 0xA0000000;
    public const int APPCOMMAND_VOLUME_DOWN = 0x90000000;
}
"@

function Test-SystemAudioMuted {
    <#
    .SYNOPSIS
        Checks if system audio is currently muted.
    
    .DESCRIPTION
        Uses Windows API to determine the current mute status of the system audio.
        
    .OUTPUTS
        [bool] True if audio is muted, False if unmuted
    
    .EXAMPLE
        if (Test-SystemAudioMuted) {
            Write-Host "Audio is currently muted"
        } else {
            Write-Host "Audio is not muted"
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    try {
        # Get current volume level to determine mute status
        $volume = 0
        $result = [AudioStatusChecker]::waveOutGetVolume([IntPtr]::Zero, [ref]$volume)
        
        if ($result -eq 0) {
            # Check if volume is 0 (muted) or has value (unmuted)
            $isMuted = ($volume -eq 0)
            Write-Verbose "Current volume level: $volume (Muted: $isMuted)"
            return $isMuted
        }
        else {
            Write-Warning "Could not retrieve volume status. Error code: $result"
            return $false
        }
    }
    catch {
        Write-Error "Failed to check audio mute status: $($_.Exception.Message)"
        return $false
    }
}
```

### Microsoft Teams Mute Status

For Teams integration, checking mute status requires different approaches:

```powershell
function Test-TeamsMuted {
    <#
    .SYNOPSIS
        Checks if Microsoft Teams is muted.
    
    .DESCRIPTION
        Attempts to determine Teams mute status through process and window analysis.
        Note: This is an approximation as Teams doesn't expose direct mute status.
        
    .OUTPUTS
        [PSCustomObject] Object containing Teams status information
    
    .EXAMPLE
        $teamsStatus = Test-TeamsMuted
        if ($teamsStatus.IsMuted) {
            Write-Host "Teams is likely muted"
        }
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $result = [PSCustomObject]@{
        IsRunning = $false
        ProcessFound = $false
        WindowTitle = $null
        IsMuted = $null
        LastChecked = Get-Date
        Method = "ProcessAnalysis"
    }
    
    try {
        # Check if Teams is running
        $teamsProcesses = @(Get-Process | Where-Object { 
            $_.ProcessName -like "*Teams*" -or 
            $_.ProcessName -like "*ms-teams*" 
        })
        
        if ($teamsProcesses.Count -gt 0) {
            $result.IsRunning = $true
            $result.ProcessFound = $true
            
            # Try to get window information (requires additional Windows API calls)
            try {
                $windowTitle = $teamsProcesses[0].MainWindowTitle
                $result.WindowTitle = $windowTitle
                
                # Heuristic: Check if window title contains mute indicators
                # Note: This is not always reliable as Teams may not update window titles
                if ($windowTitle -match "muted|🔇") {
                    $result.IsMuted = $true
                    $result.Method = "WindowTitleAnalysis"
                } else {
                    $result.IsMuted = $false
                    $result.Method = "WindowTitleAnalysis"
                }
            }
            catch {
                Write-Verbose "Could not analyze Teams window: $($_.Exception.Message)"
                $result.IsMuted = $null
                $result.Method = "ProcessOnly"
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to check Teams mute status: $($_.Exception.Message)"
        $result.IsMuted = $null
        return $result
    }
}
```

### Comprehensive Status Reporting

Combine system and application-specific checks for complete audio status:

```powershell
function Get-AudioStatus {
    <#
    .SYNOPSIS
        Gets comprehensive audio status for system and applications.
    
    .DESCRIPTION
        Retrieves mute status for system audio and Microsoft Teams.
        
    .OUTPUTS
        [PSCustomObject] Complete audio status information
    
    .EXAMPLE
        $status = Get-AudioStatus
        Write-Host "System Muted: $($status.System.IsMuted)"
        Write-Host "Teams Muted: $($status.Teams.IsMuted)"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $status = [PSCustomObject]@{
        Timestamp = Get-Date
        System = @{
            IsMuted = $null
            VolumeLevel = $null
            Status = "Unknown"
        }
        Teams = $null
        Summary = $null
    }
    
    try {
        # Check system audio status
        Write-Verbose "Checking system audio status..."
        $systemMuted = Test-SystemAudioMuted
        $status.System.IsMuted = $systemMuted
        $status.System.Status = if ($systemMuted) { "Muted" } else { "Unmuted" }
        
        # Check Teams status
        Write-Verbose "Checking Teams audio status..."
        $status.Teams = Test-TeamsMuted
        
        # Create summary
        $systemStatus = $status.System.Status
        $teamsStatus = if ($null -eq $status.Teams.IsMuted) { 
            "Unknown" 
        } elseif ($status.Teams.IsMuted) { 
            "Muted" 
        } else { 
            "Unmuted" 
        }
        
        $status.Summary = "System: $systemStatus | Teams: $teamsStatus"
        
        return $status
    }
    catch {
        Write-Error "Failed to get complete audio status: $($_.Exception.Message)"
        $status.Summary = "Error retrieving status"
        return $status
    }
}
```

### Status Checking Best Practices

1. **Always verify before action**: Check current state before making changes
   ```powershell
   # ✅ Good: Check before changing
   if (-not (Test-SystemAudioMuted)) {
       Write-Host "Audio is already unmuted. No action needed."
       return
   }
   
   # Proceed with muting logic
   Set-AudioMute -Mute $true
   ```

2. **Use appropriate error handling**: Audio APIs can fail
   ```powershell
   # ✅ Good: Robust status checking with fallbacks
   try {
       $isMuted = Test-SystemAudioMuted
   }
   catch {
       Write-Warning "Primary mute check failed. Using fallback method."
       $isMuted = Test-AudioMuteFallback
   }
   ```

3. **Provide verbose output**: Help with debugging
   ```powershell
   # ✅ Good: Detailed status information
   function Test-SystemAudioMuted {
       [CmdletBinding()]
       param()
       
       Write-Verbose "Starting audio mute status check..."
       $result = # ... check logic ...
       Write-Verbose "Audio mute status check completed. Result: $result"
       return $result
   }
   ```

4. **Cache status when appropriate**: Avoid excessive API calls
   ```powershell
   # ✅ Good: Cache status for short periods
   $script:LastAudioCheck = $null
   $script:LastAudioStatus = $null
   $script:AudioCacheTimeout = 5 # seconds
   
   function Get-CachedAudioStatus {
       $now = Get-Date
       if ($null -eq $script:LastAudioCheck -or 
           ($now - $script:LastAudioCheck).TotalSeconds -gt $script:AudioCacheTimeout) {
           
           $script:LastAudioStatus = Test-SystemAudioMuted
           $script:LastAudioCheck = $now
       }
       
       return $script:LastAudioStatus
   }
   ```

5. **Handle edge cases**: Consider system states and errors
   ```powershell
   # ✅ Good: Handle various system states
   function Test-SystemAudioMuted {
       [CmdletBinding()]
       param()
       
       # Check if audio service is running
       $audioService = Get-Service -Name "AudioSrv" -ErrorAction SilentlyContinue
       if ($null -eq $audioService -or $audioService.Status -ne "Running") {
           Write-Warning "Windows Audio service is not running"
           return $null  # Unknown state
       }
       
       # Check if audio devices are available
       try {
           $audioDevices = Get-WmiObject -Class Win32_SoundDevice -ErrorAction Stop
           if ($audioDevices.Count -eq 0) {
               Write-Warning "No audio devices detected"
               return $null
           }
       }
       catch {
           Write-Warning "Could not enumerate audio devices: $($_.Exception.Message)"
       }
       
       # Proceed with actual mute status check
       # ... implementation ...
   }
   ```

## Testing

### Unit Testing Structure

```powershell
# Test script example: Test-MuteAudio.ps1
Describe "MuteAudio Script Tests" {
    Context "Parameter Validation" {
        It "Should accept valid business hours" {
            { .\MuteAudio.ps1 -StartBusinessHour 8 -EndBusinessHour 17 } | Should -Not -Throw
        }
        
        It "Should reject invalid hour ranges" {
            { .\MuteAudio.ps1 -StartBusinessHour 25 -EndBusinessHour 17 } | Should -Throw
        }
    }
    
    Context "Audio Control" {
        It "Should mute audio outside business hours" {
            # Mock current time to be outside business hours
            Mock Get-Date { [DateTime]::Parse("2023-01-01 06:00:00") }
            # Test mute functionality
        }
    }
}
```

### Integration Testing

```powershell
# Integration test example
function Test-AudioIntegration {
    param(
        [string]$ScriptPath
    )
    
    Write-Host "Testing audio integration..." -ForegroundColor Yellow
    
    # Test 1: Script execution
    try {
        & $ScriptPath -WhatIf
        Write-Host "✅ Script executes without errors" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Test 2: Required types are available
    try {
        Add-Type -TypeDefinition $AudioManagerDefinition
        Write-Host "✅ AudioManager type loads successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ AudioManager type failed to load" -ForegroundColor Red
        return $false
    }
    
    return $true
}
```

## Deployment

### Scheduled Task Best Practices

```powershell
# ✅ Good: Comprehensive scheduled task creation
$taskParams = @{
    TaskName = "MuteAudioTask"
    Description = "Automatically mutes/unmutes audio based on business hours"
    User = $env:USERNAME
    RunLevel = "Highest"
    TaskPath = "\MarquezHouse\"
}

$actionParams = @{
    Execute = "powershell.exe"
    Argument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
    WorkingDirectory = Split-Path $ScriptPath -Parent
}

$triggerParams = @{
    Weekly = $true
    DaysOfWeek = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
    At = "08:00"
}

try {
    $action = New-ScheduledTaskAction @actionParams
    $trigger = New-ScheduledTaskTrigger @triggerParams
    Register-ScheduledTask @taskParams -Action $action -Trigger $trigger
    
    Write-Host "✅ Scheduled task created successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
}
```

### Logging

```powershell
# ✅ Good: Structured logging function
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info",
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP\MarquezHouse.log"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with appropriate color
    switch ($Level) {
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Debug" { Write-Host $logEntry -ForegroundColor Gray }
        default { Write-Host $logEntry -ForegroundColor White }
    }
    
    # Write to log file
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

# Usage example
Write-Log "Audio muted successfully" -Level "Info"
Write-Log "Failed to load audio driver" -Level "Error"
```

## Configuration Management

```powershell
# ✅ Good: External configuration file support
function Get-Configuration {
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$PSScriptRoot\config.json"
    )
    
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content $ConfigPath | ConvertFrom-Json
            return $config
        }
        catch {
            Write-Warning "Failed to parse configuration file. Using defaults."
        }
    }
    
    # Return default configuration
    return @{
        BusinessHours = @{
            Start = 8
            End = 17
        }
        Logging = @{
            Enabled = $true
            Level = "Info"
            Path = "$env:TEMP\MarquezHouse.log"
        }
    }
}
```

## Version Control Integration

```powershell
# ✅ Good: Script versioning and metadata
$ScriptVersion = "1.2.0"
$ScriptName = "MuteAudio"
$LastModified = "2025-06-27"

# Include version information in help
<#
.NOTES
    Version: 1.2.0
    Last Modified: 2025-06-27
    Changes: Added configuration file support, improved error handling
#>
```

This guide provides a foundation for creating robust, maintainable PowerShell scripts for home automation and system administration tasks.

## Audio State Detection

```powershell
# ✅ Good: Check if system audio is muted using WMI
function Test-AudioMuted {
    try {
        # Method 1: Using Windows Audio Session Manager (WASAPI)
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        
        public class AudioEndpointVolume {
            [DllImport("ole32.dll")]
            public static extern int CoCreateInstance(
                ref Guid clsid,
                IntPtr pUnkOuter,
                uint dwClsContext,
                ref Guid iid,
                out IntPtr ppv);
                
            [DllImport("ole32.dll")]
            public static extern int CoInitialize(IntPtr pvReserved);
        }
"@ -ErrorAction SilentlyContinue
        
        # Method 2: Using AudioDeviceManager via WMI (simpler approach)
        $audioDevices = Get-WmiObject -Class Win32_SoundDevice -ErrorAction SilentlyContinue
        if ($audioDevices) {
            return [PSCustomObject]@{
                DevicesFound = $audioDevices.Count
                Method = "WMI"
                Status = "Available"
                IsMuted = $null  # WMI doesn't directly provide mute status
            }
        }
        
        return [PSCustomObject]@{
            DevicesFound = 0
            Method = "None"
            Status = "No audio devices detected"
            IsMuted = $null
        }
    }
    catch {
        return [PSCustomObject]@{
            DevicesFound = 0
            Method = "Error"
            Status = "Error: $($_.Exception.Message)"
            IsMuted = $null
        }
    }
}

# ✅ Good: Alternative method using PowerShell and registry
function Get-SystemVolumeInfo {
    try {
        # Check Windows volume mixer settings via registry
        $volumeRegPath = "HKCU:\Software\Microsoft\Multimedia\Audio\VolumeControl"
        
        if (Test-Path $volumeRegPath) {
            $volumeSettings = Get-ItemProperty -Path $volumeRegPath -ErrorAction SilentlyContinue
            
            return [PSCustomObject]@{
                RegistryPath = $volumeRegPath
                SettingsFound = $null -ne $volumeSettings
                Method = "Registry"
            }
        }
        
        return [PSCustomObject]@{
            RegistryPath = $volumeRegPath
            SettingsFound = $false
            Method = "Registry"
        }
    }
    catch {
        Write-Warning "Unable to access volume registry settings: $($_.Exception.Message)"
        return $null
    }
}

# ✅ Good: Check audio state using multiple methods
function Get-AudioStatus {
    [CmdletBinding()
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    $results = @{
    
    # Test 1: Audio device detection
    $deviceTest = Test-AudioMuted
    $results.DeviceDetection = $deviceTest
    
    # Test 2: Registry check
    $registryTest = Get-SystemVolumeInfo
    $results.RegistryInfo = $registryTest
    
    # Test 3: Process-based detection (check if audio-related processes are running)
    $audioProcesses = Get-Process -Name "audiodg", "winlogon" -ErrorAction SilentlyContinue
    $results.AudioProcesses = @{
        Count = $audioProcesses.Count
        Running = $audioProcesses.Count -gt 0
        Processes = $audioProcesses.Name
    }
    
    # Test 4: Service status
    $audioServices = Get-Service -Name "AudioSrv", "AudioEndpointBuilder" -ErrorAction SilentlyContinue
    $results.AudioServices = @{
        Found = $audioServices.Count
        Running = ($audioServices | Where-Object { $_.Status -eq "Running" }).Count
        Services = $audioServices | ForEach-Object { 
            @{ Name = $_.Name; Status = $_.Status.ToString() }
        }
    }
    
    if ($Detailed) {
        return $results
    }
    
    # Return simplified status
    return [PSCustomObject]@{
        HasAudioDevices = $results.DeviceDetection.DevicesFound -gt 0
        AudioServicesRunning = $results.AudioServices.Running -gt 0
        AudioProcessesActive = $results.AudioProcesses.Running
        OverallStatus = if ($results.DeviceDetection.DevicesFound -gt 0 -and 
                           $results.AudioServices.Running -gt 0) { "Ready" } else { "Issues Detected" }
        Timestamp = Get-Date
    }
}

# ✅ Good: Teams-specific mute detection
function Test-TeamsMuted {
    [CmdletBinding()
    param()
    
    try {
        # Check if Teams is running
        $teamsProcesses = Get-Process -Name "ms-teams*", "Teams*" -ErrorAction SilentlyContinue
        
        if (-not $teamsProcesses) {
            return [PSCustomObject]@{
                TeamsRunning = $false
                TeamsWindows = 0
                MuteStatus = "Teams not running"
                Method = "Process Detection"
            }
        }
        
        # Check for Teams windows with titles
        $teamsWindows = $teamsProcesses | Where-Object { $_.MainWindowTitle -ne "" }
        
        return [PSCustomObject]@{
            TeamsRunning = $true
            TeamsProcesses = $teamsProcesses.Count
            TeamsWindows = $teamsWindows.Count
            WindowTitles = $teamsWindows.MainWindowTitle
            MuteStatus = "Cannot detect mute state directly"
            Method = "Process Detection"
            Note = "Use Ctrl+Shift+M to toggle mute in Teams"
        }
    }
    catch {
        return [PSCustomObject]@{
            TeamsRunning = $false
            TeamsWindows = 0
            MuteStatus = "Error detecting Teams"
            Error = $_.Exception.Message
            Method = "Error"
        }
    }
}
```

### Practical Audio State Checking

```powershell
# ✅ Good: Comprehensive audio status check function
function Get-CompleteAudioStatus {
    [CmdletBinding()
    param(
        [Parameter(Mandatory = $false)]
        [switch]$IncludeTeams,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails
    )
    
    Write-Host "🔊 Checking Audio System Status..." -ForegroundColor Cyan
    
    # System audio status
    $systemAudio = Get-AudioStatus -Detailed:$ShowDetails
    Write-Host "   System Audio: $($systemAudio.OverallStatus)" -ForegroundColor $(
        if ($systemAudio.OverallStatus -eq "Ready") { "Green" } else { "Yellow" }
    )
    
    if ($ShowDetails) {
        Write-Host "   • Audio Devices: $($systemAudio.HasAudioDevices)" -ForegroundColor Gray
        Write-Host "   • Audio Services: $($systemAudio.AudioServicesRunning)" -ForegroundColor Gray
        Write-Host "   • Audio Processes: $($systemAudio.AudioProcessesActive)" -ForegroundColor Gray
    }
    
    # Teams status (if requested)
    $teamsStatus = $null
    if ($IncludeTeams) {
        $teamsStatus = Test-TeamsMuted
        Write-Host "   Teams Status: $($teamsStatus.MuteStatus)" -ForegroundColor $(
            if ($teamsStatus.TeamsRunning) { "Green" } else { "Yellow" }
        )
        
        if ($ShowDetails -and $teamsStatus.TeamsRunning) {
            Write-Host "   • Teams Processes: $($teamsStatus.TeamsProcesses)" -ForegroundColor Gray
            Write-Host "   • Teams Windows: $($teamsStatus.TeamsWindows)" -ForegroundColor Gray
        }
    }
    
    # Return combined status
    $result = [PSCustomObject]@{
        Timestamp = Get-Date
        SystemAudio = $systemAudio
        TeamsAudio = $teamsStatus
        OverallReady = $systemAudio.OverallStatus -eq "Ready"
    }
    
    if ($IncludeTeams) {
        $result | Add-Member -NotePropertyName "TeamsReady" -NotePropertyValue $teamsStatus.TeamsRunning
    }
    
    return $result
}

# Usage examples:
# Get-CompleteAudioStatus
# Get-CompleteAudioStatus -IncludeTeams
# Get-CompleteAudioStatus -IncludeTeams -ShowDetails
```

### Mute State Validation in Scripts

```powershell
# ✅ Good: Validate audio state before attempting mute operations
function Invoke-SafeAudioControl {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Mute", "Unmute", "Toggle")]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeTeams
    )
    
    # Pre-flight check
    Write-Host "Performing pre-flight audio system check..." -ForegroundColor Yellow
    
    $audioStatus = Get-CompleteAudioStatus -IncludeTeams:$IncludeTeams
    
    if (-not $audioStatus.OverallReady) {
        Write-Warning "Audio system not ready. Status: $($audioStatus.SystemAudio.OverallStatus)"
        Write-Host "Troubleshooting steps:" -ForegroundColor Cyan
        Write-Host "  1. Check if audio services are running: Get-Service AudioSrv, AudioEndpointBuilder" -ForegroundColor Gray
        Write-Host "  2. Verify audio drivers are installed" -ForegroundColor Gray
        Write-Host "  3. Test audio playback manually" -ForegroundColor Gray
        return $false
    }
    
    if ($IncludeTeams -and -not $audioStatus.TeamsReady) {
        Write-Warning "Teams integration requested but Teams is not running"
        Write-Host "Teams must be running for microphone control" -ForegroundColor Yellow
    }
    
    # Proceed with audio control
    Write-Host "✅ Audio system ready. Proceeding with $Action action..." -ForegroundColor Green
    
    try {
        # Add your actual audio control logic here
        # This is where you would call your AudioManager methods
        
        # Simulate the operation
        Start-Sleep -Milliseconds 500
        
        Write-Host "✅ Audio $Action operation completed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to perform audio $Action operation: $($_.Exception.Message)"
        return $false
    }
}
```
