<#
.SYNOPSIS
    Checks the current audio mute status of the system and Teams.

.DESCRIPTION
    This script provides various methods to detect if audio is muted on the system,
    including system audio devices, Windows services, and Microsoft Teams status.
    It's designed to work alongside the MuteAudio.ps1 script for status verification.

.PARAMETER IncludeTeams
    Include Microsoft Teams mute status check.

.PARAMETER ShowDetails
    Show detailed information about audio system components.

.PARAMETER Continuous
    Run continuously and monitor audio status changes.

.PARAMETER IntervalSeconds
    Interval in seconds for continuous monitoring (default: 5).

.EXAMPLE
    .\Check-AudioMuteStatus.ps1
    Basic audio status check.

.EXAMPLE
    .\Check-AudioMuteStatus.ps1 -IncludeTeams -ShowDetails
    Detailed check including Teams status.

.EXAMPLE
    .\Check-AudioMuteStatus.ps1 -Continuous -IntervalSeconds 10
    Continuous monitoring every 10 seconds.

.NOTES
    Author: Eric Marquez
    Date: 2025-06-27
    Version: 1.0
    
    This script demonstrates the audio state detection methods outlined
    in the PowerShell Best Practices guide.
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTeams,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowDetails,
    
    [Parameter(Mandatory = $false)]
    [switch]$Continuous,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3600)]
    [int]$IntervalSeconds = 5
)

# Windows API definitions for audio control and mute detection
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class AudioStatusAPI {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    
    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveOutGetVolume(IntPtr hwo, out uint dwVolume);
    
    [DllImport("winmm.dll", SetLastError = true)]
    public static extern int waveOutSetVolume(IntPtr hwo, uint dwVolume);
    
    // Constants for Windows messages
    public const uint WM_APPCOMMAND = 0x319;
    public const IntPtr HWND_BROADCAST = (IntPtr)0xFFFF;
    public const int APPCOMMAND_VOLUME_MUTE = 0x80000000;
    public const int APPCOMMAND_VOLUME_UP = 0xA0000000;
    public const int APPCOMMAND_VOLUME_DOWN = 0x90000000;
}
"@ -ErrorAction SilentlyContinue

# Import the functions we need
function Test-AudioDevices {
    try {
        $audioDevices = Get-WmiObject -Class Win32_SoundDevice -ErrorAction SilentlyContinue
        return [PSCustomObject]@{
            DevicesFound = if ($audioDevices) { $audioDevices.Count } else { 0 }
            DeviceNames = if ($audioDevices) { $audioDevices.Name } else { @() }
            Status = if ($audioDevices) { "Available" } else { "No devices found" }
        }
    }
    catch {
        return [PSCustomObject]@{
            DevicesFound = 0
            DeviceNames = @()
            Status = "Error: $($_.Exception.Message)"
        }
    }
}

function Test-AudioServices {
    try {
        $requiredServices = @("AudioSrv", "AudioEndpointBuilder")
        $services = Get-Service -Name $requiredServices -ErrorAction SilentlyContinue
        
        $serviceStatus = @{}
        foreach ($service in $services) {
            $serviceStatus[$service.Name] = $service.Status.ToString()
        }
        
        $runningCount = ($services | Where-Object { $_.Status -eq "Running" }).Count
        
        return [PSCustomObject]@{
            TotalServices = $services.Count
            RunningServices = $runningCount
            RequiredServices = $requiredServices.Count
            ServiceStatus = $serviceStatus
            AllRunning = $runningCount -eq $requiredServices.Count
        }
    }
    catch {
        return [PSCustomObject]@{
            TotalServices = 0
            RunningServices = 0
            RequiredServices = 2
            ServiceStatus = @{}
            AllRunning = $false
            Error = $_.Exception.Message
        }
    }
}

function Test-AudioProcesses {
    try {
        $audioProcesses = Get-Process -Name "audiodg" -ErrorAction SilentlyContinue
        return [PSCustomObject]@{
            AudioDriverProcesses = $audioProcesses.Count
            ProcessIds = if ($audioProcesses) { $audioProcesses.Id } else { @() }
            Running = $audioProcesses.Count -gt 0
        }
    }
    catch {
        return [PSCustomObject]@{
            AudioDriverProcesses = 0
            ProcessIds = @()
            Running = $false
        }
    }
}

