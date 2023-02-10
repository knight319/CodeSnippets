## this need the sync.exe tool in SysinternalsSuite:https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite

Function CopyOrMoveBasedOnDate($src, $dest, $move=$false){
    # op1: use robocopy to copy, it is faster but cannot move file to it's related folder based on CreatedDate, like 2023-02
    # copy and move
    #robocopy $src $dest /S /xo /MT:5
    #robocopy $src $dest /S /xo /MT:4 /MOVE

    # op2: Get-ChildItem and Move-Item. Move items to CreatedDate related folder, like 2023-02
    $cnt = 0;
    $items = Get-ChildItem $src -Recurse -File
    $items | % {
        $dir = Join-Path $dest $_.CreationTime.ToString("yyyy-MM");
        If (!(Test-Path $dir)){ mkdir $dir };
        $destfilepath = Join-Path $dir $_.Name;
        If ($move) { Move-Item $_.FullName $destfilepath -Force; }
        ELSE { Copy-Item $_.FullName $destfilepath -Force; }
        $cnt += 1;
        Write-Progress -Activity "Copy to $dest" -Status "Percent complete" -PercentComplete $cnt / $items.Count * 100
    }
    
    # Delete empty folders in source.
    If ($move) { robocopy $src $src /s /move; }
    Write-Host "Done $cnt files."
}

Function DetectDcimFolderInUseDisk(){
    $src = ""
    $disk = Get-WmiObject Win32_Volume | Where-Object { $_.DriveType -eq 2 }
    if ($disk.GetType().Name -eq 'ManagementObject') {
        $tmp_p = Join-Path $disk.DriveLetter "DCIM"
        if (Test-Path $tmp_p) { $src = $tmp_p }
    } elseif (!$disk) {
        Write-Error "No USB disk found. Exiting"
        Pause
        return $src;
    } else {
        Write-Error "More than 1 USB disk found. Exiting"
        Pause
        return $src;
    }
    return $src
}

$src = DetectDcimFolderInUseDisk

$dest = "$env:userprofile\Pictures\Back2Nas\FujiXS10\"
$destDate = Join-Path $dest (Get-Date).ToString("yyyy-MM")
If (!(Test-Path $destDate)){ Start $dest }
ELSE { Start $destDate; }
CopyOrMoveBasedOnDate $src $dest $false

$dest = "Y:\Photos\PhotoLibrary\FujiXS10\"
CopyOrMoveBasedOnDate $src $dest $true
#Start (Join-Path $dest (Get-Date).ToString("yyyy-MM"))

sync -r -e $src[0]

Pause