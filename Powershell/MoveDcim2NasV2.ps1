## this need the sync.exe tool in SysinternalsSuite:https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite

param (
  # [Parameter(Mandatory=$true, ParameterSetName="Set1")]
  [string]$DriveLetter = "",
  [string]$LogPath = "$env:userprofile\MoveDcim2NasV2.log"
)

Function Write-Log($str) {
    $logstr = ("[" + (Get-Date).ToString('O') + "] $str")
    Write-Host $logstr
    $logstr >> $LogPath
}

function Convert-ByteSize {
  param(
    [double]$Bytes
  )
  $Units = @("B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB")
  $Unit = 0
  while ($Bytes -ge 1KB) {
    $Bytes /= 1KB
    $Unit++
  }
  [string]::Format("{0:0.##} {1}", $Bytes, $Units[$Unit])
}

function CopyItemWithSpeed([string]$source, [string]$destination, [bool]$move = $false) {
  if ($move -and ($source.ToLower()[0] -eq $destination.ToLower()[0])) { Move-Item $source $destination }

  try {
      $fileSize = (Get-Item $source).Length
      $bytesCopied = 0

      $copy = [System.IO.File]::OpenRead($source)
      $dest = [System.IO.File]::Create($destination)

      $buffer = New-Object byte[] 134217728 # 4M = 4194304, 16M = 16777216, 32M = 33554432， 64M = 67108864， 128M = 134217728
      $fileSizeHumanReadable = Convert-ByteSize $fileSize
      while ($bytesCopied -lt $fileSize)
      {
          $read = $copy.Read($buffer, 0, $buffer.Length)
          if ($read -eq 0) { break }
          $dest.Write($buffer, 0, $read)

          $bytesCopied += $read
          $bytesCopiedHumanReadable = Convert-ByteSize $bytesCopied
          $percentComplete = [int](($bytesCopied / $fileSize) * 100)
          Write-Progress -Id 99999 -Activity "Copying $source to $destination" -PercentComplete $percentComplete -Status "$bytesCopiedHumanReadable of $fileSizeHumanReadable bytes copied"
      }
      Write-Progress -Id 99999 -Activity "Copying $source to $destination" -PercentComplete 100 -Completed
      if ($move) { Remove-Item $source -Force }
  }
  finally {
      $copy.Close()
      $dest.Close()
  }
}

Function CopyOrMoveBasedOnDate($src, $dest, $move=$false){
    $StartDate = Get-Date
    # op1: use robocopy to copy, it is faster but cannot move file to it's related folder based on CreatedDate, like 2023-02
    # copy and move
    #robocopy $src $dest /S /xo /MT:5
    #robocopy $src $dest /S /xo /MT:4 /MOVE

    # op2: Get-ChildItem and Move-Item. Move items to CreatedDate related folder, like 2023-02
    $cnt = 0;
    $items = Get-ChildItem $src -Recurse -File
    Write-Log ("Total " + $items.Count + " files.")
    $items | ForEach-Object {
        $dir = Join-Path $dest $_.CreationTime.ToString("yyyy-MM");
        If (!(Test-Path $dir)){ mkdir $dir };
        $destfilepath = Join-Path $dir $_.Name;
        
        $cnt += 1;
        $pct = ($cnt/($items.Count))*100
        Write-Progress -Id 1001 -Activity "Copy to $dest" -Status "Processing $cnt files. Percent complete" -PercentComplete $pct
        If ($move) { 
            # for move, use move-item
            Move-Item $_.FullName $destfilepath -Force;
            # CopyItemWithSpeed $_.FullName $destfilepath $true
        }
        ELSE {
            # Copy-Item $_.FullName $destfilepath -Force; 
            CopyItemWithSpeed $_.FullName $destfilepath $false
        }
    }

    $EndDate = Get-Date
    
    # Delete empty folders in source.
    If ($move) { robocopy $src $src /s /move /nfl /ndl /njs }
    Write-Log ("Done " + $cnt + " files. Exec Time: " + ($EndDate - $StartDate).ToString())
}

