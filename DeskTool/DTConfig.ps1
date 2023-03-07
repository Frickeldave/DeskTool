function Initialize-DTConfig {
    
    if (-Not (Test-Path $global:_dt_base_path_user\$global:_dt_app_name)) {
        Write-DTLog "Create initial configuration directory" -Component "Get-DTConfig"
        New-Item -Path $global:_dt_base_path_user\$global:_dt_app_name -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $global:_dt_base_path_user\$global:_dt_app_name\DTConfig.json)) {
        Write-DTLog "Create initial configuration file" -Component "Get-DTConfig"
        Copy-Item -Path $PSScriptRoot\DTConfig.json -Destination $global:_dt_base_path_user\$global:_dt_app_name\DTConfig.json | Out-Null
    }
}

function Get-DTConfig {

    $_dt_jsonFile = Get-Content $global:_dt_base_path_user\$global:_dt_app_name\DTConfig.json
    $_dt_jsonObject = $_dt_jsonFile | ConvertFrom-Json

    return $_dt_jsonObject
}

function Get-DTConfigValue {

    [CmdletBinding()]
    param (
        [string]$ConfigGroup,
        [string]$ConfigName
    )

    Switch ("$ConfigGroup/$ConfigName")
    {
        "common/dtlogdir" { if ([string]::IsNullOrEmpty($global:_dt_config.dtlogdir)) { $_dt_ret="$($global:_dt_base_path_app)\$($global:_dt_app_name)" } else { $_dt_ret=$global:_dt_config.dtlogdir } }
        "common/dtlogtarget" { if ([string]::IsNullOrEmpty($global:_dt_config.dtlogtarget)) { $_dt_ret="File" } else { $_dt_ret=$global:_dt_config.dtlogtarget } }
        "common/dtlogfile" { if ([string]::IsNullOrEmpty($global:_dt_config.dtlogfile)) { $_dt_ret="$($global:_dt_app_name).log" } else { $_dt_ret=$global:_dt_config.dtlogfile } }
        default { $_dt_ret = $global:_dt_config.$ConfigGroup.$ConfigName }
    }
    return $_dt_ret;
}