function Test-SystemAudioMuted {
    <#
    .SYNOPSIS
        Checks if system audio is currently muted using Windows API.
    
    .DESCRIPTION
        Uses Windows API calls to determine the actual mute state of the system audio.
        This is the most reliable method for detecting if audio is muted.
    
    .OUTPUTS
        [PSCustomObject] Object containing mute status and volume information
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $result = [PSCustomObject]@{
        IsMuted = $null
        VolumeLevel = $null
        LeftChannel = $null
        RightChannel = $null
        DetectionMethod = "WindowsAPI"
        LastChecked = Get-Date
        Error = $null
    }
    
    try {
        Write-Verbose "Checking system audio mute status using Windows API..."
        
        # Check if Windows Audio service is running first
        $audioService = Get-Service -Name "AudioSrv" -ErrorAction SilentlyContinue
        if ($null -eq $audioService -or $audioService.Status -ne "Running") {
            $result.Error = "Windows Audio service is not running"
            return $result
        }
        
        # Get current volume level to determine mute status
        $volume = 0
        $apiResult = [AudioStatusAPI]::waveOutGetVolume([IntPtr]::Zero, [ref]$volume)
        
        if ($apiResult -eq 0) {
            # Extract left and right channel volumes (16-bit values)
            $leftVolume = $volume -band 0xFFFF
            $rightVolume = ($volume -shr 16) -band 0xFFFF
            
            $result.LeftChannel = $leftVolume
            $result.RightChannel = $rightVolume
            $result.VolumeLevel = [Math]::Max($leftVolume, $rightVolume)
            
            # Consider muted if both channels are at 0
            $result.IsMuted = ($leftVolume -eq 0 -and $rightVolume -eq 0)
            
            Write-Verbose "Volume levels - Left: $leftVolume, Right: $rightVolume (Muted: $($result.IsMuted))"
        }
        else {
            $result.Error = "Could not retrieve volume status. API Error code: $apiResult"
        }
        
        return $result
    }
    catch {
        $result.Error = "Exception during mute detection: $($_.Exception.Message)"
        Write-Error "Failed to check system audio mute status: $($_.Exception.Message)"
        return $result
    }
}

function Test-TeamsStatus {
    <#
    .SYNOPSIS
        Enhanced Teams status detection including potential mute state indicators.
    #>
    try {
        # Check for both new Teams and classic Teams
        $teamsProcesses = Get-Process -Name "ms-teams*", "Teams*" -ErrorAction SilentlyContinue
        
        $result = [PSCustomObject]@{
            IsRunning = $false
            ProcessCount = 0
            WindowCount = 0
            Processes = @()
            WindowTitles = @()
            IsMuted = $null
            MuteConfidence = "Unknown"
            DetectionMethod = "None"
            Note = "Teams not running"
        }
        
        if (-not $teamsProcesses) {
            return $result
        }
        
        $result.IsRunning = $true
        $result.ProcessCount = $teamsProcesses.Count
        
        # Check for windows with titles (indicates active Teams sessions)
        $activeWindows = $teamsProcesses | Where-Object { $_.MainWindowTitle -ne "" }
        $result.WindowCount = $activeWindows.Count
        $result.Processes = $teamsProcesses | Select-Object Name, Id, @{Name="HasWindow"; Expression={$_.MainWindowTitle -ne ""}}
        
        if ($activeWindows) {
            $result.WindowTitles = $activeWindows.MainWindowTitle
            $result.DetectionMethod = "WindowTitle"
            
            # Enhanced heuristic analysis of window titles for mute indicators
            $allTitles = $result.WindowTitles -join " "
            
            # Look for explicit mute indicators
            if ($allTitles -match "muted|\(muted\)|mute") {
                $result.IsMuted = $true
                $result.MuteConfidence = "Medium"
                $result.Note = "Mute indicator found in window title"
            }
            elseif ($allTitles -match "unmuted|\(unmuted\)|unmute") {
                $result.IsMuted = $false
                $result.MuteConfidence = "Medium"  
                $result.Note = "Unmute indicator found in window title"
            }
            else {
                # No explicit indicators found
                $result.IsMuted = $null
                $result.MuteConfidence = "Unknown"
                $result.Note = "No clear mute indicators in window titles. Use Ctrl+Shift+M to toggle."
            }
        }
        else {
            $result.DetectionMethod = "ProcessOnly"
            $result.Note = "Teams is running but no main windows detected. Mute state unknown."
        }
        
        return $result
    }
    catch {
        return [PSCustomObject]@{
            IsRunning = $false
            ProcessCount = 0
            WindowCount = 0
            Processes = @()
            WindowTitles = @()
            IsMuted = $null
            MuteConfidence = "Unknown"
            DetectionMethod = "Error"
            Note = "Error checking Teams: $($_.Exception.Message)"
        }
    }
}

