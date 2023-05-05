function Get-DTPageLogin {
    
    # setup sessions
    Write-DTLog -Message "Setup the login page" -Component "Get-DTPageLogin" -Type "Info" -LogSource "main"
    
    

    #set the login page to use the custom auth, and also custom login fields
    Set-PodeWebLoginPage -Authentication 'Login' -Content @(
        # IMPORTANT: The name will be given to the backend. Please do not change. 
        New-PodeWebTextbox -Type Text -Name 'Username' -Id '_user_name' -Placeholder 'Username bla' -Required -DynamicLabel -AutoFocus
        New-PodeWebTextbox -Type Password -Name 'Secret' -Id '_user_secret' -Placeholder 'Password bla' -Required -DynamicLabel
    ) -PassThru |
    Register-PodeWebPageEvent -Type Load, Unload, BeforeUnload -NoAuth -ScriptBlock {
        Show-PodeWebToast -Message "Login page $($EventType)!"
    }


    Write-DTLog -Message "Finished" -Component "Get-DTPageLogin" -Type "Info" -LogSource "main"
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