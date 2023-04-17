$script:_config_base_path = $null
$script:_config_folder = $null
$script:_config_file = $null

function Initialize-DTSConfig {
    [CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFolder,
        [string]$ConfigFile
    )

    $script:_config_base_path = $ConfigBasePath
    $script:_config_folder = $ConfigFolder
    $script:_config_file = $ConfigFile

    Initialize-DTCConfig -ConfigBasePath $ConfigBasePath -ConfigFolder "DTS" -ConfigFile $ConfigFile
}

function Get-DTSConfigValue {

    [CmdletBinding()]
    param (
        [string]$ConfigGroup,
        [string]$ConfigName
    )

    $_dts_config = Get-Content "$script:_config_base_path\$script:_config_folder\$script:_config_file" | ConvertFrom-Json

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
        default { $_dtc_ret = Get-DTCConfigValue -ConfigBasePath $script:_config_base_path -ConfigFolder $script:_config_folder -ConfigFile $script:_config_file -ConfigGroup $ConfigGroup -ConfigName $ConfigName }
    }
    return $_dtc_ret;
}