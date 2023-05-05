function Get-DTSConfigValue {

    [CmdletBinding()]
    param (
        [string]$ConfigGroup,
        [string]$ConfigName
    )

    $_dts_config = Get-Content "$PSScriptRoot\DTSConfig.json" | ConvertFrom-Json

    Switch ("$ConfigGroup/$ConfigName")
    {
        "common/dtslogdir" { if ([string]::IsNullOrEmpty($_dts_config.common.dtslogdir)) { $_dtc_ret="" } else { $_dtc_ret=$_dts_config.common.dtslogdir } }
        "common/dtslogfile" { if ([string]::IsNullOrEmpty($_dts_config.common.dtslogfile)) { $_dtc_ret="default.log" } else { $_dtc_ret=$_dts_config.common.dtslogfile } }

        "common/dtslogtarget" {
            if ([string]::IsNullOrEmpty($_dts_config.common.dtslogtarget)) {
                $_dtc_ret="File"
            } else {
                $_dtc_ret=$_dts_config.common.dtslogtarget
            }
        }

        default { $_dtc_ret = Get-DTCConfigValue -ConfigPath $PSScriptRoot -ConfigFile "DTSConfig.json" -ConfigGroup $ConfigGroup -ConfigName $ConfigName }
    }
    return $_dtc_ret;
}