function Initialize-DTS {

	# Set all static variables
	$_dts_pode_version = "2.8.0"
	$_dts_app_name = "Desktool server"

	# Logging functions
	. $PSScriptRoot\DTCLog.ps1
	. $PSScriptRoot\DTSLog.ps1

	# Common functions
	. $PSScriptRoot\DTCHelper.ps1

	# Config functions
	. $PSScriptRoot\DTCConfig.ps1
	. $PSScriptRoot\DTSConfig.ps1

	# API functions
	. $PSScriptRoot\DTSCommonAPI.ps1
	. $PSScriptRoot\DTSUserDB.ps1
	. $PSScriptRoot\DTSUserAPI.ps1

	New-Item -Path "$PSScriptRoot\data\db\user" -ItemType Directory -Force | Out-Null

	# Initialize the configuration
	Initialize-DTCConfig -ConfigBasePath $PSScriptRoot -ConfigFile "DTSConfig.json"

	# Get the configuration values needed in the module
	$_dts_podeweb_port = $(Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtsserverport")
	Write-DTSLog -Message "Serverport is: $_dts_podeweb_port" -Component "Module" -Type "Info" -LogSource "main"

	# Refresh logfile
	if((Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogrefresh") -eq $true) {
		Write-DTSLog -Message "Logfile refreshed" -Component "Module" -RefreshLogFile -Type "Info" -LogSource "main"
	}

	# Remove oh-my-posh when it is loaded, otherwise Pode will raise several errors
	Remove-DTCOhMyPosh

	# Import pode module
	Import-DTCModule -ModuleName "pode" -ModuleVersion $_dts_pode_version

	try {
		Start-PodeServer {
			Write-DTSLog -Message "Start webservice on port $_dts_podeweb_port" -Component "Module" -Type "Info" -LogSource "main"
			Add-PodeEndpoint -Address "localhost" -Port $_dts_podeweb_port -Protocol Http -Name $_dts_app_name

			Write-DTSLog -Message "Setup view engine" -Component "Module"  -Type "Info" -LogSource "main"
			Set-PodeViewEngine -Type Pode

			Write-DTSLog -Message "Setup logging" -Component "Module"  -Type "Info" -LogSource "main"
			New-PodeLoggingMethod -Custom -ScriptBlock {
				param ( $item )

				#Initalize logging module with same parameters again, otherwise it's not available within the web session
				. $PSScriptRoot\DTCLog.ps1
				. $PSScriptRoot\DTSLog.ps1

				Write-DTSLog -Message $($item.Message) -Component $($item.Component) -Type $($item.Type) -LogSource "main"
			} | Add-PodeLogger -Name "log" -ScriptBlock {
				param ($item)
				return $item
			}

			Write-DTSLog -Message "Setup middleware" -Component "Module"  -Type "Info" -LogSource "main"
			Enable-PodeSessionMiddleware -Duration 120 -Extend -UseHeaders -Strict # TRict will include IP and UserAgent

			# setup basic auth (base64> username:password in header)
			Write-DTSLog -Message "Setup authentication scheme" -Component "Module"  -Type "Info" -LogSource "main"
			New-PodeAuthScheme -Basic | Add-PodeAuth -Name 'Login' -ScriptBlock {
				param($UserName, $UserSecret)

				# Load functions
				. $PSScriptRoot\DTSUserDB.ps1
				. $PSScriptRoot\DTSLog.ps1

				Write-DTSLog -Message "Get user with name ""$UserName"" from database" -Component "Auth-Scheme" -Type "Info"
				$_user = Get-DTSUserListDB -UserName $UserName

				Write-DTSLog -Message "Authenticate user ""$($_user.userName)""" -Component "Auth-Scheme" -Type "Info"
				$_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($UserSecret)$($_user.userSalt)")) -Algorithm SHA256).Hash
				$UserSecret = $null
				$_user_authenticated = ($_user_secret_hash -eq $($_user.userSecret))

				if ($_user_authenticated) {
					Write-DTSLog -Message "User is authenticated" -Component "Auth-Scheme" -Type "Info"
					return @{
						User = @{
							ID =$_user.ID
							Name = $_user.Name
							Type = 'Human'
						}
					}
				} else {
					Write-DTSLog -Message "User is not authenticated" -Component "Auth-Scheme" -Type "Info"
				}

				# Authentication failed
				Write-DTSLog -Message "Authentication failed" -Component "Auth-Scheme" -Type "Info"
				return @{ Message = 'Invalid details supplied' }
			}

			Add-PodeRoute -Method Post -Path '/login' -Authentication 'Login'
			Add-PodeRoute -Method Post -Path '/logout' -Authentication 'Login' -Logout

			# Load all API functions
			Get-DTSCommonStatusAPI
			Get-DTSUserListAPI
			Get-DTSUserApi
		}
	}
	catch {
		Write-DTSLog -Message "Failed to start Pode server. Details: $_" -Component "Module" -LogSource "main" -Type "Error"
	}
}