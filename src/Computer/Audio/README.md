# Teams Audio Control Automation

This directory contains PowerShell scripts for automated control of system audio and Microsoft Teams microphone based on configurable business hours.

## 🎯 Purpose

The primary purpose is to automatically mute Teams notifications and system audio during non-business hours to prevent disruptions from:
- Teams meeting notifications
- Message alerts  
- System sounds
- Background audio

## 📁 Files

| File                | Purpose                                        |
| ------------------- | ---------------------------------------------- |
| `MuteAudio.ps1`     | Main script for audio and Teams control        |
| `ScheduledTask.ps1` | Creates Windows scheduled tasks for automation |
| `config.json`       | Configuration file for settings                |
| `README.md`         | This documentation file                        |

## 🚀 Quick Start

### Basic Usage (System Audio Only)

```powershell
# Automatic mode - mutes based on business hours
.\MuteAudio.ps1

# Force mute regardless of time
.\MuteAudio.ps1 -Force -Action Mute

# Check current status
.\MuteAudio.ps1 -Action Status
```

### Teams Integration

```powershell
# Include Teams microphone control
.\MuteAudio.ps1 -IncludeTeams

# Custom business hours with Teams
.\MuteAudio.ps1 -StartBusinessHour 9 -EndBusinessHour 18 -IncludeTeams

# Force mute both system and Teams
.\MuteAudio.ps1 -Force -Action Mute -IncludeTeams
```

### Scheduled Automation

```powershell
# Set up automatic daily tasks (run as Administrator)
.\ScheduledTask.ps1 -IncludeTeams

# Custom schedule
.\ScheduledTask.ps1 -StartBusinessHour 9 -EndBusinessHour 18 -IncludeTeams
```

## ⚙️ Configuration

### Script Parameters

#### MuteAudio.ps1 Parameters

| Parameter           | Type   | Default                      | Description                        |
| ------------------- | ------ | ---------------------------- | ---------------------------------- |
| `StartBusinessHour` | int    | 8                            | Business hours start (0-23)        |
| `EndBusinessHour`   | int    | 17                           | Business hours end (0-23)          |
| `Force`             | switch | false                        | Force action regardless of time    |
| `Action`            | string | "Auto"                       | Action: Auto, Mute, Unmute, Status |
| `IncludeTeams`      | switch | false                        | Include Teams microphone control   |
| `LogPath`           | string | %TEMP%\TeamsAudioControl.log | Log file location                  |

#### ScheduledTask.ps1 Parameters

| Parameter           | Type   | Default                 | Description                 |
| ------------------- | ------ | ----------------------- | --------------------------- |
| `StartBusinessHour` | int    | 8                       | Business hours start        |
| `EndBusinessHour`   | int    | 17                      | Business hours end          |
| `IncludeTeams`      | switch | false                   | Include Teams in automation |
| `TaskName`          | string | "TeamsAudioControlTask" | Scheduled task name         |
| `ScriptPath`        | string | auto-detected           | Path to MuteAudio.ps1       |

### Configuration File

Edit `config.json` to customize default settings:

```json
{
  "audioControl": {
    "businessHours": {
      "start": 8,
      "end": 17
    },
    "teamsIntegration": {
      "enabled": true,
      "processNames": ["ms-teams", "Teams"]
    },
    "logging": {
      "enabled": true,
      "level": "Info",
      "retentionDays": 7
    }
  }
}
```

## 🔧 How It Works

### System Audio Control

The script uses Windows API calls to control system volume:
- **Mute**: Sends `WM_APPCOMMAND` with `APPCOMMAND_VOLUME_MUTE`
- **Unmute**: Sends `WM_APPCOMMAND` with `APPCOMMAND_VOLUME_UNMUTE`
- **Broadcast**: Commands sent to all windows via `HWND_BROADCAST`

### Teams Integration

Teams microphone control works by:
1. **Process Detection**: Finds running Teams processes
2. **Window Activation**: Brings Teams window to foreground
3. **Keyboard Shortcut**: Sends `Ctrl+Shift+M` (Teams mute toggle)
4. **Error Handling**: Graceful fallback if Teams not available

