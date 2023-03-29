function Start-DT {

	# Import the logging functions
	. $PSScriptRoot\DTCLog.ps1
	
	# DT specific helper
	. $PSScriptRoot\DTHelper.ps1
	
	# DTC CommonHelper
	. $PSScriptRoot\DTCHelper.ps1

	# DT specific config
	. $PSScriptRoot\DTConfig.ps1

	# DT common config
	. $PSScriptRoot\DTCConfig.ps1

	# DT Pages
	. $PSScriptRoot\DTPages.ps1

	# Set all static variables
	$_dt_pode_version = "2.8.0"
	$_dt_podeweb_version = "0.8.3"
	$_dt_cefsharp_redis_version = "110.0.30"
	$_dt_cefsharp_common_version = "110.0.300"
	$_dt_cefsharp_wpf_version = "110.0.300"
	$_dt_base_path_app="$env:LOCALAPPDATA\Frickeldave"
	$_dt_base_path_user="$env:APPDATA\Frickeldave"
	$_dt_app_name="DeskTool"
	$_dt_config_file ="DTConfig.json"

	# Initialize the configuration
	Initialize-DTConfig -ConfigBasePath $_dt_base_path_user -ConfigFolder "DT" -ConfigFile $_dt_config_file

	# Set global log variables. These are used by "DTCLog\Write-DTCLog" therfore we do not have to add them to every call of "Write-DTCLog".
	# It is fine that there marked as not used in VSCode. There wil lbe used in the DTCLogs\Write-DTCLog function what is not detected by VSCode.
	[string]$global:_dt_log_file_dir = $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogdir")
	if([string]::IsNullOrEmpty($global:_dt_log_file_dir)) { $global:_dt_log_file_dir = "$_dt_base_path_app\DT" }
	
	[string]$global:_dt_log_file_name = $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogfile")
	if([string]::IsNullOrEmpty($global:_dt_log_file_name)) { $global:_dt_log_file_name = "$_dt_app_name.log" }
	
	[string]$global:_dt_log_target = $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogtarget")
	if([string]::IsNullOrEmpty($global:_dt_log_target)) { $global:_dt_log_target = "Console" }
	
	# Refresh logfile
	if((Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogrefresh") -eq $true) {
		Write-DTCLog "Logfile refreshed" -Component "Module" -RefreshLogFile
	}

	$_dt_podeweb_port = $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlocalport")

	# Remove oh-my-posh when it is loaded, otherwise Pode will raise several errors
	Remove-DTCOhMyPosh

	# Import all needed pode modules
	Import-DTCModule -ModuleName "pode" -ModuleVersion $_dt_pode_version
	Import-DTCModule -ModuleName "pode.web" -ModuleVersion $_dt_podeweb_version

	# Download CefSharp
	Get-DTCefSharp -ConfigBasePath $_dt_base_path_app -ConfigFolder "DT" -RedistVersion "$_dt_cefsharp_redis_version" -CommonVersion "$_dt_cefsharp_common_version" -WpfVersion "$_dt_cefsharp_wpf_version"

	try {
		Start-PodeServer {
			Write-DTCLog "Start webservice on port $_dt_podeweb_port" -Component "Module"
			Add-PodeEndpoint -Address localhost -Port $_dt_podeweb_port -Protocol Http -Name $_dt_app_name

			Write-DTCLog "Start webservice on port $_dt_podeweb_port for images" -Component "Module"
			Add-PodeStaticRoute -Path "/img" -Source "$_dt_base_path_app\DT\img"

			Add-Type -Path "$_dt_base_path_app\DT\lib\CefSharp\CefSharp.dll"
			Add-Type -Path "$_dt_base_path_app\DT\lib\CefSharp\CefSharp.Wpf.dll"

			Write-DTCLog "Start UI for application $_dt_app_name" -Component "Module"
			Show-PodeGui -Title "$_dt_app_name" -WindowState Normal -WindowStyle SingleBorderWindow -Icon $_dt_base_path_app\DT\img\DTLogo_Black.ico
			$_dt_theme = $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dttheme")
			Use-PodeWebTemplates -Title "$_dt_app_name" -Logo http://localhost:$_dt_podeweb_port/img/DTLogo_White.ico -Theme $_dt_theme

			Get-DTPageHome -Title "$_dt_app_name"
			Get-DTPageConfig -Title "$_dt_app_name"
			Get-DTPagePoker -Title "$_dt_app_name"
		}
	}
	catch {
		Write-DTCLog -Message "Failed to start Pode server. Details: $_" -Component "Module"
	}
}