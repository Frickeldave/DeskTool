function Start-DTS {

	# Import the logging functions
	. $PSScriptRoot\DTCLog.ps1
	
	# DTC CommonHelper
	. $PSScriptRoot\DTCHelper.ps1

	# DT specific config
	. $PSScriptRoot\DTSConfig.ps1

	# DT common config
	. $PSScriptRoot\DTCConfig.ps1

	# DTS endoints
	. $PSScriptRoot\DTSEndpoints.ps1

	# Set all static variables
	$_dts_pode_version = "2.8.0"
	$_dts_base_path_app = "$env:ProgramData\Frickeldave"
	$_dts_base_path_user = "$env:ProgramData\Frickeldave"
	$_dts_config_file = "DTSConfig.json"
	$_dts_app_name = "Desktool server"

	# Initialize the configuration
	Initialize-DTSConfig -ConfigBasePath $_dts_base_path_user -ConfigFolder "DTS" -ConfigFile $_dts_config_file

	# Initialize the logging which prevents to send logfile infos with every "Write-DTCLog" command
	Initialize-DTCLog -LogBasePath $_dts_base_path_app -LogFolder "DTS" -LogFileDir $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogdir") -LogFileName $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogfile") -LogTarget $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogtarget")

	# Refresh logfile
	if((Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogrefresh") -eq $true) {
		Write-DTCLog "Logfile refreshed" -Component "Module" -RefreshLogFile
	}

	# Get the webservice port from config file
	$_dts_podeweb_port = $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtsserverport")

	# Show some useful information in log output
	if($(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogtarget") -eq "File") {
		Write-DTCLog -Message "Logoutput is set to ""File""" -Component "Module"
		Write-DTCLog -Message "Logfile: $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogdir")\$(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogfile")" -Component "Module"
	} else {
		Write-DTCLog -Message "Logoutput is set to ""Console""" -Component "Module"
	}
	Write-DTCLog -Message "Serverport is: $_dts_podeweb_port" -Component "Module"

	# Remove oh-my-posh when it is loaded, otherwise Pode will raise several errors
	Remove-DTCOhMyPosh

	# Import all needed pode modules
	Import-DTCModule -ModuleName "pode" -ModuleVersion $_dts_pode_version

	try {
		Start-PodeServer {
			Write-DTCLog "Start webservice on port $_dts_podeweb_port" -Component "Module"
			Add-PodeEndpoint -Address "localhost" -Port $_dts_podeweb_port -Protocol Http -Name $_dts_app_name

			New-PodeLoggingMethod -Custom -ScriptBlock {
				param ( $item )
				
				#Initalize logging module with same parameters again, otherwise it's not available within the web session
				. $PSScriptRoot\DTCLog.ps1
				Initialize-DTCLog -LogBasePath $_dts_base_path_app -LogFolder "DTS" -LogFileDir $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogdir") -LogFileName $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogfile") -LogTarget $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogtarget")
				
				Write-DTCLog -Message $($item.Message) -Component $($item.Component) -Type $($item.Type)
			} | Add-PodeLogger -Name "log" -ScriptBlock {
				param ($item)
				return $item
			}

			Write-DTCLog "Initialize endpoints" -Component "Module"
			Initialize-DTSEndpoints -ConfigBasePath $_dts_base_path_user -ConfigFolder "DTS" -EndpointFolder "Endpoints"
			
			Get-DTSEndpointStatus
			Get-DTSEndpointPokerTableList
			Get-DTSEndpointPokerCreateTable
			Get-DTSEndpointPokerGetTable
		}
	}
	catch {
		Write-DTCLog -Message "Failed to start Pode server. Details: $_" -Component "Module"
	}
}