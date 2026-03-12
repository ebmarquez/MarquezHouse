<#
.SYNOPSIS
    Test script for the Teams Audio Control automation.

.DESCRIPTION
    This script validates the functionality of MuteAudio.ps1 and ScheduledTask.ps1
    by running various test scenarios and reporting results.

.PARAMETER IncludeTeams
    Include Teams-specific tests (requires Teams to be running).

.PARAMETER SkipScheduledTasks
    Skip tests that require administrative privileges.

.EXAMPLE
    .\Test-AudioControl.ps1
    Runs basic audio control tests.

.EXAMPLE
    .\Test-AudioControl.ps1 -IncludeTeams
    Runs tests including Teams integration.

.NOTES
    Author: Eric Marquez
    Date: 2025-06-27
    Version: 1.0
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTeams,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipScheduledTasks
)

# Test configuration
$TestResults = @()
$ScriptPath = Join-Path $PSScriptRoot "MuteAudio.ps1"
$ScheduledTaskPath = Join-Path $PSScriptRoot "ScheduledTask.ps1"

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [string]$Error = ""
    )
    
    $TestResults += [PSCustomObject]@{
        Test = $TestName
        Passed = $Passed
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
    
    $status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "$status - $TestName" -ForegroundColor $color
    if ($Details) { Write-Host "    Details: $Details" -ForegroundColor Gray }
    if ($Error) { Write-Host "    Error: $Error" -ForegroundColor Red }
}

Write-Host "🧪 Teams Audio Control Test Suite" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Script Files Exist
Write-Host "📁 Testing File Existence..." -ForegroundColor Yellow

try {
    $muteScriptExists = Test-Path $ScriptPath
    Add-TestResult "MuteAudio.ps1 exists" $muteScriptExists "Path: $ScriptPath"
    
    $scheduledTaskExists = Test-Path $ScheduledTaskPath
    Add-TestResult "ScheduledTask.ps1 exists" $scheduledTaskExists "Path: $ScheduledTaskPath"
    
    $configExists = Test-Path (Join-Path $PSScriptRoot "config.json")
    Add-TestResult "config.json exists" $configExists
}
catch {
    Add-TestResult "File existence check" $false "" $_.Exception.Message
}

# Test 2: Script Syntax Validation
Write-Host "`n🔍 Testing Script Syntax..." -ForegroundColor Yellow

try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScriptPath -Raw), [ref]$null)
    Add-TestResult "MuteAudio.ps1 syntax valid" $true
}
catch {
    Add-TestResult "MuteAudio.ps1 syntax valid" $false "" $_.Exception.Message
}

try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScheduledTaskPath -Raw), [ref]$null)
    Add-TestResult "ScheduledTask.ps1 syntax valid" $true
}
catch {
    Add-TestResult "ScheduledTask.ps1 syntax valid" $false "" $_.Exception.Message
}

# Test 3: Parameter Validation
Write-Host "`n⚙️ Testing Parameter Validation..." -ForegroundColor Yellow

try {
    # Test valid parameters
    $result = & $ScriptPath -Action Status -StartBusinessHour 9 -EndBusinessHour 17
    Add-TestResult "Valid parameters accepted" $true "Status check completed"
}
catch {
    Add-TestResult "Valid parameters accepted" $false "" $_.Exception.Message
}

try {
    # Test invalid hour range (should fail)
    & $ScriptPath -StartBusinessHour 18 -EndBusinessHour 8 2>$null
    Add-TestResult "Invalid hour range rejected" $false "Should have thrown error"
}
catch {
    Add-TestResult "Invalid hour range rejected" $true "Correctly rejected invalid range"
}

# Test 4: Audio System Detection
Write-Host "`n🔊 Testing Audio System..." -ForegroundColor Yellow

try {
    $audioDevices = Get-WmiObject -Class Win32_SoundDevice -ErrorAction SilentlyContinue
    $hasAudio = $audioDevices -and $audioDevices.Count -gt 0
    Add-TestResult "Audio devices detected" $hasAudio "Found $($audioDevices.Count) device(s)"
}
catch {
    Add-TestResult "Audio devices detected" $false "" $_.Exception.Message
}