function Get-AudioSystemStatus {
    param(
        [bool]$IncludeTeamsCheck = $false,
        [bool]$ShowDetailedInfo = $false
    )
    
    $timestamp = Get-Date
    
    # Core audio system checks
    $devices = Test-AudioDevices
    $services = Test-AudioServices
    $processes = Test-AudioProcesses
    
    # NEW: Actual mute status detection
    $muteStatus = Test-SystemAudioMuted
    
    # Determine overall system readiness
    $systemReady = ($devices.DevicesFound -gt 0) -and 
                   $services.AllRunning -and 
                   $processes.Running
    
    $result = [PSCustomObject]@{
        Timestamp = $timestamp
        SystemReady = $systemReady
        AudioDevices = $devices
        AudioServices = $services
        AudioProcesses = $processes
        SystemMuteStatus = $muteStatus
        OverallMuteState = $null
    }
    
    # Determine overall mute state
    if ($null -ne $muteStatus.IsMuted) {
        $result.OverallMuteState = if ($muteStatus.IsMuted) { "Muted" } else { "Unmuted" }
    }
    else {
        $result.OverallMuteState = "Unknown"
    }
    
    # Add Teams information if requested
    if ($IncludeTeamsCheck) {
        $teams = Test-TeamsStatus
        $result | Add-Member -NotePropertyName "Teams" -NotePropertyValue $teams
        $result | Add-Member -NotePropertyName "TeamsReady" -NotePropertyValue $teams.IsRunning
        
        # Update overall mute state considering Teams
        if ($teams.IsRunning -and $null -ne $teams.IsMuted) {
            if ($result.OverallMuteState -eq "Unknown") {
                $result.OverallMuteState = if ($teams.IsMuted) { "Teams Muted" } else { "Teams Unmuted" }
            }
            elseif ($result.OverallMuteState -eq "Unmuted" -and $teams.IsMuted) {
                $result.OverallMuteState = "System Unmuted, Teams Muted"
            }
            elseif ($result.OverallMuteState -eq "Muted" -and -not $teams.IsMuted) {
                $result.OverallMuteState = "System Muted, Teams Unmuted"
            }
        }
    }
    
    return $result
}

