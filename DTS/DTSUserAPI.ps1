function Get-DTSUserAPI {

    Write-DTSLog -Message "Load user/get api" -Component "Get-DTSUserAPI" -Type "Info"

    Add-PodeRoute -Method Get -Path '/api/v1/dts/user/get' -Authentication 'Login' -ScriptBlock {

        $_return = $null

        try {
            # Load functions
            . $PSScriptRoot\DTSUserDB.ps1
            . $PSScriptRoot\DTSLog.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/get" -Component "Get-DTSUserAPI" -Type "Info"

            # Get URL based properties
            $UserName = $WebEvent.Query['name']
            $UserId = $WebEvent.Query['id']

            Write-DTSLog -Message "Requested user with name ""$UserName"" and id ""$UserId""" -Component "Get-DTSUserAPI" -Type "Info"

            # Get user
            $_return = Get-DTSUserDB -UserName $UserName -UserId $UserId
            $_return = Format-DTSUser -User $_return
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Get-DTSUserAPI" -Type "Error"
            $_return = New-Object -Type psobject
            $_return | Add-Member -MemberType NoteProperty -Name "Component" -Value "Get-DTSUserAPI" -Force
            $_return | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get the requested user" -Force
            $_return | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force

        } finally {
            # return user to requester
            Write-DTSLog -Message "Return user data data" -Component "Get-DTSUserAPI" -Type "Info"
            Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
        }
    }
}

function Get-DTSUserListAPI {

    Write-DTSLog -Message "Load user/getlist api" -Component "Get-DTSUserListAPI" -Type "Info"

    Add-PodeRoute -Method Get -Path '/api/v1/dts/user/getlist' -Authentication 'Login' -ScriptBlock {

        [Array]$_return = $null

        try {
            # Load functions
            . $PSScriptRoot\DTSUserDB.ps1
            . $PSScriptRoot\DTSLog.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/getlist" -Component "Get-DTSUserListAPI" -Type "Info"

            $UserName = $WebEvent.Query['name']

            # Call function to read all user files
            Write-DTSLog -Message "Load users from file system" -Component "Get-DTSUserListAPI" -Type "Info"
            $_return = Get-DTSUserListDB -UserName $UserName

            foreach($_user in $_return) {
                $_user = Format-DTSUser -User $_user
            }
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Get-DTSUserListAPI" -Type "Error"
            $_return = New-Object -Type psobject
            $_return | Add-Member -MemberType NoteProperty -Name "Component" -Value "Get-DTSUserListAPI" -Force
            $_return | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get user list" -Force
            $_return | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
        } finally {
            Write-DTSLog -Message "Return data" -Component "Get-DTSUserListAPI" -Type "Info"
            Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
        }
    }
}

function Add-DTSUserAPI {

    Write-DTSLog -Message "Load user/add api" -Component "Add-DTSUserAPI" -Type "Info"

    Add-PodeRoute -Method Post -Path '/api/v1/dts/user/add' -ScriptBlock {

        $_return = $null

        try {

            # Load functions
            . $PSScriptRoot\DTSUserDB.ps1
            . $PSScriptRoot\DTSLog.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/add" -Component "Add-DTSUserAPI" -Type "Info"

            # Get URL based properties
            $UserName = $WebEvent.Query['name']
            $UserSecret = $WebEvent.Query['secret']

            Write-DTSLog -Message "Requested to create user with name ""$UserName""" -Component "Add-DTSUserAPI" -Type "Info"
            $_return = Add-DTSUserDB -UserName $UserName -UserSecret $UserSecret

            # format object
            $_return = Format-DTSUser -User $_return
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Add-DTSUserAPI" -Type "Error"
            $_return = New-Object -Type psobject
            $_return | Add-Member -MemberType NoteProperty -Name "Component" -Value "Add-DTSUserAPI" -Force
            $_return | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to create user" -Force
            $_return | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
        } finally {
            # return json to requester
            Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
        }
    }
}

function Update-DTSUserAPI {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='None')]
    param()
    $PSCmdlet.ShouldProcess("dummy") | Out-Null

    Write-DTSLog -Message "Load user/update api" -Component "Update-DTSUserAPI" -Type "Info"

    Add-PodeRoute -Method Patch -Path '/api/v1/dts/user/update' -Authentication 'Login' -ScriptBlock {

        $_return = $null

        try {

            # Load functions
            . $PSScriptRoot\DTSUserDB.ps1
            . $PSScriptRoot\DTSLog.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/update" -Component "Update-DTSUserAPI" -Type "Info"

            # Get URL based properties
            $UserId = $WebEvent.Query['id']
            $UserName = $WebEvent.Query['name']
            $UserFirstName = $WebEvent.Query['firstname']
            $UserLastName = $WebEvent.Query['lastname']

            if([string]::IsNullOrEmpty($UserId) -and [string]::IsNullOrEmpty($UserName)) {
                throw "Neither username or userid is set"
            }

            Write-DTSLog -Message "Check permissions of requesting user" -Component "Update-DTSUserAPI" -Type "Info"
            $_isAdministrator = Get-RoleMembership -User $($WebEvent.Auth.User) -Role "Administrator"

            Write-DTSLog -Message "URL Name: $UserName; Session: $($WebEvent.Auth.User.userName)" -Component "Update-DTSUserAPI" -Type "Info"
            if(-Not $_isAdministrator -and $($WebEvent.Auth.User.userName)) {
                throw "Not allowed to update the user ""$UserName"""
            }

            Write-DTSLog -Message "Requested to update user with id ""$UserId"" name ""$UserName""" -Component "Update-DTSUserAPI" -Type "Info"
            $_return = [PSCustomObject](Update-DTSUserDB -UserId $UserId -UserName $UserName -UserFirstName $UserFirstName -UserLastName $UserLastName)

            # format object
            $_return = Format-DTSUser -User $_return
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Update-DTSUserAPI" -Type "Error"
            $_return = New-Object -Type psobject
            $_return | Add-Member -MemberType NoteProperty -Name "Component" -Value "Update-DTSUserAPI" -Force
            $_return | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to update user" -Force
            $_return | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
        } finally {
            # return json to requester
            Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
        }
    }
}