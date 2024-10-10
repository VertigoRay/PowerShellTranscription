# PowerShell Transcription
Enable Auto PowerShell Transcription and Prevent User Modification

The `Install.ps1` script will:
1. Enable Auto Transcription for Windows PowerShell and PowerShell Core.
2. Create the log folder and set ACLs so that:
   - Users can create log files and view their own.
   - Users cannot delete any log files.
4. Purge Old Logs:
   - Remove Old Log Files (older than 60 days).
   - Remove Empty Folders.

# Cron

```powershell
# Define the task name and script path
$taskName = "RunFooScript"
$scriptPath = "C:\Path\To\Your\Script\foo.ps1"

# Define the action to run the PowerShell script
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Define the trigger to run daily at 12:05 AM
$trigger = New-ScheduledTaskTrigger -Daily -At "00:05AM"

# Define the principal (user) to run the task
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the scheduled task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal
```
