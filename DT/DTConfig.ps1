$script:_config_base_path = $null
$script:_config_folder = $null
$script:_config_file = $null

function Initialize-DTConfig {
    [CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFolder,
        [string]$ConfigFile
    )

    $script:_config_base_path = $ConfigBasePath
    $script:_config_folder = $ConfigFolder
    $script:_config_file = $ConfigFile

    Initialize-DTCConfig -ConfigBasePath $ConfigBasePath -ConfigFolder "DT" -ConfigFile $ConfigFile
}

function Get-DTConfigValue {

    [CmdletBinding()]
    param (
        [string]$ConfigGroup,
        [string]$ConfigName
    )

    $_dtc_config = Get-Content "$script:_config_base_path\$script:_config_folder\$script:_config_file" | ConvertFrom-Json

    Switch ("$ConfigGroup/$ConfigName")
    {
        "common/dtlogdir" { if ([string]::IsNullOrEmpty($_dtc_config.common.dtlogdir)) { $_dtc_ret="" } else { $_dtc_ret=$_dtc_config.common.dtlogdir } }
        "common/dtlogfile" { if ([string]::IsNullOrEmpty($_dtc_config.common.dtlogfile)) { $_dtc_ret="default.log" } else { $_dtc_ret=$_dtc_config.common.dtlogfile } }
        "common/dtlogtarget" { 
            if ([string]::IsNullOrEmpty($_dtc_config.common.dtlogtarget)) { 
                $_dtc_ret="File" 
            } else {
                $_dtc_ret=$_dtc_config.common.dtlogtarget 
            } 
        }
        "common/dttheme" { if ([string]::IsNullOrEmpty($_dtc_config.common.dttheme)) { $_dtc_ret="Auto" } else { $_dtc_ret=$_dtc_config.common.dttheme } }
        "common/dtserveractive" { $_dtc_ret = [System.Convert]::ToBoolean($_dtc_config.common.dtserveractive) }
        "common/dtlogrefresh" { $_dtc_ret = [System.Convert]::ToBoolean($_dtc_config.common.dtlogrefresh) }
        
        default { $_dtc_ret = Get-DTCConfigValue -ConfigBasePath $script:_config_base_path -ConfigFolder $script:_config_folder -ConfigFile $script:_config_file -ConfigGroup $ConfigGroup -ConfigName $ConfigName }
    }
    return $_dtc_ret;
}