function Show-AudioStatus {
    param(
        [PSCustomObject]$Status,
        [bool]$ShowDetails = $false
    )
    
    # Header
    Write-Host "`n🔊 Audio System Status Check" -ForegroundColor Cyan
    Write-Host "Time: $($Status.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "=" * 50 -ForegroundColor Gray
    
    # Overall status
    $statusColor = if ($Status.SystemReady) { "Green" } else { "Red" }
    $statusText = if ($Status.SystemReady) { "✅ READY" } else { "❌ ISSUES DETECTED" }
    Write-Host "System Status: $statusText" -ForegroundColor $statusColor
    
    # NEW: Overall mute state
    $muteStateColor = switch ($Status.OverallMuteState) {
        "Muted" { "Red" }
        "Unmuted" { "Green" }
        { $_ -like "*Muted*" } { "Yellow" }
        default { "Gray" }
    }
    Write-Host "Mute State: $($Status.OverallMuteState)" -ForegroundColor $muteStateColor
    
    # Audio devices
    $deviceColor = if ($Status.AudioDevices.DevicesFound -gt 0) { "Green" } else { "Red" }
    Write-Host "Audio Devices: $($Status.AudioDevices.DevicesFound) found" -ForegroundColor $deviceColor
    
    if ($ShowDetails -and $Status.AudioDevices.DevicesFound -gt 0) {
        foreach ($device in $Status.AudioDevices.DeviceNames) {
            Write-Host "  • $device" -ForegroundColor Gray
        }
    }
    
    # Audio services
    $serviceColor = if ($Status.AudioServices.AllRunning) { "Green" } else { "Red" }
    Write-Host "Audio Services: $($Status.AudioServices.RunningServices)/$($Status.AudioServices.RequiredServices) running" -ForegroundColor $serviceColor
    
    if ($ShowDetails) {
        foreach ($service in $Status.AudioServices.ServiceStatus.GetEnumerator()) {
            $svcColor = if ($service.Value -eq "Running") { "Green" } else { "Red" }
            Write-Host "  • $($service.Key): $($service.Value)" -ForegroundColor $svcColor
        }
    }
    
    # Audio processes
    $processColor = if ($Status.AudioProcesses.Running) { "Green" } else { "Yellow" }
    Write-Host "Audio Processes: $($Status.AudioProcesses.AudioDriverProcesses) driver processes" -ForegroundColor $processColor
    
    # NEW: System mute status details
    Write-Host "`n🔇 Mute Status Details:" -ForegroundColor Cyan
    if ($null -ne $Status.SystemMuteStatus.Error) {
        Write-Host "  System Audio: Error - $($Status.SystemMuteStatus.Error)" -ForegroundColor Red
    }
    elseif ($null -ne $Status.SystemMuteStatus.IsMuted) {
        $sysMuteColor = if ($Status.SystemMuteStatus.IsMuted) { "Red" } else { "Green" }
        $sysMuteText = if ($Status.SystemMuteStatus.IsMuted) { "[MUTED]" } else { "[UNMUTED]" }
        Write-Host "  System Audio: $sysMuteText" -ForegroundColor $sysMuteColor
        
        if ($ShowDetails) {
            Write-Host "    Left Channel: $($Status.SystemMuteStatus.LeftChannel)" -ForegroundColor Gray
            Write-Host "    Right Channel: $($Status.SystemMuteStatus.RightChannel)" -ForegroundColor Gray
            Write-Host "    Max Volume: $($Status.SystemMuteStatus.VolumeLevel)" -ForegroundColor Gray
            Write-Host "    Detection: $($Status.SystemMuteStatus.DetectionMethod)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  System Audio: Status unknown" -ForegroundColor Yellow
    }
    
    # Teams status (if included)
    if ($Status.PSObject.Properties.Name -contains "Teams") {
        $teamsColor = if ($Status.Teams.IsRunning) { "Green" } else { "Yellow" }
        $teamsText = if ($Status.Teams.IsRunning) { "Running ($($Status.Teams.ProcessCount) processes)" } else { "Not running" }
        Write-Host "  Teams Status: $teamsText" -ForegroundColor $teamsColor
        
        if ($Status.Teams.IsRunning) {
            if ($null -ne $Status.Teams.IsMuted) {
                $teamsMuteColor = if ($Status.Teams.IsMuted) { "Red" } else { "Green" }
                $teamsMuteText = if ($Status.Teams.IsMuted) { "[LIKELY MUTED]" } else { "[LIKELY UNMUTED]" }
                Write-Host "  Teams Mute: $teamsMuteText (Confidence: $($Status.Teams.MuteConfidence))" -ForegroundColor $teamsMuteColor
            }
            else {
                Write-Host "  Teams Mute: Unknown" -ForegroundColor Yellow
            }
            
            if ($ShowDetails) {
                Write-Host "    Active Windows: $($Status.Teams.WindowCount)" -ForegroundColor Gray
                Write-Host "    Detection Method: $($Status.Teams.DetectionMethod)" -ForegroundColor Gray
                if ($Status.Teams.WindowTitles) {
                    foreach ($title in $Status.Teams.WindowTitles) {
                        Write-Host "      - $title" -ForegroundColor Gray
                    }
                }
                Write-Host "    Note: $($Status.Teams.Note)" -ForegroundColor Gray
            }
        }
    }
    
    # Recommendations
    if (-not $Status.SystemReady) {
        Write-Host "`n⚠️  System Recommendations:" -ForegroundColor Yellow
        
        if ($Status.AudioDevices.DevicesFound -eq 0) {
            Write-Host "  • Check audio device drivers" -ForegroundColor Gray
            Write-Host "  • Verify audio hardware is connected" -ForegroundColor Gray
        }
        
        if (-not $Status.AudioServices.AllRunning) {
            Write-Host "  • Start audio services:" -ForegroundColor Gray
            Write-Host "    Start-Service AudioSrv, AudioEndpointBuilder" -ForegroundColor White
        }
        
        if (-not $Status.AudioProcesses.Running) {
            Write-Host "  • Audio driver processes not running" -ForegroundColor Gray
            Write-Host "  • Consider restarting audio services" -ForegroundColor Gray
        }
    }
    
    # Mute control recommendations
    if ($Status.SystemReady) {
        Write-Host "`n💡 Mute Control Options:" -ForegroundColor Cyan
        Write-Host "  • System Audio: Use MuteAudio.ps1 script" -ForegroundColor Gray
        if ($Status.PSObject.Properties.Name -contains "Teams" -and $Status.Teams.IsRunning) {
            Write-Host "  • Teams Audio: Press Ctrl+Shift+M or use MuteAudio.ps1 -IncludeTeams" -ForegroundColor Gray
        }
        elseif ($Status.PSObject.Properties.Name -contains "Teams") {
            Write-Host "  • Teams Audio: Start Teams first, then use Ctrl+Shift+M" -ForegroundColor Gray
        }
    }
}

# Main execution
Write-Host "🎯 Audio Mute Status Checker" -ForegroundColor Green
Write-Host "Checking system audio and mute capabilities..." -ForegroundColor Gray

if ($Continuous) {
    Write-Host "`nStarting continuous monitoring (Ctrl+C to stop)..." -ForegroundColor Yellow
    Write-Host "Update interval: $IntervalSeconds seconds`n" -ForegroundColor Gray
    
    try {
        do {
            Clear-Host
            Write-Host "🎯 Audio Mute Status Checker - Continuous Mode" -ForegroundColor Green
            Write-Host "Press Ctrl+C to stop monitoring`n" -ForegroundColor Yellow
            
            $status = Get-AudioSystemStatus -IncludeTeamsCheck:$IncludeTeams -ShowDetailedInfo:$ShowDetails
            Show-AudioStatus -Status $status -ShowDetails:$ShowDetails
            
            Write-Host "`nNext update in $IntervalSeconds seconds..." -ForegroundColor Gray
            Start-Sleep -Seconds $IntervalSeconds
        } while ($true)
    }
    catch {
        Write-Host "`nMonitoring stopped." -ForegroundColor Yellow
    }
}
else {
    # Single check
    $status = Get-AudioSystemStatus -IncludeTeamsCheck:$IncludeTeams -ShowDetailedInfo:$ShowDetails
    Show-AudioStatus -Status $status -ShowDetails:$ShowDetails
    
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
    if ($status.SystemReady) {
        Write-Host "  • Current mute state: $($status.OverallMuteState)" -ForegroundColor White
        Write-Host "  • Test audio control: .\MuteAudio.ps1 -Action Status" -ForegroundColor Gray
        Write-Host "  • Force mute test: .\MuteAudio.ps1 -Force -Action Mute" -ForegroundColor Gray
        if ($IncludeTeams -and $status.TeamsReady) {
            Write-Host "  • Test with Teams: .\MuteAudio.ps1 -IncludeTeams -Action Status" -ForegroundColor Gray
        }
        if ($null -ne $status.SystemMuteStatus.IsMuted) {
            $toggleAction = if ($status.SystemMuteStatus.IsMuted) { "Unmute" } else { "Mute" }
            Write-Host "  • Toggle to $toggleAction : .\MuteAudio.ps1 -Force -Action $toggleAction" -ForegroundColor Gray
        }
    } else {
        Write-Host "  • Resolve audio system issues before using MuteAudio.ps1" -ForegroundColor Gray
        Write-Host "  • Run with -ShowDetails for more information" -ForegroundColor Gray
    }
    
    # Return status object for programmatic use
    return $status
}