### Business Hours Logic

```
Current Hour < Start Hour  → Mute (Non-business hours)
Current Hour >= End Hour   → Mute (Non-business hours)  
Start Hour <= Current < End → Unmute (Business hours)
```

## 📋 Prerequisites

### System Requirements
- **OS**: Windows 10/11
- **PowerShell**: 5.1 or later (7.x recommended)
- **Privileges**: Standard user (Administrator for scheduled tasks)
- **Audio**: Windows-compatible audio hardware

### For Teams Integration
- **Microsoft Teams**: New Teams or Classic Teams
- **Teams Running**: Application must be running for microphone control
- **Permissions**: Access to send keystrokes to Teams

### PowerShell Modules
```powershell
# Optional but recommended for enhanced functionality
Install-Module -Name PSScriptAnalyzer  # Code quality
Install-Module -Name Pester           # Testing
```

## 🛠️ Installation

### Step 1: Download Scripts
```powershell
# Clone the repository
git clone https://github.com/emarquez/MarquezHouse.git
cd MarquezHouse/src/Computer/Audio
```

### Step 2: Set Execution Policy (if needed)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 3: Test the Script
```powershell
# Test without making changes
.\MuteAudio.ps1 -Action Status

# Test mute functionality
.\MuteAudio.ps1 -Force -Action Mute -IncludeTeams
```

### Step 4: Set Up Automation (Optional)
```powershell
# Run as Administrator for scheduled task creation
.\ScheduledTask.ps1 -IncludeTeams
```

## 📊 Usage Examples

### Example 1: Standard Office Hours
```powershell
# Default 8 AM - 5 PM schedule
.\MuteAudio.ps1 -IncludeTeams
```

### Example 2: Flexible Hours
```powershell
# 9 AM - 6 PM schedule  
.\MuteAudio.ps1 -StartBusinessHour 9 -EndBusinessHour 18 -IncludeTeams
```

### Example 3: Manual Control
```powershell
# Immediately mute everything
.\MuteAudio.ps1 -Force -Action Mute -IncludeTeams

# Immediately unmute everything
.\MuteAudio.ps1 -Force -Action Unmute -IncludeTeams
```

### Example 4: Status Monitoring
```powershell
# Check current system status
$status = .\MuteAudio.ps1 -Action Status -IncludeTeams
Write-Host "Teams Running: $($status.TeamsRunning)"
Write-Host "Business Hours: $($status.BusinessHours)"
```

### Example 5: Custom Scheduled Tasks
```powershell
# Create tasks for 7 AM - 7 PM with Teams
.\ScheduledTask.ps1 -StartBusinessHour 7 -EndBusinessHour 19 -IncludeTeams

# Verify tasks were created
Get-ScheduledTask -TaskName "TeamsAudioControlTask*"
```

## 🐛 Troubleshooting

### Common Issues

#### Teams Not Responding
**Problem**: Teams microphone doesn't mute
**Solutions**:
1. Ensure Teams is running and has focus capability
2. Check Teams keyboard shortcuts are enabled
3. Verify the process name detection:
   ```powershell
   Get-Process -Name "*teams*" | Select-Object Name, MainWindowTitle
   ```

#### System Audio Not Muting
**Problem**: System volume doesn't change
**Solutions**:
1. Check audio drivers are working:
   ```powershell
   Get-WmiObject -Class Win32_SoundDevice
   ```
2. Test with admin privileges
3. Verify audio services are running:
   ```powershell
   Get-Service -Name "AudioSrv","AudioEndpointBuilder"
   ```

#### Scheduled Tasks Not Running
**Problem**: Automation doesn't work
**Solutions**:
1. Verify tasks exist:
   ```powershell
   Get-ScheduledTask -TaskName "TeamsAudioControlTask*"
   ```
2. Check task history in Task Scheduler
3. Ensure script path is correct
4. Run task manually to test:
   ```powershell
   Start-ScheduledTask -TaskName "TeamsAudioControlTask-Morning"
   ```

