[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ParameterSetName='Dates')]
    [Parameter(Mandatory=$true, ParameterSetName = 'Yesterday')]
    [string]$XiaoMiCameraRootFolder,
    [Parameter(Mandatory=$true, ParameterSetName = 'Dates')]
    [string]$StartDate,
    [Parameter(Mandatory=$true, ParameterSetName='Dates')]
    [string]$EndDate,
    [Parameter(Mandatory=$true, ParameterSetName='Yesterday')]
    [Parameter(Mandatory=$true, ParameterSetName='Dates')]
    [string]$OutputFolder,
    [Parameter(Mandatory=$false, ParameterSetName='Yesterday')]
    [Parameter(Mandatory=$false, ParameterSetName='Dates')]
    [string]$LogPath = "$env:userprofile\MergeXiaomiCameraVideos.log",
    [Parameter(Mandatory=$false, ParameterSetName='Yesterday')]
    [switch]$Yesterday
)

Function Write-Log($str) {
    $logstr = ("[" + (Get-Date).ToString('O') + "] $str")
    Write-Host $logstr
    $logstr >> $LogPath
}

# main logic start
# Get all camera folders in the root folder
$cameraFolders = Get-ChildItem -Path $XiaoMiCameraRootFolder -Directory

Write-Log ("Found " + $cameraFolders.Count + " camera folders.")

$cameraFolders | ForEach-Object {
    Write-Log ("Start processing " + $_.FullName)

    $cameraOutputFolder = Join-Path $OutputFolder $_.Name
    if ($Yesterday) {
        .\Merge-Videos.ps1 -Folder $_.FullName -OutputFolder $cameraOutputFolder -LogPath $LogPath -Yesterday
    } else {
        .\Merge-Videos.ps1 -Folder $_.FullName -OutputFolder $cameraOutputFolder -LogPath $LogPath -StartDate $StartDate -EndDate $EndDate
    }
    
    Write-Log ("Finish processing " + $_.FullName)
}
