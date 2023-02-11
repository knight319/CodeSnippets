# Not work as expected, it only works when the powershell session is active.

# Unregister the existing WMI event
Unregister-Event -SourceIdentifier "Win32_LogicalDiskInsertEvent"

# Re-register the WMI event with the updated action
$Query = "select * from __InstanceCreationEvent within 5 where TargetInstance ISA 'Win32_LogicalDisk' and TargetInstance.DriveType = 2"

# Register the WMI event query
$WMI = Register-WMIEvent -Query $Query -SourceIdentifier "Win32_LogicalDiskInsertEvent" -Action {
  # Get the drive letter of the USB drive that was just inserted
  $DriveLetter = ($Event.SourceEventArgs.NewEvent.TargetInstance.Name)
  ("[" + (Get-Date).ToString('O') + "] USB drive with letter $DriveLetter was inserted") >> (Join-Path $env:USERPROFILE "Win32_LogicalDiskInsertEvent.txt")
}
