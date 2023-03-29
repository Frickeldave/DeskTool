function Initialize-DTCConfig {
    [CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFolder,
        [string]$ConfigFile
    )

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\$ConfigFile)) {
        Copy-Item -Path $PSScriptRoot\$ConfigFile -Destination $ConfigBasePath\$ConfigFolder\$ConfigFile | Out-Null
    }
}

# function Get-DTCConfig {

#     $_dt_jsonFile = Get-Content $global:_dt_base_path_user\$global:_dt_app_name\DTConfig.json
#     $_dt_jsonObject = $_dt_jsonFile | ConvertFrom-Json

#     return $_dt_jsonObject
# }

function Get-DTCConfigValue {

    [CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFolder,
        [string]$ConfigFile,
        [string]$ConfigGroup,
        [string]$ConfigName
    )

    $_dtc_config = Get-Content "$ConfigBasePath\$ConfigFolder\$ConfigFile" | ConvertFrom-Json

    #$_dtc_config = Get-DTCConfig -DTCConfigBasePath $ConfigBasePath -DTCConfigFolder $ConfigFolder

    # Switch ("$ConfigGroup/$ConfigName")
    # {
    #     "common/dtlogdir" { if ([string]::IsNullOrEmpty($_dtc_config.dtlogdir)) { $_dtc_ret="$ConfigBasePath\$ConfigFolder" } else { $_dtc_ret=$_dtc_config.dtlogdir } }
    #     "common/dtlogtarget" { if ([string]::IsNullOrEmpty($_dtc_config.dtlogtarget)) { $_dtc_ret="File" } else { $_dtc_ret=$_dtc_config.dtlogtarget } }
    #     "common/dtlogfile" { if ([string]::IsNullOrEmpty($_dtc_config.dtlogfile)) { $_dtc_ret="default.log" } else { $_dtc_ret=$_dtc_config.dtlogfile } }
    #     default { $_dtc_ret = $_dtc_config.$ConfigGroup.$ConfigName }
    # }
    # return $_dtc_ret;
    return $_dtc_config.$ConfigGroup.$ConfigName
}