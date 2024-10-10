# Ensure 'Turn on PowerShell Transcription' is set to 'Enabled'

This Policy setting lets you capture the input and output of Windows PowerShell commands into text-based transcripts.
The recommended state for this setting is: Enabled.

## Rationale

PowerShell transcript input can be very valuable when performing forensic investigations of PowerShell attack incidents to determine what occurred.

## Impact

PowerShell transcript input will be logged to the PowerShell_transcript output file, which is saved to the My Documents folder of each users ' profile by default.

Warning: There are potential risks of capturing credentials and sensitive information in the PowerShell_transcript output file, which could be exposed to users who have read-access to the file.

## Solution

To establish the recommended configuration via GP, set the following UI path to Enabled:
- `Computer Configuration\Policies\Administrative Templates\Windows Components\Windows PowerShell\Turn on PowerShell Transcription`

Note: This Group Policy path may not exist by default. It is provided by the Group Policy template PowerShellExecutionPolicy.admx/adml that is included with the Microsoft Windows 10 RTM (Release 1507) Administrative Templates (or newer).

- Default Value: `Disabled`. (Transcription of PowerShell-based applications is disabled by default, although transcription can still be enabled through the Start-Transcript cmdlet.)
- Reference: `CIS 18.10.87.2`, `800-171|3.3.1`, `800-171|3.3.2`, `800-53|AU-2`, `800-53r5|AU-2`, `CN-L3|8.1.4.3(a)`, `CSCv7|8.8`, `CSCv8|8.8`, `CSF|PR.PT-1`, `GDPR|32.1.b`, `HIPAA|164.306(a)(1)`, `HIPAA|164.312(b)`, `ITSG-33|AU-2`, `LEVEL|1A`, `NESA|M1.2.2`, `NESA|M5.5.1`, `NIAv2|AM7`, `NIAv2|AM11a`, `NIAv2|AM11b`, `NIAv2|AM11c`, `NIAv2|AM11d`, `NIAv2|AM11e`, `NIAv2|SS30`, `NIAv2|VL8`, `QCSC-v1|8.2.1`, `QCSC-v1|13.2`, `SWIFT-CSCv1|6.4`
- Policy Value: `1`
- Actual Value: `NULL`

# What This Does

The `Install.ps1` script will:
1. Enable Auto Transcription for Windows PowerShell and PowerShell Core.
2. Create the log folder and set ACLs so that:
   - Users can create log files and view their own.
   - Users cannot delete any log files.
4. Purge Old Logs:
   - Remove Old Log Files (older than 60 days).
   - Remove Empty Folders.

# Cron

To set this up as a scheduled task, do something like this ...

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
