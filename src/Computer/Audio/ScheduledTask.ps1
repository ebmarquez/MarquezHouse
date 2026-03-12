<#
.SYNOPSIS
    Creates scheduled tasks for automated Teams and system audio control.

.DESCRIPTION
    This script creates Windows scheduled tasks to automatically mute/unmute
    system audio and Microsoft Teams based on business hours. It creates
    triggers for the beginning and end of business hours.

.PARAMETER StartBusinessHour
    Hour when business begins (0-23). Default is 8.

.PARAMETER EndBusinessHour
    Hour when business ends (0-23). Default is 17.

.PARAMETER IncludeTeams
    Include Microsoft Teams control in the automation.

.PARAMETER TaskName
    Name for the scheduled task. Default is "TeamsAudioControlTask".

.PARAMETER ScriptPath
    Path to the MuteAudio.ps1 script. Auto-detected if not specified.

.EXAMPLE
    .\ScheduledTask.ps1
    Creates tasks with default settings.

.EXAMPLE
    .\ScheduledTask.ps1 -StartBusinessHour 9 -EndBusinessHour 18 -IncludeTeams
    Creates tasks for 9 AM to 6 PM with Teams integration.

.NOTES
    Requires administrative privileges to create scheduled tasks.
    Author: Eric Marquez
    Date: 2025-06-27
    Version: 2.0
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 23)]
    [int]$StartBusinessHour = 8,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 23)]
    [int]$EndBusinessHour = 17,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTeams,
    
    [Parameter(Mandatory = $false)]
    [string]$TaskName = "TeamsAudioControlTask",
    
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath = ""
)

# Auto-detect script path if not provided
if (-not $ScriptPath) {
    $ScriptPath = Join-Path $PSScriptRoot "MuteAudio.ps1"
    if (-not (Test-Path $ScriptPath)) {
        Write-Error "MuteAudio.ps1 not found at $ScriptPath. Please specify -ScriptPath parameter."
        exit 1
    }
}

Write-Host "Setting up scheduled tasks for audio control..." -ForegroundColor Green
Write-Host "Script Path: $ScriptPath" -ForegroundColor Cyan
Write-Host "Business Hours: $StartBusinessHour`:00 - $EndBusinessHour`:00" -ForegroundColor Cyan
Write-Host "Teams Integration: $($IncludeTeams.IsPresent)" -ForegroundColor Cyan

# Build the PowerShell arguments
$baseArgs = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
$businessHourArgs = "-StartBusinessHour $StartBusinessHour -EndBusinessHour $EndBusinessHour"
$teamsArgs = if ($IncludeTeams) { "-IncludeTeams" } else { "" }

# Morning trigger (start of business hours - unmute)
$morningArgs = "$baseArgs $businessHourArgs $teamsArgs -Force -Action Unmute"
$eveningArgs = "$baseArgs $businessHourArgs $teamsArgs -Force -Action Mute"

try {
    # Remove existing task if it exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing task: $TaskName" -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Create morning trigger (unmute at start of business hours)
    $morningTrigger = New-ScheduledTaskTrigger -Daily -At "$StartBusinessHour`:00"
    
    # Create evening trigger (mute at end of business hours)  
    $eveningTrigger = New-ScheduledTaskTrigger -Daily -At "$EndBusinessHour`:00"

    # Create action for morning (unmute)
    $morningAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $morningArgs

    # Create action for evening (mute)
    $eveningAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $eveningArgs

    # Create principal (run as current user with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Register morning task (unmute)
    $morningTaskName = "$TaskName-Morning"
    Register-ScheduledTask -TaskName $morningTaskName -Trigger $morningTrigger -Action $morningAction -Principal $principal -Settings $settings -Description "Unmute audio and Teams at start of business hours ($StartBusinessHour`:00)"

    # Register evening task (mute)
    $eveningTaskName = "$TaskName-Evening"
    Register-ScheduledTask -TaskName $eveningTaskName -Trigger $eveningTrigger -Action $eveningAction -Principal $principal -Settings $settings -Description "Mute audio and Teams at end of business hours ($EndBusinessHour`:00)"

    Write-Host "✅ Successfully created scheduled tasks:" -ForegroundColor Green
    Write-Host "   📅 $morningTaskName - Daily at $StartBusinessHour`:00 (Unmute)" -ForegroundColor Green  
    Write-Host "   📅 $eveningTaskName - Daily at $EndBusinessHour`:00 (Mute)" -ForegroundColor Green
    
    if ($IncludeTeams) {
        Write-Host "   🎯 Teams integration enabled" -ForegroundColor Green
    }

    # Test the tasks
    Write-Host "`nTesting task configuration..." -ForegroundColor Yellow
    $morningTask = Get-ScheduledTask -TaskName $morningTaskName
    $eveningTask = Get-ScheduledTask -TaskName $eveningTaskName
    
    if ($morningTask.State -eq "Ready" -and $eveningTask.State -eq "Ready") {
        Write-Host "✅ Tasks are ready and properly configured" -ForegroundColor Green
    } else {
        Write-Warning "⚠️  Tasks may not be properly configured. Check Task Scheduler."
    }

    # Provide management instructions
    Write-Host "`n📋 Task Management:" -ForegroundColor Cyan
    Write-Host "   View tasks: Get-ScheduledTask -TaskName '$TaskName*'" -ForegroundColor Gray
    Write-Host "   Remove tasks: Unregister-ScheduledTask -TaskName '$TaskName*' -Confirm:`$false" -ForegroundColor Gray
    Write-Host "   Test manually: Start-ScheduledTask -TaskName '$morningTaskName'" -ForegroundColor Gray

}
catch {
    Write-Error "❌ Failed to create scheduled tasks: $($_.Exception.Message)"
    Write-Host "Make sure you're running as Administrator and try again." -ForegroundColor Red
    exit 1
}