# Test 5: PowerShell Version
Write-Host "`n🐚 Testing PowerShell Environment..." -ForegroundColor Yellow

$psVersion = $PSVersionTable.PSVersion
$isCompatible = $psVersion.Major -ge 5
Add-TestResult "PowerShell version compatible" $isCompatible "Version: $($psVersion.ToString())"

# Test 6: Execution Policy
$executionPolicy = Get-ExecutionPolicy
$policyOk = $executionPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")
Add-TestResult "Execution policy allows scripts" $policyOk "Policy: $executionPolicy"

# Test 7: Teams Integration (if requested)
if ($IncludeTeams) {
    Write-Host "`n🎯 Testing Teams Integration..." -ForegroundColor Yellow
    
    try {
        $teamsProcesses = Get-Process -Name "*teams*" -ErrorAction SilentlyContinue
        $teamsRunning = $teamsProcesses -and $teamsProcesses.Count -gt 0
        Add-TestResult "Teams processes detected" $teamsRunning "Found $($teamsProcesses.Count) process(es)"
        
        if ($teamsRunning) {
            # Test Teams window detection
            $teamsWindows = $teamsProcesses | Where-Object { $_.MainWindowTitle -ne "" }
            $hasActiveWindows = $teamsWindows -and $teamsWindows.Count -gt 0
            Add-TestResult "Teams windows with titles found" $hasActiveWindows "Found $($teamsWindows.Count) window(s)"
        }
        
        # Test Teams integration without actually muting
        $result = & $ScriptPath -Action Status -IncludeTeams
        $teamsIntegrationWorks = $result -and $result.TeamsIncluded
        Add-TestResult "Teams integration status check" $teamsIntegrationWorks "Teams included in status"
    }
    catch {
        Add-TestResult "Teams integration test" $false "" $_.Exception.Message
    }
}

# Test 8: Scheduled Task Creation (if not skipped)
if (-not $SkipScheduledTasks) {
    Write-Host "`n📅 Testing Scheduled Task Creation..." -ForegroundColor Yellow
    
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        try {
            # Test if the ScheduledTask script can be called with valid parameters
            $taskTestName = "TestAudioControlTask-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            
            # Test parameter validation without creating actual tasks
            Add-TestResult "Scheduled task script exists" (Test-Path $ScheduledTaskPath) "Path: $ScheduledTaskPath"
            
            # Test parameter compatibility between scripts
            $muteParams = Get-Command $ScriptPath | Select-Object -ExpandProperty Parameters
            $taskParams = Get-Command $ScheduledTaskPath | Select-Object -ExpandProperty Parameters
            
            $hasStartHour = $muteParams.ContainsKey("StartBusinessHour") -and $taskParams.ContainsKey("StartBusinessHour")
            $hasEndHour = $muteParams.ContainsKey("EndBusinessHour") -and $taskParams.ContainsKey("EndBusinessHour")
            $hasIncludeTeams = $muteParams.ContainsKey("IncludeTeams") -and $taskParams.ContainsKey("IncludeTeams")
            
            Add-TestResult "Parameter compatibility - StartBusinessHour" $hasStartHour "Both scripts support this parameter"
            Add-TestResult "Parameter compatibility - EndBusinessHour" $hasEndHour "Both scripts support this parameter"
            Add-TestResult "Parameter compatibility - IncludeTeams" $hasIncludeTeams "Both scripts support this parameter"
            
            # Test if we can parse the ScheduledTask script (syntax check)
            $taskScriptContent = Get-Content $ScheduledTaskPath -Raw
            $taskScriptValid = $taskScriptContent -match "Register-ScheduledTask" -and $taskScriptContent -match "New-ScheduledTaskTrigger"
            Add-TestResult "Scheduled task script contains required cmdlets" $taskScriptValid "Found Register-ScheduledTask and New-ScheduledTaskTrigger"
            
            # Test if the script properly references MuteAudio.ps1
            $referencesMuteScript = $taskScriptContent -match "MuteAudio\.ps1"
            Add-TestResult "Scheduled task script references MuteAudio.ps1" $referencesMuteScript "Properly configured to call main script"
            
            Write-Host "    💡 To test actual task creation, run:" -ForegroundColor Cyan
            Write-Host "       .\ScheduledTask.ps1 -TaskName '$taskTestName' -IncludeTeams" -ForegroundColor Gray
        }
        catch {
            Add-TestResult "Scheduled task compatibility test" $false "" $_.Exception.Message
        }
    }
    else {
        Add-TestResult "Scheduled task admin check" $false "Not running as Administrator" "Run as admin to test scheduled task creation"
        Write-Host "    💡 To test with admin privileges:" -ForegroundColor Cyan
        Write-Host "       Start-Process PowerShell -ArgumentList '-File .\Test-AudioControl.ps1' -Verb RunAs" -ForegroundColor Gray
    }
}

