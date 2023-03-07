function Start-DeskTool {

	# Import the logging functions
	. $PSScriptRoot\DTLog.ps1
	# CommonHelper
	. $PSScriptRoot\DTHelper.ps1
	# Config
	. $PSScriptRoot\DTConfig.ps1
	# Pages
	. $PSScriptRoot\DTPages.ps1

	# Set all static variables
	$_dt_pode_version = "2.8.0"
	$_dt_podeweb_version = "0.8.3"
	$_dt_cefsharp_redis_version = "110.0.30"
	$_dt_cefsharp_common_version = "110.0.300"
	$_dt_cefsharp_wpf_version = "110.0.300"
	$global:_dt_base_path_app=$env:LOCALAPPDATA
	$global:_dt_base_path_user=$env:APPDATA
	$global:_dt_app_name="DeskTool"

	# Initialize the configuration
	Initialize-DTConfig
	$global:_dt_config = Get-DTConfig
	$_dt_podeweb_port = $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlocalport")


	# Refresh logfile
	if((Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogrefresh") -eq $true) {
		Write-DTLog "Logfile refreshed" -Component "Module" -RefreshLogFile
	}

	# Remove oh-my-posh when it is loaded, otherwise Pode will raise several errors
	Remove-OhMyPosh

	# Import all needed pode modules
	Import-DTModule -ModuleName "pode" -ModuleVersion $_dt_pode_version
	Import-DTModule -ModuleName "pode.web" -ModuleVersion $_dt_podeweb_version

	# Download CefSharp
	Get-CefSharp -RedistVersion "$_dt_cefsharp_redis_version" -CommonVersion "$_dt_cefsharp_common_version" -WpfVersion "$_dt_cefsharp_wpf_version"

	try {
		Start-PodeServer {
			Write-DTLog "Start webservice on port $_dt_podeweb_port" -Component "Module"
			Add-PodeEndpoint -Address localhost -Port $_dt_podeweb_port -Protocol Http -Name $global:_dt_app_name

			Write-DTLog "Start webservice on port $_dt_podeweb_port for images" -Component "Module"
			Add-PodeStaticRoute -Path "/img" -Source "$PSScriptRoot\img"

			Add-Type -Path "$env:LOCALAPPDATA\$global:_dt_app_name\lib\CefSharp\CefSharp.dll"
			Add-Type -Path "$env:LOCALAPPDATA\$global:_dt_app_name\lib\CefSharp\CefSharp.Wpf.dll"

			Write-DTLog "Start UI" -Component "$global:_dt_app_name"
			Show-PodeGui -Title "$global:_dt_app_name" -WindowState Normal -WindowStyle SingleBorderWindow -Icon $PSScriptRoot/img/DTLogo_Black.ico
			Use-PodeWebTemplates -Title "$global:_dt_app_name" -Logo http://localhost:$_dt_podeweb_port/img/DTLogo_White.ico -Theme "$(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dttheme")"

			Get-DTPageHome
			Get-DTPageConfig
			Get-DTPagePoker
		}
	}
	catch {
		Write-DTLog -Message "Failed to start Pode server. Details: $_" -Component "Module"
	}
}