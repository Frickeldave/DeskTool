function Write-DTSLog {

    [CmdletBinding()]
    param (
        [string]$Message,
        [switch]$RefreshLogFile,
        [string]$Component,
        [string]$Type,
        [string]$LogSource
    )

    New-Item -Path "$PSScriptRoot\data" -ItemType Directory -Force | Out-Null

    if($LogSource -eq "main") {
        Write-DTCLog -Message $Message -RefreshLogFile:$RefreshLogFile -Component $Component -Type $Type -LogFileDir "$PSScriptRoot\log" -LogFileName "DTS.log" -LogTarget "File"
    } else {
        Write-PodeLog -Name "log" -InputObject @{Message=$Message; Component=$Component; Type=$Type; LogFileDir="$PSScriptRoot\data"; LogFileName="DTS.log"; LogTarget="File"}
    }

}
