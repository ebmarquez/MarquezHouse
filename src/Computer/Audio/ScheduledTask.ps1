# Define the script path using $env:UserProfile
$ScriptPath = "$env:UserProfile\OneDrive\Scripts\MuteAudio.ps1"

# Create a trigger for 8 AM on weekdays
$Trigger1 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 08:00

# Create a trigger for 5 PM on weekdays
$Trigger2 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 17:00

# Define the action to execute the PowerShell script
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -Noninteractive -File `"$ScriptPath`"" -WorkingDirectory "$env:UserProfile\OneDrive\Scripts"

# Register the scheduled task with both triggers
Register-ScheduledTask -TaskName "MuteAudioTask" -Trigger $Trigger1, $Trigger2 -Action $Action -Description "Mutes/Unmutes audio based on business hours (excludes weekends)" -User "$env:USERNAME" -RunLevel Highest