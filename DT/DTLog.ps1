function Write-DTLog {

    [CmdletBinding()]
    param (
        [string]$Message,
        [switch]$RefreshLogFile,
        [string]$Component,
        [string]$Type,
        [string]$LogSource
    )

    New-Item -Path "$($env:APPDATA)\Frickeldave\DT\log" -ItemType Directory -Force | Out-Null

    if($LogSource -eq "main") {
        Write-DTCLog -Message $Message -RefreshLogFile:$RefreshLogFile -Component $Component -Type $Type -LogFileDir "$($env:APPDATA)\Frickeldave\DT\log" -LogFileName "DT.log" -LogTarget "File"
    } else {
        Write-PodeLog -Name "log" -InputObject @{Message=$Message; Component=$Component; Type=$Type; LogFileDir="$($env:APPDATA)\Frickeldave\DT\log"; LogFileName="DT.log"; LogTarget="File"}
    }

}
