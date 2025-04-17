<#
.SYNOPSIS
    This script mutes or unmutes the system audio based on the current time.

.DESCRIPTION
    The script checks the current hour and determines whether it falls within business hours.
    If the current time is outside business hours, the system audio is muted.
    If the current time is within business hours, the system audio is unmuted.

.PARAMETERS
    None.

.NOTES
    Author: Eric Marquez
    Date: 2025-04-16
    This script uses the Windows API to send messages to control the system audio.

.LIMITATIONS
    - This script requires administrative privileges to execute.
    - The script uses hardcoded business hours (8:00 AM to 5:00 PM).
    - The script assumes the use of the Windows operating system.

.EXAMPLE
    Run the script to mute/unmute audio based on the current time:
    ./MuteAudio.ps1
#>

# Define business hours (customize these values as needed)
$StartBusinessHour = 8   # 8:00 AM
$EndBusinessHour = 17    # 5:00 PM

# Get the current hour
$CurrentHour = (Get-Date).Hour

# Function to define and add the AudioManager class for controlling audio
function Add-AudioManagerClass {
    Add-Type -TypeDefinition @"
    using System.Runtime.InteropServices;

    public class AudioManager {
        [DllImport("user32.dll")]
        public static extern int SendMessage(int hWnd, int Msg, int wParam, int lParam);
    }
"@
}

# Check if the current time is outside business hours
if ($CurrentHour -lt $StartBusinessHour -or $CurrentHour -ge $EndBusinessHour) {
    # Mute the audio
    Write-Host "Muting the audio output (non-business hours)"
    
    # Add the AudioManager class
    Add-AudioManagerClass

    # Send command to mute the volume
    # 0xFFFF: Broadcast to all windows
    # 0x319: WM_APPCOMMAND message
    # 0x80800000: APPCOMMAND_VOLUME_MUTE
    [AudioManager]::SendMessage(0xFFFF, 0x319, 0, 0x80800000)  
}
else {
    # Unmute the audio
    Write-Host "Audio output is active (business hours)"
    
    # Add the AudioManager class
    Add-AudioManagerClass

    # Send command to unmute the volume
    # 0xFFFF: Broadcast to all windows
    # 0x319: WM_APPCOMMAND message
    # 0x80000000: APPCOMMAND_VOLUME_UNMUTE
    [AudioManager]::SendMessage(0xFFFF, 0x319, 0, 0x80000000)
}