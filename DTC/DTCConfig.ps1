function Initialize-DTCConfig {
    [CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFile
    )

    if (-Not (Test-Path $ConfigBasePath)) {
        New-Item -Path $ConfigBasePath -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFile)) {
        Copy-Item -Path $PSScriptRoot\$ConfigFile -Destination $ConfigBasePath\$ConfigFile | Out-Null
    }
}


function Get-DTCConfigValue {

    [CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFile,
        [string]$ConfigGroup,
        [string]$ConfigName
    )

    $_dtc_config = Get-Content "$ConfigBasePath\$ConfigFile" | ConvertFrom-Json

    return $_dtc_config.$ConfigGroup.$ConfigName
}