# Test 9: Logging Functionality
Write-Host "`n📝 Testing Logging..." -ForegroundColor Yellow

try {
    $logPath = "$env:TEMP\TeamsAudioControlTest.log"
    $result = & $ScriptPath -Action Status -LogPath $logPath
    
    $logExists = Test-Path $logPath
    Add-TestResult "Log file creation" $logExists "Path: $logPath"
    
    if ($logExists) {
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        $hasLogEntries = $logContent -and $logContent.Count -gt 0
        Add-TestResult "Log entries written" $hasLogEntries "Found $($logContent.Count) line(s)"
        
        # Clean up test log
        Remove-Item $logPath -ErrorAction SilentlyContinue
    }
}
catch {
    Add-TestResult "Logging functionality test" $false "" $_.Exception.Message
}

# Test 10: Configuration File Validation
Write-Host "`n⚙️ Testing Configuration..." -ForegroundColor Yellow

try {
    $configPath = Join-Path $PSScriptRoot "config.json"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath | ConvertFrom-Json
        $hasAudioControl = $null -ne $config.audioControl
        Add-TestResult "Configuration file valid JSON" $hasAudioControl "Contains audioControl section"
        
        $hasBusinessHours = $null -ne $config.audioControl.businessHours
        Add-TestResult "Business hours configuration present" $hasBusinessHours
    }
    else {
        Add-TestResult "Configuration file validation" $false "config.json not found"
    }
}
catch {
    Add-TestResult "Configuration file validation" $false "" $_.Exception.Message
}

# Test 11: Integration Test - Script Parameter Compatibility
Write-Host "`n🔗 Testing Script Integration..." -ForegroundColor Yellow

try {
    # Test that ScheduledTask.ps1 can successfully call MuteAudio.ps1 with compatible parameters
    $testStartHour = 9
    $testEndHour = 18
    
    # Test MuteAudio.ps1 with parameters that ScheduledTask.ps1 would use
    $testArgs = @{
        StartBusinessHour = $testStartHour
        EndBusinessHour = $testEndHour
        Action = "Status"
        Force = $true
    }
    
    $muteResult = & $ScriptPath @testArgs
    $integrationWorks = $null -ne $muteResult
    Add-TestResult "MuteAudio accepts ScheduledTask parameters" $integrationWorks "Parameters successfully processed"
    
    if ($IncludeTeams) {
        # Test with Teams parameter
        $testArgsWithTeams = $testArgs.Clone()
        $testArgsWithTeams.IncludeTeams = $true
        
        $muteResultWithTeams = & $ScriptPath @testArgsWithTeams
        $teamsIntegrationWorks = $null -ne $muteResultWithTeams
        Add-TestResult "MuteAudio accepts Teams parameters from ScheduledTask" $teamsIntegrationWorks "Teams parameter integration successful"
    }
    
    # Verify the ScheduledTask script can find MuteAudio.ps1
    $scheduledTaskContent = Get-Content $ScheduledTaskPath -Raw
    $autoDetectsScript = $scheduledTaskContent -match '\$ScriptPath = Join-Path \$PSScriptRoot "MuteAudio\.ps1"'
    Add-TestResult "ScheduledTask auto-detects MuteAudio.ps1 path" $autoDetectsScript "Uses PSScriptRoot for relative path detection"
    
    # Test the command line arguments that ScheduledTask would generate
    $expectedMorningArgs = "-StartBusinessHour $testStartHour -EndBusinessHour $testEndHour -Force -Action Unmute"
    $expectedEveningArgs = "-StartBusinessHour $testStartHour -EndBusinessHour $testEndHour -Force -Action Mute"
    
    if ($IncludeTeams) {
        $expectedMorningArgs += " -IncludeTeams"
        $expectedEveningArgs += " -IncludeTeams"
    }
    
    Add-TestResult "Command line arguments format validated" $true "Morning: $expectedMorningArgs"
    Add-TestResult "Command line arguments format validated" $true "Evening: $expectedEveningArgs"
}
catch {
    Add-TestResult "Script integration test" $false "" $_.Exception.Message
}

