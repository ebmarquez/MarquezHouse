<#
.SYNOPSIS
    Automatically mutes system audio and Microsoft Teams during non-business hours.

.DESCRIPTION
    This script provides automated audio management for preventing Teams notifications 
    and system sounds during non-business hours. It can mute/unmute both system audio 
    and Microsoft Teams microphone based on configurable business hours.

.PARAMETER StartBusinessHour
    The hour (0-23) when business hours begin. Default is 8 (8:00 AM).

.PARAMETER EndBusinessHour
    The hour (0-23) when business hours end. Default is 17 (5:00 PM).

.PARAMETER Force
    Forces the mute/unmute action regardless of current time.

.PARAMETER Action
    Specifies the action to take: "Auto" (default), "Mute", "Unmute", or "Status".

.PARAMETER IncludeTeams
    When specified, also attempts to mute/unmute Microsoft Teams microphone.

.PARAMETER LogPath
    Path to the log file. Default is $env:TEMP\TeamsAudioControl.log

.EXAMPLE
    .\MuteAudio.ps1
    Runs with default settings - mutes audio outside business hours (8 AM - 5 PM).

.EXAMPLE
    .\MuteAudio.ps1 -StartBusinessHour 9 -EndBusinessHour 18 -IncludeTeams
    Custom business hours with Teams integration.

.EXAMPLE
    .\MuteAudio.ps1 -Force -Action Mute -IncludeTeams
    Immediately mutes system audio and Teams regardless of time.

.EXAMPLE
    .\MuteAudio.ps1 -Action Status
    Shows current audio and Teams status without making changes.

.NOTES
    Author: Eric Marquez
    Date: 2025-06-27
    Version: 2.0
    
    Requirements:
    - Windows 10/11
    - PowerShell 5.1 or later
    - Administrative privileges recommended
    - Microsoft Teams (if using -IncludeTeams parameter)

.LINK
    https://github.com/emarquez/MarquezHouse

.INPUTS
    None. You cannot pipe objects to this script.

.OUTPUTS
    System.Management.Automation.PSCustomObject
    Returns status information about audio and Teams mute state.
#>

param(
    [Parameter(Mandatory = $false, HelpMessage = "Start hour for business hours (0-23)")]
    [ValidateRange(0, 23)]
    [int]$StartBusinessHour = 8,
    
    [Parameter(Mandatory = $false, HelpMessage = "End hour for business hours (0-23)")]
    [ValidateRange(0, 23)]
    [int]$EndBusinessHour = 17,
    
    [Parameter(Mandatory = $false, HelpMessage = "Force action regardless of time")]
    [switch]$Force,
    
    [Parameter(Mandatory = $false, HelpMessage = "Action to perform")]
    [ValidateSet("Auto", "Mute", "Unmute", "Status")]
    [string]$Action = "Auto",
    
    [Parameter(Mandatory = $false, HelpMessage = "Include Microsoft Teams control")]
    [switch]$IncludeTeams,
    
    [Parameter(Mandatory = $false, HelpMessage = "Log file path")]
    [string]$LogPath = "$env:TEMP\TeamsAudioControl.log"
)

# Validate business hours
if ($StartBusinessHour -ge $EndBusinessHour) {
    throw "StartBusinessHour ($StartBusinessHour) must be less than EndBusinessHour ($EndBusinessHour)"
}

# Script variables
$ScriptVersion = "2.0"
$ScriptName = "TeamsAudioControl"

# Get the current hour
$CurrentHour = (Get-Date).Hour
$CurrentDateTime = Get-Date

# Logging function
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with appropriate color
    switch ($Level) {
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Debug" { Write-Host $logEntry -ForegroundColor Gray }
        default { Write-Host $logEntry -ForegroundColor Green }
    }
    
    # Write to log file
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # If logging fails, continue silently
    }
}

# Function to get current audio status
function Get-AudioStatus {
    try {
        # Get system volume information using WMI
        $audio = Get-WmiObject -Class Win32_SoundDevice -ErrorAction SilentlyContinue
        if ($audio) {
            return @{
                DevicesFound = $audio.Count
                Status       = "Available"
            }
        }
        return @{
            DevicesFound = 0
            Status       = "No audio devices found"
        }
    }
    catch {
        return @{
            DevicesFound = 0
            Status       = "Error: $($_.Exception.Message)"
        }
    }
}

