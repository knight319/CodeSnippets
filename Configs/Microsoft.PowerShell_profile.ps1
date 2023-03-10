Write-Host " "

$PSDefaultParameterValues['Out-Default:OutVariable'] = 'last'

#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

function Get-DateTimeKqlQuery($minutes=60)
{
    $start = ((Get-Date).ToUniversalTime().AddMinutes(-$minutes)).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $end = ((Get-Date).ToUniversalTime().AddMinutes(0)).ToString("yyyy-MM-ddTHH:mm:ssZ")
    Write-Host "startTimeUtc: $start"
    Write-Host "endTimeUtc: $end"
    Write-Host "Saved to clipboard: Time >= datetime('$start') and Time <= datetime('$end')"
    Set-Clipboard "Time >= datetime('$start') and Time <= datetime('$end')"
}

function ph()
{
    Write-Host "Saved '$env:UserProfile\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline' to clipboard"
    Set-Clipboard "$env:UserProfile\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline"
    start "$env:UserProfile\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline"
    
}