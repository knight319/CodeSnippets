[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Folder,
    [Parameter(Mandatory=$true)]
    [string]$StartDate,
    [Parameter(Mandatory=$true)]
    [string]$EndDate,
    [Parameter(Mandatory=$true)]
    [string]$OutputFolder,
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:userprofile\Merge-Videos.log"
)

Function Write-Log($str) {
    $logstr = ("[" + (Get-Date).ToString('O') + "] $str")
    Write-Host $logstr
    $logstr >> $LogPath
}

function Get-SubFoldersByPrefix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Folder,
        [Parameter(Mandatory=$true)]
        [string]$Prefix
    )
    
    # Get all sub-folders in the specified folder
    $subFolders = Get-ChildItem -Path $Folder -Directory
    
    # Filter sub-folders that have the specified prefix
    $filteredFolders = $subFolders | Where-Object { $_.Name.StartsWith($Prefix) }
    
    # Return the filtered sub-folders' paths
    return $filteredFolders.FullName
}


function Merge-VideosInFolders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Folders,
        [Parameter(Mandatory=$false)]
        [string]$OutputFileName = ""
    )
    
    $InputFiles = @()
    foreach ($Folder in $Folders) {
        if (-not (Test-Path $Folder -PathType Container)) {
            Write-Error "Invalid folder specified: $Folder"
            return
        }
        # Get all MP4 files in folder
        $InputFiles += Get-ChildItem -Path $Folder -Filter "*.mp4" | Sort-Object -Property FullName
    }

    if ($OutputFileName -eq "") { $OutputFileName = "MergedVideo_" + (Get-Date).ToString('yyyyMMdd_HHmmss') + ".mkv"; }
    
    Merge-VideosByFileNames $InputFiles.FullName $OutputFileName
}

function Merge-VideosByFileNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$InputFiles,
        [Parameter(Mandatory=$false)]
        [string]$OutputFileName = ""
    )

    # Get all MP4 files in folder
    if ($InputFiles.Count -eq 0) {
        Write-Error "No files found in folder: $Folder"
        return
    }

    if ($OutputFileName -eq "") { $OutputFileName = "MergedVideo_" + (Get-DateTimeFileName) + ".mkv"; }
        
    # Generate input file list for FFmpeg
    $tmpFilePath = Join-Path $pwd ("MergedVideo_Filelist_" + (Get-DateTimeFileName) + ".txt")
    echo "" > $tmpFilePath;foreach ($i in $InputFiles) {echo "file '$i'" >> $tmpFilePath}; Set-Content -Path $tmpFilePath -Encoding Default -Value (Get-Content -Path $tmpFilePath)
    ffmpeg -f concat -safe 0 -i $tmpFilePath -c copy $OutputFileName
    rm $tmpFilePath
}

function Get-DateTimeFileName {
    return (Get-Date).ToString('yyyyMMdd_HHmmss_fff');
}

function Merge-AllVideos {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Folder,
        [Parameter(Mandatory=$false)]
        [string]$OutputFolder = ".",
        [Parameter(Mandatory=$false)]
        [bool]$DeleteAfterMerge = $false
    )

    $Directories = Get-ChildItem $Folder -Directory | Select-Object -ExpandProperty FullName
    $Directories | % { Merge-Videos $_ $Folder; rm -r $_ }
}

# main logic start
$format = "yyyy-MM-dd"
$sDate = [DateTime]::ParseExact($StartDate, $format, $null)
$eDate = [DateTime]::ParseExact($EndDate, $format, $null)
while ($sDate -le $eDate) {
    $prefix = $sDate.ToString("yyyyMMdd")
    Write-Log ("Get-SubFoldersByPrefix start. Prefix:" + $prefix + " Folder:" + $Folder)
    $folders = Get-SubFoldersByPrefix -Folder $Folder -Prefix $prefix
    Write-Log ("Get-SubFoldersByPrefix finish. " + ($folders.Count) + " folders found.")

    Write-Log "Merge-VideosInFolders start"

    $NewOutputFolder = Join-Path $OutputFolder ($sDate.ToString("yyyy-MM"))
    $outputFileName = Join-Path $NewOutputFolder ($prefix + "_CreateTime_" + (Get-DateTimeFileName) + ".mkv")

    if (-not (Test-Path $NewOutputFolder -PathType Container)) {
        Write-Log "Creating folder $NewOutputFolder"
        New-Item -ItemType Directory -Path $NewOutputFolder | Out-Null
    }

    Merge-VideosInFolders -Folders $folders -OutputFileName $outputFileName
    Write-Log "Merge-VideosInFolders finish"
    $sDate = $sDate.AddDays(1)
    $folders | ForEach-Object {Remove-Item -r $_}
}