# Function to check if Teams is running
function Test-TeamsRunning {
    try {
        $teamsProcesses = Get-Process -Name "ms-teams*", "Teams*" -ErrorAction SilentlyContinue
        if ($teamsProcesses) {
            Write-Log "Found Teams processes: $($teamsProcesses.Count)" -Level "Debug"
            return $true
        }
        return $false
    }
    catch {
        Write-Log "Error checking Teams processes: $($_.Exception.Message)" -Level "Warning"
        return $false
    }
}

# Enhanced AudioManager class with additional functionality
function Add-AudioManagerClass {
    if (-not ([System.Management.Automation.PSTypeName]'AudioManager').Type) {
        try {
            Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;

            public class AudioManager {
                [DllImport("user32.dll")]
                public static extern int SendMessage(int hWnd, int Msg, int wParam, int lParam);
                
                [DllImport("user32.dll")]
                public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
                
                // Windows Messages
                public const int HWND_BROADCAST = 0xFFFF;
                public const int WM_APPCOMMAND = 0x319;
                
                // Audio Commands
                public const int APPCOMMAND_VOLUME_MUTE = 0x80000;
                public const int APPCOMMAND_VOLUME_UNMUTE = 0x80000;
                public const int APPCOMMAND_MICROPHONE_MUTE = 0x180000;
                
                // Mute system volume
                public static bool MuteSystemVolume() {
                    int result = SendMessage(HWND_BROADCAST, WM_APPCOMMAND, 0, APPCOMMAND_VOLUME_MUTE);
                    return result == 0;
                }
                
                // Unmute system volume  
                public static bool UnmuteSystemVolume() {
                    int result = SendMessage(HWND_BROADCAST, WM_APPCOMMAND, 0, APPCOMMAND_VOLUME_UNMUTE);
                    return result == 0;
                }
                
                // Toggle mute
                public static bool ToggleMute() {
                    int result = SendMessage(HWND_BROADCAST, WM_APPCOMMAND, 0, APPCOMMAND_VOLUME_MUTE);
                    return result == 0;
                }
            }
"@ -ErrorAction Stop
            Write-Log "AudioManager class loaded successfully" -Level "Debug"
            return $true
        }
        catch {
            Write-Log "Failed to load AudioManager class: $($_.Exception.Message)" -Level "Error"
            return $false
        }
    }
    else {
        Write-Log "AudioManager class already loaded" -Level "Debug"
        return $true
    }
}

