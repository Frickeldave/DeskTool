function Start-DeskTool {

	[CmdletBinding()]
	param (
		[Parameter()]
		[string]$Port=8082,
		[string]$BasePath=$env:LOCALAPPDATA

	)

	$_dt_pode_version = "2.8.0"
	$_dt_podeweb_version = "0.8.3"
	$_dt_cefsharp_redis_version = "110.0.30"
	$_dt_cefsharp_common_version = "110.0.300"
	$_dt_cefsharp_wpf_version = "110.0.300"
	$_dt_podeweb_port = $Port

	# Import the logging functions
	. $PSScriptRoot\DTLog.ps1
	# CommonHelper
	. $PSScriptRoot\DTHelper.ps1

	Remove-OhMyPosh
	Import-DTModule -ModuleName "pode" -ModuleVersion $_dt_pode_version
	Import-DTModule -ModuleName "pode.web" -ModuleVersion $_dt_podeweb_version

	Get-CefSharp -BasePath $BasePath -AppName $AppName -RedistVersion "$_dt_cefsharp_redis_version" -CommonVersion "$_dt_cefsharp_common_version" -WpfVersion "$_dt_cefsharp_wpf_version"

	try {
		Start-PodeServer {
			Write-DTLog "Start webservice on port $_dt_podeweb_port" -Component "DeskTool"
			Add-PodeEndpoint -Address localhost -Port $_dt_podeweb_port -Protocol Http -Name Frickeldave_DeskTool

			Add-Type -Path "$env:LOCALAPPDATA\$AppName\lib\CefSharp\CefSharp.dll"
			Add-Type -Path "$env:LOCALAPPDATA\$AppName\lib\CefSharp\CefSharp.Wpf.dll"

			Write-DTLog "Start UI" -Component "DeskTool"
			Show-PodeGui -Title "Frickeldaves DeskTool"
			Use-PodeWebTemplates -Title "Frickeldave" -Theme Dark
		}
	}
	catch {
		Write-DTLog -Message "Failed to start Pode server. Details: $_" -Component "DeskTool"
	}
}