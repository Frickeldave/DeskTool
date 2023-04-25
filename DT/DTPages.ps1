$script:_log_file_dir = $null
$script:_log_file_name = $null
$script:_log_target = $null

function Initialize-DTPages{

    [CmdletBinding()]
        param (
            [string]$LogFileDir,
            [string]$LogFileName,
            [string]$LogTarget
        )

    Write-DTCLog -Message "Initialize common page configuration" -Component "Initialize-DTPages"
    # TODO: Remove the following 3 lines
    Write-DTCLog -Message "Dir: $LogFileDir" -Component "Initialize-DTPages"
    Write-DTCLog -Message "Name: $LogFileName" -Component "Initialize-DTPages"
    Write-DTCLog -Message "Target: $LogTarget" -Component "Initialize-DTPages"
    $script:_log_file_dir = $LogFileDir
    $script:_log_file_name = $LogFileName
    $script:_log_target = $LogTarget
}

function Write-DTLog {

    [CmdletBinding()]
    param (
        [string]$Message,
        [string]$Component,
        [string]$Type
    )

    # TODO: This is statically added because i was not able to get the values from outside
    $script:_log_file_dir = "C:\Users\david\AppData\Local\Frickeldave\DT"
    $script:_log_file_name = "DT.log"
    $script:_log_target = "File"

    Write-PodeLog -Name "log" -InputObject @{Message=$Message; Component=$Component; Type=$Type; LogFileDir=$script:_log_file_dir; LogFileName=$script:_log_file_name; LogTarget=$script:_log_target}
}

function Get-DTPageLogin {
    
    # setup sessions
    Write-DTCLog "Enable middleware" -Component "Get-DTPageLogin"
    Enable-PodeSessionMiddleware -Duration 120 -Extend

    # define a new custom authentication scheme, which needs a client, username, and password
    $_auth_scheme = New-PodeAuthScheme -Custom -ScriptBlock {
        param($opts)

        #Load functions
        . $PSScriptRoot\DTPages.ps1

        Write-DTLog -Message "Enable authentication scheme" -Component "Get-DTPageLogin"
        # get the client/user/password from the request's post data
        $client = $WebEvent.Data.client
        $username = $WebEvent.Data.username
        $password = $WebEvent.Data.password
        Write-DTLog -Message "Client: $client, Username: $username, Password: $password" -Component "Get-DTPageLogin"
        # return the data in a array, which will be passed to the validator script
        return @($client, $username, $password)
    }

    #now, add a new custom authentication validator using the scheme you created above
    $_auth_scheme | Add-PodeAuth -Name Login -ScriptBlock {
        param($client, $username, $password)
        
        #Load functions
        . $PSScriptRoot\DTPages.ps1

        Write-DTLog -Message "Enable pode authentication" -Component "Get-DTPageLogin"
        # check if the client is valid in some database
        return @{
            User = @{
                ID ='M0R7Y302'
                Name = 'Morty'
                Type = 'Human'
            }
        }

        # return a user object (return $null if validation failed)
        return  @{ User = $user }
    }

    # set the login page to use the custom auth, and also custom login fields
    Write-DTCLog "Set login page" -Component "Get-DTPageLogin"
    Set-PodeWebLoginPage -Authentication Login -Content @(
        New-PodeWebTextbox -Type Text -Name 'client' -Id 'client' -Placeholder 'Client' -Required -AutoFocus -DynamicLabel
        New-PodeWebTextbox -Type Text -Name 'username' -Id 'username' -Placeholder 'Username' -Required -DynamicLabel
        New-PodeWebTextbox -Type Password -Name 'password' -Id 'password' -Placeholder 'Password' -Required -DynamicLabel
    )
    Write-DTCLog "Finished" -Component "Get-DTPageLogin"
}

function Get-DTPageHome {
    
    [CmdletBinding()]
    param (
        [string]$Title
    )

    Set-PodeWebHomePage -Layouts @(
        New-PodeWebHero -Title "$Title" -Message 'This is the home page' -Content @(
            New-PodeWebText -Value 'Welcome to Desktool. This is simple local desktop app for IT teams with the most imports tools they need everyday.' -InParagraph -Alignment Center
        )
    )
}

function Get-DTPageConfig {

    [CmdletBinding()]
    param (
        [string]$Title
    )

    Add-PodeWebPage -Name 'Config' -Icon 'wrench' -Layouts @(
        New-PodeWebCard -Id 'webcard_config_common' -Name 'Common' -Content @(
            New-PodeWebForm -Id 'webform_config_common' -Name 'Common' -ScriptBlock {
                $WebEvent.Data | Out-Default
            } -Content @(
                New-PodeWebTextbox -Id "common_dtteamnames" -Name 'Teams you are member of (One per line)' -Value $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtteamnames") -Multiline
                [bool]$_dt_server_active = Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtserveractive"
                New-PodeWebCheckbox -Id "common_dtserveractive" -Name 'Server active' -Checked:$_dt_server_active -AsSwitch
                New-PodeWebTextbox -Id "common_dtserveraddress" -Name 'Server address' -Value $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtserveraddress")
                New-PodeWebTextbox -Id "common_dtserverport" -Name 'Server port' -Value $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtserverport")
                New-PodeWebSelect -Id "common_dtlogtarget" -Name 'Log target' -Options 'Console', 'File' -SelectedValue $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogtarget")
                New-PodeWebTextbox -Id "common_dtlogdir" -Name 'Log directory' -Value $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogdir")
                New-PodeWebTextbox -Id "common_dtlogfile" -Name 'Logfile name' -Value $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogfile")
                [bool]$_dt_log_refresh = Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtlogrefresh"
                New-PodeWebCheckbox -Id "common_dtlogrefresh" -Name 'Refresh log on startup' -Checked:$_dt_log_refresh -AsSwitch
                New-PodeWebSelect -Id "common_dttheme" -Name 'Theme' -Options 'Auto', 'Custom', 'Dark', 'Light', 'Terminal' -SelectedValue $(Get-DTConfigValue -ConfigGroup "common" -ConfigName "dttheme")
            )
        )

        New-PodeWebCard -Id 'webcard_config_poker' -Name 'Poker' -Content @(
            New-PodeWebForm -Id 'webform_config_poker' -Name 'Poker' -ScriptBlock {
                $WebEvent.Data | Out-Default
            } -Content @(
                New-PodeWebTextbox -Id "poker_nickname" -Name 'Poker nickname' -Value $(Get-DTConfigValue -ConfigGroup "poker" -ConfigName "nickname")
                New-PodeWebTextbox -Id "poker_picture" -Name 'Poker picture' -Value $(Get-DTConfigValue -ConfigGroup "poker" -ConfigName "picture")
            )
        )
    )
}

function Get-DTPagePoker {

    [CmdletBinding()]
    param (
        [string]$Title
    )

    Add-PodeWebPage -Name 'Poker' -Icon 'cards-playing-outline' -Layouts @(
        New-PodeWebCard -Id 'webcard_poker' -Name 'Poker' -Content @(
            New-PodeWebForm -Id 'webform_poker' -Name 'Poker settings' -ScriptBlock {
                $WebEvent.Data | Out-Default
            } -Content @(
                New-PodeWebTextbox -Id "poker_table" -Name 'Poker table'
            ) -SubmitText "Enter"
        )
    )
}