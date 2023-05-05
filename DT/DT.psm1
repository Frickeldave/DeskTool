function Initialize-DT {

	# Set all static variables
	$_dt_pode_version = "2.8.0"
	$_dt_podeweb_version = "0.8.3"
	$_dt_cefsharp_redis_version = "110.0.30"
	$_dt_cefsharp_common_version = "110.0.300"
	$_dt_cefsharp_wpf_version = "110.0.300"
	$_dt_app_name="DeskTool"

	# Logging functions
	. $PSScriptRoot\DTCLog.ps1
	. $PSScriptRoot\DTLog.ps1
	
	# Helper funtions
	. $PSScriptRoot\DTHelper.ps1
	. $PSScriptRoot\DTCHelper.ps1

	# Config functions
	. $PSScriptRoot\DTCConfig.ps1
	. $PSScriptRoot\DTConfig.ps1

	# DT Pages
	. $PSScriptRoot\DTPages.ps1
	
	# Initialize directories
	New-Item -Path "$($env:APPDATA)\Frickeldave\DT" -ItemType Directory -Force | Out-Null

	# Initialize the configuration by copying the template file from programdata to datadir
	Copy-Item -Path "$PSScriptRoot\DTConfig.json" -Destination "$($env:APPDATA)\Frickeldave\DT\DTConfig.json" | Out-Null

	# Get the configuration values needed in the module
	$_dt_podeweb_port = $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlocalport")
	$_dt_theme = $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dttheme")
	Write-DTLog -Message "Serverport is: $_dt_podeweb_port" -Component "Module" -Type "Info" -LogSource "main"
	
	# Refresh logfile
	if((Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogrefresh") -eq $true) {
		Write-DTLog -Message "Logfile refreshed" -Component "Module" -RefreshLogFile -Type "Info" -LogSource "main"
	}

	# Remove oh-my-posh when it is loaded, otherwise Pode will raise several errors
	Remove-DTCOhMyPosh

	# Import all needed pode modules
	Import-DTCModule -ModuleName "pode" -ModuleVersion $_dt_pode_version
	Import-DTCModule -ModuleName "pode.web" -ModuleVersion $_dt_podeweb_version

	try {
		Start-PodeServer {
			Write-DTLog -Message "Start webservice on port $_dt_podeweb_port" -Component "Module" -Type "Info" -LogSource "main"
			Add-PodeEndpoint -Address "localhost" -Port $_dt_podeweb_port -Protocol Http -Name $_dt_app_name

			Write-DTLog -Message "Setup logging" -Component "Module"  -Type "Info" -LogSource "main"
			New-PodeLoggingMethod -Custom -ScriptBlock {
				param ( $item )

				#Initalize logging module with same parameters again, otherwise it's not available within the web session
				. $PSScriptRoot\DTCLog.ps1
				. $PSScriptRoot\DTSLog.ps1

				Write-DTLog -Message $($item.Message) -Component $($item.Component) -Type $($item.Type) -LogSource "main"
			} | Add-PodeLogger -Name "log" -ScriptBlock {
				param ($item)
				return $item
			}

			Write-DTLog -Message "Setup middleware" -Component "Module" -Type "Info" -LogSource "main"
			Enable-PodeSessionMiddleware -Secret "schwifty" -Duration 120 -Extend

			# setup custom auth
			Write-DTLog -Message "Setup authentication scheme" -Component "Module"  -Type "Info" -LogSource "main"
			$_custom_scheme = New-PodeAuthScheme -Custom -ScriptBlock {
				param($opts)

				#Load functions
				. $PSScriptRoot\DTLog.ps1
				. $PSScriptRoot\DTCLog.ps1

				#Write-DTLog -Message "$opts" -Component "Auth-Scheme" -Type "Info" -LogSource "main"
				Write-DTLog -Message "Receive data from login formular" -Component "Auth-Scheme" -Type "Info" -LogSource "main"

				# get the client/user/password from the request's post data
				$_user_name = $WebEvent.Data.Username
				$_user_secret = $WebEvent.Data.Secret

				# return the data in a array, which will be passed to the validator script
				return @($_user_name, $_user_secret)
			}

			#now, add a new custom authentication validator using the scheme you created above
			$_custom_scheme | Add-PodeAuth -Name 'Login' -ScriptBlock {
				param($UserName, $UserSecret)
				
				try {
					#Load functions
					. $PSScriptRoot\DTLog.ps1
					. $PSScriptRoot\DTCLog.ps1
					. $PSScriptRoot\DTServer.ps1
					. $PSScriptRoot\DTConfig.ps1
					. $PSScriptRoot\DTCConfig.ps1

					Write-DTLog -Message "Check authentication details against server" -Component "Auth-Scheme" -Type "Info" -LogSource "main"
					
					$_user = Grant-DTServerAccess -Username $UserName -Secret $UserSecret
					Write-DTLog -Message "$_user" -Component "Auth-Scheme" -Type "Info" -LogSource "main"
					return @{
						User = @{
							userId = $userId.userId
							userName = $_user.userName
							userFirstName = $_user.userFirstName
							userLastName = $_user.userLastName
							userTimestamp = $_user.userTimestamp
							userSid = $_user.userSid
						}
					}
				} catch {
					Write-DTLog -Message "Authentication failed. Details: $($_.Exception.Message)" -Component "Auth-Scheme" -Type "Error" -LogSource "main"
				}
			}

			Write-DTLog -Message "Start route /img for images" -Component "Module" -Type "Info" -LogSource "main"
			Add-PodeStaticRoute -Path "/img" -Source "$PSScriptRoot\img"

			# To enable as Desktop GUI do the following
			####################################################################################################
			# Download CefSvharp
			#Get-DTCefSharp -RedistVersion "$_dt_cefsharp_redis_version" -CommonVersion "$_dt_cefsharp_common_version" -WpfVersion "$_dt_cefsharp_wpf_version"
	
			# Write-DTLog -Message "Load CefSharp" -Component "Module" -Type "Info" -LogSource "main"
			# Add-Type -Path "$PSScriptRoot\lib\CefSharp\CefSharp.dll"
			# Add-Type -Path "$PSScriptRoot\lib\CefSharp\CefSharp.Wpf.dll"

			Write-DTLog -Message "Start UI for application $_dt_app_name" -Component "Module" -Type "Info" -LogSource "main"
			#Show-PodeGui -Title "$_dt_app_name" -WindowState Normal -WindowStyle SingleBorderWindow -Icon "$PSScriptRoot\img\DTLogo_Black.ico"
			####################################################################################################

			Use-PodeWebTemplates -Title "$_dt_app_name" -Logo http://localhost:$_dt_podeweb_port/img/DTLogo_White.ico -Theme $_dt_theme

			Get-DTPageLogin
			Get-DTPageHome -Title "$_dt_app_name"
			Get-DTPageConfig -Title "$_dt_app_name"
			Get-DTPagePoker -Title "$_dt_app_name"
		}
	}
	catch {
		Write-DTLog -Message "Failed to start Pode server. Details: $_" -Component "Module" -LogSource "main"
	}
}