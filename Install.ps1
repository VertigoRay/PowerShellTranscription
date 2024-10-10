function Assert-LogDirPermissions([IO.DirectoryInfo] $LogDir, [System.Security.AccessControl.FileSystemAccessRule[]] $DesiredACLs) {
    if (-not $LogDir.Exists) {
        return $false
    }

    # Get the current ACL
    $acl = Get-Acl -Path $LogDir.FullName

    # Serialize the ACL objects for easy comparing
    $currentACL = $acl.Access | Where-Object { $_.IdentityReference } | ConvertTo-Json | ConvertFrom-Json
    Write-Verbose ('[Assert-LogDirPermissions] Current ACL: {0}' -f ($currentACL | ConvertTo-Json))
    $desiredACL = $permission.DesiredACLs | ConvertTo-Json | ConvertFrom-Json
    Write-Verbose ('[Assert-LogDirPermissions] Desired ACL: {0}' -f ($desiredACL | ConvertTo-Json))

    # Check each desired rule
    if (-not (Compare-Object $currentACL $desiredACL)) {
        # No discrepencies found
        return $true
    } else {
        return $false
    }

}

function Enable-PowerShellTranscription([IO.DirectoryInfo] $LogDir) {
    # [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription]
    # "EnableTranscripting"=dword:00000001
    # "EnableInvocationHeader"=dword:00000001
    # "OutputDirectory"="C:\\Windows\\Logs\\PowerShell"
    $regPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription'
    $regs = @(
        @{
            Path = $regPath
            Name = 'EnableTranscripting'
            Type = 'DWord'
            Value = 1
        }
        @{
            Path = $regPath
            Name = 'EnableInvocationHeader'
            Type = 'DWord'
            Value = 1
        }
        @{
            Path = $regPath
            Name = 'OutputDirectory'
            Type = 'String'
            Value = $LogDir.FullName
        }
    )
    foreach ($reg in $regs) {
        Set-ItemProperty @reg -Force
    }
}

function Enable-PowerShellCoreTranscription([IO.DirectoryInfo] $LogDir) {
    # [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PowerShellCore\Transcription]
    # "EnableTranscripting"=dword:00000001
    # "EnableInvocationHeader"=dword:00000001
    # "OutputDirectory"="C:\\Windows\\Logs\\PowerShell"
    $regPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\PowerShellCore\Transcription'
    $regs = @(
        @{
            Path = $regPath
            Name = 'EnableTranscripting'
            Type = 'DWord'
            Value = 1
        }
        @{
            Path = $regPath
            Name = 'EnableInvocationHeader'
            Type = 'DWord'
            Value = 1
        }
        @{
            Path = $regPath
            Name = 'OutputDirectory'
            Type = 'String'
            Value = $LogDir.FullName
        }
    )
    foreach ($reg in $regs) {
        Set-ItemProperty @reg -Force
    }
}

function Remove-OldFiles([IO.DirectoryInfo] $LogDir, [int] $Age) {
    $cutoffDate = (Get-Date).AddDays(-$Age)

    # Get all files in the folder and subfolders
    $files = Get-ChildItem -Path $LogDir.FullName -File -Recurse

    foreach ($file in $files) {
        if ($file.LastWriteTime -lt $cutoffDate) {
            Remove-Item -Path $file.FullName -Force
        }
    }
}

function Remove-EmptyFolders([IO.DirectoryInfo] $LogDir) {
    # Get all directories in the folder and subfolders
    $directories = Get-ChildItem -Path $LogDir.FullName -Directory -Recurse

    foreach ($directory in $directories) {
        if (-not (Get-ChildItem -Path $directory.FullName)) {
            Remove-Item -Path $directory.FullName -Force
        }
    }
}

function Set-LogDirPermissions([IO.DirectoryInfo] $LogDir, [System.Security.AccessControl.FileSystemAccessRule[]] $DesiredACLs) {
    # Create the folder if it doesn't exist
    if (-not $LogDir.Exists) {
        New-Item -ItemType 'Directory' -Path $LogDir.FullName -Force
    }

    # Define the ACLs
    $acl = Get-Acl $LogDir.FullName

    # Disable inheritance and remove inherited permissions
    $acl.SetAccessRuleProtection($true, $false)

    # Clear existing rules
    $acl.Access | ForEach-Object {
        $acl.RemoveAccessRule($_) | Out-Null
    }

    # Add the permissions to the ACL
    foreach ($desiredACL in $DesiredACLs) {
        $acl.SetAccessRule($desiredACL)
    }

    # Apply the ACL to the folder
    Set-Acl -Path $LogDir.FullName -AclObject $acl
}

# Define the permissions
$permission = @{
    LogDir = [IO.Path]::Combine($env:SystemRoot, 'Logs', 'PowerShell')
    DesiredACLs = @(
        # [System.Security.AccessControl.FileSystemAccessRule]::new(
        #     'BUILTIN\Administrators',
        #     'FullControl',
        #     'ContainerInherit, ObjectInherit',
        #     'None',
        #     'Allow'
        # )
        [System.Security.AccessControl.FileSystemAccessRule]::new(
            'Authenticated Users',
            'ReadAndExecute, Synchronize, Write',
            'ContainerInherit',
            'NoPropagateInherit',
            'Allow'
        )
        [System.Security.AccessControl.FileSystemAccessRule]::new(
            'CREATOR OWNER',
            'ReadAndExecute, Synchronize, Write',
            'ContainerInherit, ObjectInherit',
            'InheritOnly',
            'Allow'
        )
    )
}

Enable-PowerShellCoreTranscription -LogDir $permission.LogDir
Enable-PowerShellTranscription -LogDir $permission.LogDir

$asserted = Assert-LogDirPermissions @permission
Write-Verbose ('Asserting LogDir Perms: {0}' -f $asserted)
if (-not $asserted) {
    Write-Verbose ('Setting LogDir Perms: {0}' -f ($permission | ConvertTo-Json))
    Set-LogDirPermissions @permission
}

Remove-OldFiles -LogDir $permission.LogDir -Age 60
Remove-EmptyFolders -LogDir $permission.LogDir
