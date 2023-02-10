Function OverrideWithLargerFile ($path, $comparePath) {
  $start = Get-Date

  # Create an empty dictionary
  $files = @{}
  
  # Get a list of all files in the specified path
  $fileList = Get-ChildItem $path -File -Recurse

  # Loop through each file in the list
  foreach ($file in $fileList) {
    # Add the file name as a key and the full path as the value to the dictionary
    If (!$files.ContainsKey($file.Name)) { $files.Add($file.Name, $file.FullName) }
  }

  # Create an empty dictionary for the files in the comparison folder
  $compareFiles = @{}

  # Get a list of all files in the comparison folder
  $compareFileList = Get-ChildItem $comparePath -File -Recurse

  # Loop through each file in the list
  foreach ($compareFile in $compareFileList) {
    # Add the file name as a key and the full path as the value to the dictionary
    If (!$compareFiles.ContainsKey($compareFile.Name)) { $compareFiles.Add($compareFile.Name, $compareFile.FullName) }
  }

  $cnt = 0
  $cpd = 0
  # Loop through each file in the original dictionary
  foreach ($key in $files.Keys) {
    # Check if there is a file with the same name in the comparison folder
    if ($compareFiles.ContainsKey($key)) {
      # If there is a match, copy the file from the original folder to the comparison folder
      
      If ((Get-Item $compareFiles[$key]).Length -gt (Get-Item $files[$key]).Length) {
          Copy-Item $compareFiles[$key] -Destination $files[$key] -Force;
          $cpd += 1;
          Write-Host "Copy " + $cpd + "th file;"
          Write-Host $cnt + "/" + $compareFiles.Keys.Count + ": Copy-Item" + $compareFiles[$key] + " -Destination" +   $files[$key] + " -Force"
      }
      
      $cnt += 1;
    }
  }

  $end = Get-Date
  $elapsed = $end - $start
  Write-Host "Elapsed time: $elapsed"
}
