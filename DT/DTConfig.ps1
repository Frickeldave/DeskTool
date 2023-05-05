function Get-DTConfigValue {

    [CmdletBinding()]
    param (
        [string]$ConfigGroup,
        [string]$ConfigName
    )

    $_dtc_config = Get-Content "$($env:APPDATA)\Frickeldave\DT\DTConfig.json" | ConvertFrom-Json

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
        
        default { $_dtc_ret = Get-DTCConfigValue -ConfigPath "$($env:APPDATA)\Frickeldave\DT" -ConfigFile "DTConfig.json" -ConfigGroup $ConfigGroup -ConfigName $ConfigName }
    }
    return $_dtc_ret;
}