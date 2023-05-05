function Get-DTCConfigValue {

    [CmdletBinding()]
    param (
        [string]$ConfigPath,
        [string]$ConfigFile,
        [string]$ConfigGroup,
        [string]$ConfigName
    )

    $_dtc_config = Get-Content "$ConfigPath\$ConfigFile" | ConvertFrom-Json

    return $_dtc_config.$ConfigGroup.$ConfigName
}