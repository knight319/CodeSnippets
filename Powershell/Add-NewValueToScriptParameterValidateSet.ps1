
# $FilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

function Add-NewValueToScriptParameterValidateSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$ParameterName,
        [Parameter(Mandatory = $true)]
        [string]$NewValidValue
    )

    # Read the contents of the script into an array of lines
    $scriptContent = Get-Content $ScriptPath

    # Loop through the lines to find the line containing the parameter with the specified name
    $foundParameter = $false
    for ($i = 0; $i -lt $scriptContent.Length - 1; $i++) {
        $line = $scriptContent[$i].Trim()
        if ($line.StartsWith("[Parameter(") -and $scriptContent[$i + 2].Contains("`$${ParameterName}")) {
            $foundParameter = $true

            # Find the line containing the ValidateSet attribute
            $validateSetLineIndex = $i + 1
            while ($validateSetLineIndex -lt $scriptContent.Length -and $scriptContent[$validateSetLineIndex].Trim().StartsWith("[ValidateSet(") -eq $false) {
                $validateSetLineIndex++
            }

            if ($validateSetLineIndex -lt $scriptContent.Length -and $scriptContent[$validateSetLineIndex].Trim().StartsWith("[ValidateSet(")) {
                # Modify the line containing the ValidateSet attribute to add the new valid value
                $validateSetLine = $scriptContent[$validateSetLineIndex]
                $validValuesString = $validateSetLine.Substring($validateSetLine.IndexOf("(") + 1, $validateSetLine.IndexOf(")") - $validateSetLine.IndexOf("(") - 1).Trim()
                $validValues = $validValuesString.Split(",").ForEach({ $_.Trim(" ").Trim("`"").Trim("'"); })
                # Check if the new valid value is already in the ValidateSet attribute
                if ($validValues -contains $NewValidValue) {
                    Write-Host "The new value $NewValidValue is already in the ValidateSet attribute for parameter $ParameterName in script $ScriptPath."
                    return
                }

                $newValidateSetValue = $validateSetLine.Replace(")]", ", '$NewValidValue')]")
                $scriptContent[$validateSetLineIndex] = $newValidateSetValue
                # Write the modified array back to the script
                Set-Content $ScriptPath -Value $scriptContent

                # Exit the loop once we've found and modified the line
                break
            }
        }
    }

    if (-not $foundParameter) {
        throw "Could not find parameter $ParameterName in script $ScriptPath"
    }
}
