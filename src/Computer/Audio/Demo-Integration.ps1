<#
.SYNOPSIS
    Demonstrates the integration between MuteAudio.ps1 and ScheduledTask.ps1

.DESCRIPTION
    This script shows how the ScheduledTask.ps1 script calls MuteAudio.ps1 with
    the correct parameters and demonstrates the complete workflow.

.PARAMETER ShowCommands
    Display the exact commands that would be executed by the scheduled tasks.

.PARAMETER TestExecution
    Actually test the command execution (without creating scheduled tasks).

.EXAMPLE
    .\Demo-Integration.ps1 -ShowCommands
    Shows the commands that scheduled tasks would execute.

.EXAMPLE
    .\Demo-Integration.ps1 -TestExecution
    Tests the actual command execution.

.NOTES
    Author: Eric Marquez
    Date: 2025-06-27
    Version: 1.0
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$ShowCommands,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestExecution
)

$ScriptPath = Join-Path $PSScriptRoot "MuteAudio.ps1"
$ScheduledTaskPath = Join-Path $PSScriptRoot "ScheduledTask.ps1"

Write-Host "🔗 MuteAudio.ps1 and ScheduledTask.ps1 Integration Demo" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Check if files exist
if (-not (Test-Path $ScriptPath)) {
    Write-Error "MuteAudio.ps1 not found at $ScriptPath"
    exit 1
}

if (-not (Test-Path $ScheduledTaskPath)) {
    Write-Error "ScheduledTask.ps1 not found at $ScheduledTaskPath"
    exit 1
}

Write-Host "✅ Both scripts found and ready" -ForegroundColor Green
Write-Host "   MuteAudio.ps1: $ScriptPath" -ForegroundColor Gray
Write-Host "   ScheduledTask.ps1: $ScheduledTaskPath" -ForegroundColor Gray
Write-Host ""

# Example configurations
$configurations = @(
    @{
        Name = "Default Office Hours"
        StartHour = 8
        EndHour = 17
        IncludeTeams = $false
        Description = "Standard 8 AM - 5 PM schedule, system audio only"
    },
    @{
        Name = "Extended Hours with Teams"
        StartHour = 7
        EndHour = 19
        IncludeTeams = $true
        Description = "7 AM - 7 PM schedule with Teams integration"
    },
    @{
        Name = "Flexible Hours"
        StartHour = 9
        EndHour = 18
        IncludeTeams = $true
        Description = "9 AM - 6 PM schedule with Teams integration"
    }
)

if ($ShowCommands) {
    Write-Host "📋 Scheduled Task Commands" -ForegroundColor Yellow
    Write-Host "===========================" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($config in $configurations) {
        Write-Host "🔧 Configuration: $($config.Name)" -ForegroundColor Cyan
        Write-Host "   $($config.Description)" -ForegroundColor Gray
        Write-Host ""
        
        # Build arguments like ScheduledTask.ps1 does
        $businessHourArgs = "-StartBusinessHour $($config.StartHour) -EndBusinessHour $($config.EndHour)"
        $teamsArgs = if ($config.IncludeTeams) { "-IncludeTeams" } else { "" }
        
        $morningArgs = "$businessHourArgs $teamsArgs -Force -Action Unmute".Trim()
        $eveningArgs = "$businessHourArgs $teamsArgs -Force -Action Mute".Trim()
        
        Write-Host "   Morning Task (Unmute at $($config.StartHour):00):" -ForegroundColor Green
        Write-Host "   powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`" $morningArgs" -ForegroundColor White
        Write-Host ""
        
        Write-Host "   Evening Task (Mute at $($config.EndHour):00):" -ForegroundColor Red
        Write-Host "   powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`" $eveningArgs" -ForegroundColor White
        Write-Host ""
        
        Write-Host "   ScheduledTask.ps1 command to create these tasks:" -ForegroundColor Magenta
        $taskCommand = ".\ScheduledTask.ps1 -StartBusinessHour $($config.StartHour) -EndBusinessHour $($config.EndHour)"
        if ($config.IncludeTeams) {
            $taskCommand += " -IncludeTeams"
        }
        Write-Host "   $taskCommand" -ForegroundColor White
        Write-Host ""
        Write-Host "   " + ("-" * 80) -ForegroundColor Gray
        Write-Host ""
    }
}

