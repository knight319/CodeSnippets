param(
    [string]$source,
    [string]$destination,
    [bool]$move = $false
  )

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
      if ($move) { Remove-Item $source }
  }
  finally {
      $copy.Close()
      $dest.Close()
  }
}

CopyItemWithSpeed $source $destination $move