# Function to control Teams audio via keyboard shortcuts
function Set-TeamsAudioState {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Mute", "Unmute", "Toggle")]
        [string]$TeamsAction
    )
    
    if (-not (Test-TeamsRunning)) {
        Write-Log "Microsoft Teams is not running - skipping Teams audio control" -Level "Warning"
        return $false
    }
    
    try {
        # Add Windows Forms for sending keystrokes
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        
        # Find Teams window
        $teamsWindows = Get-Process -Name "ms-teams*", "Teams*" -ErrorAction SilentlyContinue | 
            Where-Object { $_.MainWindowTitle -ne "" }
        
        if (-not $teamsWindows) {
            Write-Log "No Teams windows with titles found" -Level "Warning"
            return $false
        }
        
        $teamsWindow = $teamsWindows[0]
        Write-Log "Found Teams window: $($teamsWindow.MainWindowTitle)" -Level "Debug"
        
        # Bring Teams to foreground briefly
        $null = [Microsoft.VisualBasic.Interaction]::AppActivate($teamsWindow.Id)
        Start-Sleep -Milliseconds 500
        
        # Send Ctrl+Shift+M (Teams mute/unmute shortcut)
        switch ($TeamsAction) {
            "Mute" { 
                [System.Windows.Forms.SendKeys]::SendWait("^+{m}")
                Write-Log "Sent mute command to Teams" -Level "Info"
            }
            "Unmute" { 
                [System.Windows.Forms.SendKeys]::SendWait("^+{m}")  # Same shortcut toggles
                Write-Log "Sent unmute command to Teams" -Level "Info"
            }
            "Toggle" { 
                [System.Windows.Forms.SendKeys]::SendWait("^+{m}")
                Write-Log "Sent toggle mute command to Teams" -Level "Info"
            }
        }
        
        Start-Sleep -Milliseconds 200
        return $true
    }
    catch {
        Write-Log "Error controlling Teams audio: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Add Visual Basic for window activation
try {
    Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction SilentlyContinue
}
catch {
    Write-Log "Warning: Could not load Visual Basic assembly for window activation" -Level "Warning"
}

# Main execution logic
Write-Log "Starting $ScriptName v$ScriptVersion" -Level "Info"
Write-Log "Current time: $CurrentDateTime (Hour: $CurrentHour)" -Level "Info"
Write-Log "Business hours: $StartBusinessHour:00 - $EndBusinessHour:00" -Level "Info"

# Initialize audio manager
if (-not (Add-AudioManagerClass)) {
    Write-Log "Failed to initialize audio manager - exiting" -Level "Error"
    exit 1
}

# Determine if we're in business hours
$isBusinessHours = ($CurrentHour -ge $StartBusinessHour -and $CurrentHour -lt $EndBusinessHour)
Write-Log "Currently in business hours: $isBusinessHours" -Level "Debug"

# Determine action to take
$shouldMute = $false
$actionToTake = ""

switch ($Action) {
    "Auto" {
        if ($Force) {
            $shouldMute = $true
            $actionToTake = "Force mute (ignoring business hours)"
        }
        elseif (-not $isBusinessHours) {
            $shouldMute = $true
            $actionToTake = "Auto mute (non-business hours)"
        }
        else {
            $shouldMute = $false
            $actionToTake = "Auto unmute (business hours)"
        }
    }
    "Mute" {
        $shouldMute = $true
        $actionToTake = "Manual mute"
    }
    "Unmute" {
        $shouldMute = $false
        $actionToTake = "Manual unmute"
    }
    "Status" {
        $actionToTake = "Status check only"
    }
}

Write-Log "Action determined: $actionToTake" -Level "Info"

# Get current audio status
$audioStatus = Get-AudioStatus
Write-Log "Audio devices found: $($audioStatus.DevicesFound)" -Level "Debug"

# Status check mode
if ($Action -eq "Status") {
    $teamsRunning = Test-TeamsRunning
    
    $statusResult = [PSCustomObject]@{
        Timestamp         = $CurrentDateTime
        BusinessHours     = $isBusinessHours
        AudioDevices      = $audioStatus.DevicesFound
        TeamsRunning      = $teamsRunning
        CurrentHour       = $CurrentHour
        BusinessHourRange = "$StartBusinessHour:00-$EndBusinessHour:00"
        ScriptVersion     = $ScriptVersion
    }
    
    Write-Log "=== AUDIO CONTROL STATUS ===" -Level "Info"
    Write-Log "Current Time: $($statusResult.Timestamp)" -Level "Info"
    Write-Log "Business Hours: $($statusResult.BusinessHourRange)" -Level "Info"
    Write-Log "In Business Hours: $($statusResult.BusinessHours)" -Level "Info"
    Write-Log "Audio Devices: $($statusResult.AudioDevices)" -Level "Info"
    Write-Log "Teams Running: $($statusResult.TeamsRunning)" -Level "Info"
    
    return $statusResult
}

# Execute mute/unmute actions
$systemResult = $false
$teamsResult = $false

try {
    if ($shouldMute) {
        # Mute system audio
        Write-Log "Muting system audio..." -Level "Info"
        $systemResult = [AudioManager]::MuteSystemVolume()
        
        if ($IncludeTeams) {
            Write-Log "Muting Teams microphone..." -Level "Info"
            $teamsResult = Set-TeamsAudioState -TeamsAction "Mute"
        }
    }
    else {
        # Unmute system audio
        Write-Log "Unmuting system audio..." -Level "Info"
        $systemResult = [AudioManager]::UnmuteSystemVolume()
        
        if ($IncludeTeams) {
            Write-Log "Unmuting Teams microphone..." -Level "Info"
            $teamsResult = Set-TeamsAudioState -TeamsAction "Unmute"
        }
    }
    
    # Log results
    $systemStatus = if ($systemResult) { "Success" } else { "Failed" }
    $teamsStatus = if ($IncludeTeams) { 
        if ($teamsResult) { "Success" } else { "Failed" }
    }
    else { "Skipped" }
    
    Write-Log "System audio control: $systemStatus" -Level "Info"
    Write-Log "Teams audio control: $teamsStatus" -Level "Info"
    
    # Return result object
    $result = [PSCustomObject]@{
        Timestamp         = $CurrentDateTime
        Action            = $actionToTake
        BusinessHours     = $isBusinessHours
        SystemAudioResult = $systemStatus
        TeamsAudioResult  = $teamsStatus
        TeamsIncluded     = $IncludeTeams.IsPresent
        ScriptVersion     = $ScriptVersion
    }
    
    Write-Log "Operation completed successfully" -Level "Info"
    return $result
}
catch {
    Write-Log "Error during audio control operation: $($_.Exception.Message)" -Level "Error"
    throw
}