if ($TestExecution) {
    Write-Host "🧪 Testing Command Execution" -ForegroundColor Yellow
    Write-Host "=============================" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($config in $configurations) {
        Write-Host "Testing configuration: $($config.Name)" -ForegroundColor Cyan
        
        try {
            # Test morning command (unmute)
            $morningParams = @{
                StartBusinessHour = $config.StartHour
                EndBusinessHour = $config.EndHour
                Force = $true
                Action = "Unmute"
            }
            
            if ($config.IncludeTeams) {
                $morningParams.IncludeTeams = $true
            }
            
            Write-Host "   Testing morning unmute command..." -ForegroundColor Green
            $morningResult = & $ScriptPath @morningParams
            if ($morningResult) {
                Write-Host "   ✅ Morning command successful" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Morning command completed (no result object)" -ForegroundColor Yellow
            }
            
            # Test evening command (mute)
            $eveningParams = @{
                StartBusinessHour = $config.StartHour
                EndBusinessHour = $config.EndHour
                Force = $true
                Action = "Mute"
            }
            
            if ($config.IncludeTeams) {
                $eveningParams.IncludeTeams = $true
            }
            
            Write-Host "   Testing evening mute command..." -ForegroundColor Red
            $eveningResult = & $ScriptPath @eveningParams
            if ($eveningResult) {
                Write-Host "   ✅ Evening command successful" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Evening command completed (no result object)" -ForegroundColor Yellow
            }
            
            # Test status command
            $statusParams = @{
                StartBusinessHour = $config.StartHour
                EndBusinessHour = $config.EndHour
                Action = "Status"
            }
            
            if ($config.IncludeTeams) {
                $statusParams.IncludeTeams = $true
            }
            
            Write-Host "   Testing status command..." -ForegroundColor Blue
            $statusResult = & $ScriptPath @statusParams
            if ($statusResult) {
                Write-Host "   ✅ Status command successful" -ForegroundColor Green
                Write-Host "      Business Hours: $($statusResult.BusinessHours)" -ForegroundColor Gray
                Write-Host "      Teams Included: $($statusResult.TeamsIncluded)" -ForegroundColor Gray
            } else {
                Write-Host "   ❌ Status command failed" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "   ❌ Error testing configuration: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host ""
    }
}

if (-not $ShowCommands -and -not $TestExecution) {
    Write-Host "📖 How Integration Works" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "1. ScheduledTask.ps1 Parameters:" -ForegroundColor Cyan
    Write-Host "   • StartBusinessHour (0-23)" -ForegroundColor Gray
    Write-Host "   • EndBusinessHour (0-23)" -ForegroundColor Gray  
    Write-Host "   • IncludeTeams (switch)" -ForegroundColor Gray
    Write-Host "   • TaskName (string)" -ForegroundColor Gray
    Write-Host "   • ScriptPath (auto-detected)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "2. ScheduledTask.ps1 creates two tasks:" -ForegroundColor Cyan
    Write-Host "   • Morning Task: Calls MuteAudio.ps1 with -Force -Action Unmute" -ForegroundColor Green
    Write-Host "   • Evening Task: Calls MuteAudio.ps1 with -Force -Action Mute" -ForegroundColor Red
    Write-Host ""
    
    Write-Host "3. MuteAudio.ps1 Parameters Passed:" -ForegroundColor Cyan
    Write-Host "   • StartBusinessHour & EndBusinessHour (passed through)" -ForegroundColor Gray
    Write-Host "   • Force (always true for scheduled tasks)" -ForegroundColor Gray
    Write-Host "   • Action (Mute or Unmute)" -ForegroundColor Gray
    Write-Host "   • IncludeTeams (if specified)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "4. Result:" -ForegroundColor Cyan
    Write-Host "   • Audio mutes automatically at end of business hours" -ForegroundColor Red
    Write-Host "   • Audio unmutes automatically at start of business hours" -ForegroundColor Green
    Write-Host "   • Teams microphone follows same schedule (if enabled)" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "💡 Try these commands:" -ForegroundColor Yellow
    Write-Host "   .\Demo-Integration.ps1 -ShowCommands     # See exact commands" -ForegroundColor White
    Write-Host "   .\Demo-Integration.ps1 -TestExecution    # Test the commands" -ForegroundColor White
    Write-Host "   .\Test-AudioControl.ps1 -IncludeTeams    # Run full test suite" -ForegroundColor White
    Write-Host ""
}

Write-Host "🎯 Next Steps:" -ForegroundColor Green
Write-Host "   1. Test manually: .\MuteAudio.ps1 -Action Status" -ForegroundColor Gray
Write-Host "   2. Test with Teams: .\MuteAudio.ps1 -IncludeTeams -Action Status" -ForegroundColor Gray
Write-Host "   3. Create tasks: .\ScheduledTask.ps1 -IncludeTeams (run as Admin)" -ForegroundColor Gray
Write-Host "   4. Verify tasks: Get-ScheduledTask -TaskName '*TeamsAudioControl*'" -ForegroundColor Gray
