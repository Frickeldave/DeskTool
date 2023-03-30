function Start-DTS {

	# Import the logging functions
	. $PSScriptRoot\DTCLog.ps1
	
	# DTC CommonHelper
	. $PSScriptRoot\DTCHelper.ps1

	# DT specific config
	. $PSScriptRoot\DTConfig.ps1

	# DT common config
	. $PSScriptRoot\DTCConfig.ps1

	# Set all static variables
	$_dts_pode_version = "2.8.0"
	$_dts_base_path_app = "$env:LOCALAPPDATA\Frickeldave"
	$_dts_base_path_user = "$env:APPDATA\Frickeldave"
	$_dts_config_file = "DTSConfig.json"
	$_dts_app_name = "Desktool server"

	# Initialize the configuration
	Initialize-DTSConfig -ConfigBasePath $_dts_base_path_user -ConfigFolder "DTS" -ConfigFile $_dts_config_file

	# Initialize the logging which prevents to send logfile infos with every "Write-DTLog" command
	Intialize-DTCLog -LogBasePath $_dts_base_path_app -LogFolder "DTS" -LogFileDir $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogdir") -LogFileName $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogfile") -LogFileTarget $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogtarget")
	# Set global log variables. These are used by "DTCLog\Write-DTCLog" therfore we do not have to add them to every call of "Write-DTCLog".
	# It is fine that there marked as not used in VSCode. There wil lbe used in the DTCLogs\Write-DTCLog function what is not detected by VSCode.
	# TODO: Change to script vars in DTCLog analog to the var handling in DT(S)Config
	[string]$global:_dts_log_file_dir = $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogdir")
	if([string]::IsNullOrEmpty($global:_dts_log_file_dir)) { $global:_dts_log_file_dir = "$_dts_base_path_app\DTS" }
	
	[string]$global:_dts_log_file_name = $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogfile")
	if([string]::IsNullOrEmpty($global:_dts_log_file_name)) { $global:_dts_log_file_name = "$_dts_app_name.log" }
	
	[string]$global:_dts_log_target = $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogtarget")
	if([string]::IsNullOrEmpty($global:_dts_log_target)) { $global:_dts_log_target = "Console" }
	
	# Refresh logfile
	if((Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogrefresh") -eq $true) {
		Write-DTCLog "Logfile refreshed" -Component "Module" -RefreshLogFile
	}

	$_dts_podeweb_port = $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslocalport")

	# Remove oh-my-posh when it is loaded, otherwise Pode will raise several errors
	Remove-DTCOhMyPosh

	# Import all needed pode modules
	Import-DTCModule -ModuleName "pode" -ModuleVersion $_dt_pode_version

	try {
		Start-PodeServer {
			Write-DTCLog "Start webservice on port $_dts_podeweb_port" -Component "Module"
			Add-PodeEndpoint -Address "0.0.0.0" -Port $_dts_podeweb_port -Protocol Http -Name $_dts_app_name

			New-PodeLoggingMethod -Custom -ScriptBlock {
				param ( $item )
	
				if($null -ne $($item.LogFileDir) -and $null -ne $($item.LogFileName)) {
					Write-DTCLog -Message $($item.Message) -Target "File" -Component "Sokovia" -LogFileDir "$($item.LogFileDir)" -LogFileName "$($item.LogFileName)" -Type "$($item.Type)"
				} else {
					Write-DTCLog -Message $($item.Message) -Target "Console" -Component "Sokovia" -Type $($item.Type)
				}
			} | Add-PodeLogger -Name "log" -ScriptBlock {
				param ($item)
				return $item
			}

		}
	}
	catch {
		Write-DTCLog -Message "Failed to start Pode server. Details: $_" -Component "Module"
	}
}