# use robocopy to move item to a dest first and use move to adjust the folder.
Function CopyOrMoveBasedOnDateV2($src, $dest, $move=$false){
    $StartDate = Get-Date
    # step 1: use robocopy to copy, it is faster but cannot move file to it's related folder based on CreatedDate, like 2023-02
    # copy or move
    $dest_tmp = Join-Path $dest ("CopyOrMoveBasedOnDateV2_TMP_" + (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss"))
    If ($move) { 
        robocopy $src $dest_tmp /S /xo /MT:8 /MOVE /nfl /ndl
    }
    ELSE {
        robocopy $src $dest_tmp /S /xo /MT:8 /nfl /ndl
    }
    
    $src = $dest_tmp

    # step 2: Get-ChildItem and Move-Item. Move items to CreatedDate related folder, like 2023-02
    $cnt = 0;
    $items = Get-ChildItem $src -Recurse -File
    Write-Log ("Step2: Move to date folder. Total " + $items.Count + " files.")
    $items | ForEach-Object {
        $dir = Join-Path $dest $_.CreationTime.ToString("yyyy-MM");
        If (!(Test-Path $dir)){ mkdir $dir };
        $destfilepath = Join-Path $dir $_.Name;
        
        $cnt += 1;
        $pct = ($cnt/($items.Count))*100
        Write-Progress -Id 1001 -Activity "Move to $dest" -Status "Processing $cnt files. Percent complete" -PercentComplete $pct
        Move-Item $_.FullName $destfilepath -Force;
    }

    $EndDate = Get-Date
    
    # Delete empty folders in source.
    robocopy $src $src /s /move /nfl /ndl /njs
    Write-Log ("Done " + $cnt + " files. Exec Time: " + ($EndDate - $StartDate).ToString())
}

Function DetectDcimFolderInUseDisk($DriveLetter){
    if ($DriveLetter) {
        $tmp_p = Join-Path $disk.DriveLetter "DCIM"
        if (Test-Path $tmp_p) { return $tmp_p }
    }

    $src = ""
    $disk = Get-WmiObject Win32_Volume | Where-Object { $_.DriveType -eq 2 }
    if ($disk.GetType().Name -eq 'ManagementObject') {
        $tmp_p = Join-Path $disk.DriveLetter "DCIM"
        if (Test-Path $tmp_p) { $src = $tmp_p }
    } elseif (!$disk) {
        Write-Log "No USB disk found. Exiting"
        Pause
        return $src;
    } else {
        Write-Log "More than 1 USB disk found. Exiting"
        Pause
        return $src;
    }
    return $src
}

$src = DetectDcimFolderInUseDisk $DriveLetter

# below is custmized logic for myself. 
if ($src) {
    # Copy files to a tmp folder
    $srcTmp = Join-Path "D:\KC" ("MoveDcim2NasV2_TMP_" + (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss"))
    CopyOrMoveBasedOnDateV2 $src $srcTmp $true
    sync -r -e $src[0]
    # Start-Process $srcTmp
    $src = $srcTmp

    # Copy file from tmp folder to dest1 and dest2
    $dest = "$env:userprofile\Pictures\Back2Nas\FujiXS10\"
    $destDate = Join-Path $dest (Get-Date).ToString("yyyy-MM")
    If (!(Test-Path $destDate)){ Start-Process $dest }
    ELSE { Start-Process $destDate; }
    CopyOrMoveBasedOnDateV2 $src $dest $false

    $dest = "Y:\Photos\PhotoLibrary\FujiXS10\"
    CopyOrMoveBasedOnDateV2 $src $dest $true
    # Start (Join-Path $dest (Get-Date).ToString("yyyy-MM"))
} else {
    Write-Log "No usb drive with DCIM folder, please insert one."
}

Pause