# This Powershell function extracts text and span pairs from an HTML file. 
# Specifically, the function reads in a file specified by the 'FilePath' parameter. 
# Then, it parses the HTML file by searching for '<span class="text-format-content "', 
#   which marks the start of each pair, and then extracts the text found between the starting tag and '</span>', the end tag. 
# The extracted data is returned in a 'ContentPairs' array of key-value pairs, which can then be exported as a CSV file.

function Extract-TextPairsFromHtmlFile {
    param (
        [string]$FilePath
    )

    # Read the HTML file into a string
    $html = Get-Content $FilePath -Raw  -Encoding UTF8

    $contentPairs = @()
    $pos = 0
    while ($pos -lt $html.Length) {
        $start = $html.IndexOf('<span class="text-format-content "', $pos)
        if ($start -lt 0) {
            break
        }
        $end = $html.IndexOf('</span>', $start)
        if ($end -lt 0) {
            break
        }
        $pos = $end + 1
        $innerStart = $html.IndexOf('<b>', $start, $end - $start)
        if ($innerStart -lt 0) {
            continue
        }
        $innerEnd = $html.IndexOf('</b>', $innerStart, $end - $innerStart)
        if ($innerEnd -lt 0) {
            continue
        }
        $keyStart = $html.LastIndexOf('class="text-format-content "', $innerStart)
        if ($keyStart -lt 0) {
            continue
        }
        $keyEnd = $html.IndexOf('>', $keyStart + 1)
        if ($keyEnd -lt 0) {
            continue
        }
        $key = $html.Substring($keyEnd + 1, $innerStart - $keyEnd - 1).Trim()
        $value = $html.Substring($innerStart + 3, $innerEnd - $innerStart - 3).Trim()
        if ($key -and $value) {
            $contentPairs += @{ Key = $key; Value = $value }
        }
    }
    return $contentPairs
}

$results | Select-Object @{Name='Key';Expression={$_.Key}}, @{Name='Value';Expression={$_.Value}} | Export-Csv -Path "1.csv" -NoTypeInformation -Encoding UTF8