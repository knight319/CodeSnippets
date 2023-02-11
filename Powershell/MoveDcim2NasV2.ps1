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

      $buffer = New-Object byte[] 1048576
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
      if ($move) { Remove-Item $source -Force }
  }
  finally {
      $copy.Close()
      $dest.Close()
  }
}

Function CopyOrMoveBasedOnDate($src, $dest, $move=$false){
    # op1: use robocopy to copy, it is faster but cannot move file to it's related folder based on CreatedDate, like 2023-02
    # copy and move
    #robocopy $src $dest /S /xo /MT:5
    #robocopy $src $dest /S /xo /MT:4 /MOVE

    # op2: Get-ChildItem and Move-Item. Move items to CreatedDate related folder, like 2023-02
    $cnt = 0;
    $items = Get-ChildItem $src -Recurse -File
    Write-Log ("Total " + $items.Count + " files.")
    $items | % {
        $dir = Join-Path $dest $_.CreationTime.ToString("yyyy-MM");
        If (!(Test-Path $dir)){ mkdir $dir };
        $destfilepath = Join-Path $dir $_.Name;
        
        $cnt += 1;
        $pct = ($cnt/($items.Count))*100
        Write-Progress -Id 1001 -Activity "Copy to $dest" -Status "Processing $cnt files. Percent complete" -PercentComplete $pct
        If ($move) { 
            # Move-Item $_.FullName $destfilepath -Force;
            CopyItemWithSpeed $_.FullName $destfilepath $true
        }
        ELSE {
            # Copy-Item $_.FullName $destfilepath -Force; 
            CopyItemWithSpeed $_.FullName $destfilepath $false
        }
    }
    
    # Delete empty folders in source.
    If ($move) { robocopy $src $src /s /move; }
    Write-Log ("Done " + $cnt + " files.")
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