#### Permission Issues
**Problem**: "Access Denied" errors
**Solutions**:
1. Run PowerShell as Administrator for scheduled tasks
2. Check execution policy:
   ```powershell
   Get-ExecutionPolicy -List
   ```
3. Set appropriate policy:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Debug Mode

Enable detailed logging:
```powershell
# Run with verbose output
.\MuteAudio.ps1 -IncludeTeams -Verbose

# Check log file
Get-Content "$env:TEMP\TeamsAudioControl.log" -Tail 20
```

### Testing Teams Integration

```powershell
# Test if Teams is detected
if (Get-Process -Name "*teams*" -ErrorAction SilentlyContinue) {
    Write-Host "✅ Teams is running"
} else {
    Write-Host "❌ Teams not detected"
}

# Test keyboard shortcut manually
# 1. Focus Teams window
# 2. Press Ctrl+Shift+M
# 3. Verify microphone mutes/unmutes
```

## 📝 Logging

### Log Locations
- **Default**: `%TEMP%\TeamsAudioControl.log`
- **Custom**: Specify with `-LogPath` parameter

### Log Levels
- **Info**: Normal operations
- **Warning**: Non-critical issues  
- **Error**: Critical problems
- **Debug**: Detailed troubleshooting info

### Sample Log Output
```
[2025-06-27 14:30:00] [Info] Starting TeamsAudioControl v2.0
[2025-06-27 14:30:00] [Info] Current time: 06/27/2025 14:30:00 (Hour: 14)
[2025-06-27 14:30:00] [Info] Business hours: 8:00 - 17:00
[2025-06-27 14:30:00] [Debug] Currently in business hours: True
[2025-06-27 14:30:01] [Info] Action determined: Auto unmute (business hours)
[2025-06-27 14:30:01] [Info] Found Teams processes: 2
[2025-06-27 14:30:01] [Info] Unmuting system audio...
[2025-06-27 14:30:01] [Info] Unmuting Teams microphone...
[2025-06-27 14:30:02] [Info] System audio control: Success
[2025-06-27 14:30:02] [Info] Teams audio control: Success
[2025-06-27 14:30:02] [Info] Operation completed successfully
```

## 🔒 Security Considerations

### Script Execution
- Scripts are signed and follow PowerShell best practices
- Execution policy should be `RemoteSigned` or more restrictive
- No elevation required for basic audio control

### Teams Integration
- Uses standard Teams keyboard shortcuts (no API access)
- Briefly activates Teams window (visible for <1 second)
- No access to Teams data or conversations

### Scheduled Tasks
- Run with user credentials (not SYSTEM)
- Limited to audio control functions
- Can be easily removed or disabled

### Network Security
- No network communication required
- No external dependencies
- All operations are local to the machine

## 🤝 Contributing

### Reporting Issues
1. Check the [troubleshooting section](#-troubleshooting)
2. Enable debug logging and include relevant log entries
3. Specify your environment (OS, PowerShell version, Teams version)
4. Provide steps to reproduce the issue

### Feature Requests
- Additional Teams integration features
- Support for other communication apps
- Enhanced scheduling options
- Configuration management improvements

### Code Contributions
See the main [Contributing Guide](../../../CONTRIBUTING.md) for:
- PowerShell coding standards
- Testing requirements
- Pull request process
- Documentation guidelines

## 📚 Additional Resources

### Microsoft Documentation
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [Windows API Reference](https://docs.microsoft.com/windows/win32/api/)
- [Teams Keyboard Shortcuts](https://support.microsoft.com/office/keyboard-shortcuts-for-microsoft-teams-2e8e2a70-e8d8-4a19-949b-4c36dd5292d2)

### Related Projects
- [Teams PowerShell Module](https://docs.microsoft.com/microsoftteams/teams-powershell-overview)
- [Windows Audio Control](https://github.com/AndrewSav/WinAudioControl)
- [SysInternals Tools](https://docs.microsoft.com/sysinternals/)

---

**Need help?** Check the [main project documentation](../../../README.md) or [create an issue](https://github.com/emarquez/MarquezHouse/issues).