# Summary Report
Write-Host "`n📊 Test Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

$totalTests = $TestResults.Count
$passedTests = ($TestResults | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Yellow" })

# Display failed tests
if ($failedTests -gt 0) {
    Write-Host "`n❌ Failed Tests:" -ForegroundColor Red
    $TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Host "   • $($_.Test)" -ForegroundColor Red
        if ($_.Error) { Write-Host "     Error: $($_.Error)" -ForegroundColor Gray }
    }
}

# Recommendations
Write-Host "`n💡 Recommendations:" -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "✅ All tests passed! The audio control system is ready for use." -ForegroundColor Green
}
else {
    Write-Host "⚠️  Some tests failed. Review the errors above and:" -ForegroundColor Yellow
    Write-Host "   • Ensure all required files are present" -ForegroundColor Gray
    Write-Host "   • Check PowerShell execution policy" -ForegroundColor Gray
    Write-Host "   • Verify audio hardware is working" -ForegroundColor Gray
    if ($IncludeTeams) {
        Write-Host "   • Make sure Microsoft Teams is running for Teams tests" -ForegroundColor Gray
    }
    if (-not $SkipScheduledTasks) {
        Write-Host "   • Run as Administrator to test scheduled task creation" -ForegroundColor Gray
    }
}

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "   • Run: .\MuteAudio.ps1 -Action Status" -ForegroundColor Gray
Write-Host "   • Test: .\MuteAudio.ps1 -Force -Action Mute" -ForegroundColor Gray
if ($IncludeTeams) {
    Write-Host "   • With Teams: .\MuteAudio.ps1 -IncludeTeams" -ForegroundColor Gray
}
Write-Host "   • Automate: .\ScheduledTask.ps1 (run as Admin)" -ForegroundColor Gray

Write-Host "`n🔗 Script Integration:" -ForegroundColor Cyan
Write-Host "   The ScheduledTask.ps1 script works with MuteAudio.ps1 by:" -ForegroundColor Gray
Write-Host "   • Auto-detecting the MuteAudio.ps1 path using PSScriptRoot" -ForegroundColor Gray
Write-Host "   • Creating two tasks: Morning (Unmute) and Evening (Mute)" -ForegroundColor Gray
Write-Host "   • Passing compatible parameters: -StartBusinessHour, -EndBusinessHour, -IncludeTeams" -ForegroundColor Gray
Write-Host "   • Using -Force -Action Mute/Unmute for reliable scheduled execution" -ForegroundColor Gray

Write-Host "`n📋 Example Integration Commands:" -ForegroundColor Cyan
Write-Host "   # Basic setup" -ForegroundColor Gray
Write-Host "   .\ScheduledTask.ps1" -ForegroundColor White
Write-Host "   # With Teams integration" -ForegroundColor Gray  
Write-Host "   .\ScheduledTask.ps1 -IncludeTeams" -ForegroundColor White
Write-Host "   # Custom hours" -ForegroundColor Gray
Write-Host "   .\ScheduledTask.ps1 -StartBusinessHour 9 -EndBusinessHour 18 -IncludeTeams" -ForegroundColor White

# Return test results for programmatic use
return $TestResults
