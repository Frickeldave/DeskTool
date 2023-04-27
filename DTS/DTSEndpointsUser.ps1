$script:_user_base_bath = $null

function Initialize-UserEndpoint{

    [CmdletBinding()]
        param (
            [string]$ConfigBasePath,
            [string]$ConfigFolder,
            [string]$EndpointFolder
        )

    Write-DTCLog -Message "Initialize user endpoint configuration" -Component "Initialize-UserEndpoint"
    $script:_user_base_bath = "$ConfigBasePath\$ConfigFolder\$EndpointFolder\user"

    Write-DTCLog -Message "Create all needed directories for the user endpoint" -Component "Initialize-UserEndpoint"
    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\$EndpointFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder\$EndpointFolder -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path "$script:_user_base_bath")) {
        New-Item -Path "$script:_user_base_bath" -ItemType Directory | Out-Null
    }
    Write-DTCLog -Message "Initialized data path ""$script:_user_base_bath""" -Component "Initialize-UserEndpoint"
}

function Get-DTSUserListApi {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/user/getuserlist'-ScriptBlock {

        param (
			$inputArgs
		)

        try {
            # Load functions
            . $PSScriptRoot\DTSEndpointsCommon.ps1
            . $PSScriptRoot\DTSEndpointsUser.ps1

            # Get properties from input args
            $UserBasePath = $($inputArgs["UserBasePath"])

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/getuserlist" -Component "Get-DTSUserListApi" -Type "Info"

            # Call function to read all user files
            Write-DTSLog -Message "Load users from file system" -Component "Get-DTSUserListApi" -Type "Info"
            $_return_obj_list = Get-DTSUserList -UserBasePath $UserBasePath
            Write-DTSLog -Message "Return data" -Component "Get-DTSUserListApi" -Type "Info"
            if($null -eq $_return_obj_list) {
                $_return_obj_list = ""
            }
            Write-PodeJsonResponse -Value ($_return_obj_list | ConvertTo-Json)
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Get-DTSUserListApi" -Type "Error"
            $_user_list_obj = New-Object -Type psobject
            $_user_list_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get users" -Force
            $_user_list_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_user_list_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"UserBasePath" = $script:_user_base_bath}
}

function Add-DTSUserApi {

    Add-PodeRoute -Method Post -Path '/api/v1/dts/user/adduser'-ScriptBlock {

        param (
			$inputArgs
		)

        try {

            # Load functions
            . $PSScriptRoot\DTSEndpointsCommon.ps1
            . $PSScriptRoot\DTSEndpointsUser.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/adduser" -Component "Add-DTSUserApi" -Type "Info"

            # Get URL based properties
            $UserName = $WebEvent.Query['name']
            $UserSecret = $WebEvent.Query['secret']
            $_user_secret_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
            $_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($UserSecret)$($_user_secret_salt)")) -Algorithm SHA256).Hash
            $_user_guid = [guid]::NewGuid().ToString()

            Write-DTSLog -Message "Requested to create user with name ""$UserName"" and id ""$_user_guid""" -Component "Add-DTSUserApi" -Type "Info"
            
            # Get properties from input args
            $UserBasePath = $($inputArgs["UserBasePath"])

            # Initialize json variable which we will return
            $_user_json=$null

            # Call function to read all user files
            Write-DTSLog -Message "Check if user exist" -Component "Add-DTSUserApi" -Type "Info"
            $_user_obj = (Get-DTSUser -UserBasePath $UserBasePath -UserName $UserName)

            if($null -eq $_user_obj -or "" -eq $_user_obj) {

                # Create a powershell object with new user
                Write-DTSLog -Message "User doesn't exist -> create new file" -Component "Add-DTSUserApi" -Type "Info"

                $_user_creation_timestamp = Get-Date -format "yyyy-MM-dd HH:MM"

                $_user_obj = New-Object -Type psobject
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userId" -Value $_user_guid -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userName" -Value $UserName -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userSecret" -Value $_user_secret_hash -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userSalt" -Value $_user_secret_salt -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userTimestamp" -Value $_user_creation_timestamp -Force

                # Convert to json and save to file
                Write-DTSLog -Message "Save file" -Component "Add-DTSUserApi" -Type "Info"
                $_user_json = ($_user_obj | ConvertTo-Json)

                # TODO: Move this to a common-save-file method
                $_user_json | Out-File -Append -Encoding UTF8 -FilePath "$UserBasePath\$_user_guid.json"
            } else {
                # User already exist
                Write-DTSLog -Message "User ""$UserName"" already exist" -Component "Add-DTSUserApi" -Type "Info"
            }

            # format object
            $_user_obj = Format-DTSUser -User $_user_obj -UserSecret $UserSecret
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Add-DTSUserApi" -Type "Error"
            $_user_obj = New-Object -Type psobject
            $_user_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to create user" -Force
            $_user_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
        } finally {
            # return json to requester
            Write-PodeJsonResponse -Value ($_user_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"UserBasePath" = $script:_user_base_bath}
}

function Get-DTSUserApi {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/user/getuser'-ScriptBlock {

        param (
			$inputArgs
		)

        $_user = $null

        try {
            # Load functions
            . $PSScriptRoot\DTSEndpointsCommon.ps1
            . $PSScriptRoot\DTSEndpointsUser.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/getuser" -Component "Get-DTSUserApi" -Type "Info"

            # Get URL based properties
            $UserName = $WebEvent.Query['name']
            $UserId = $WebEvent.Query['id']

            # Get properties from input args
            $UserBasePath = $($inputArgs["UserBasePath"])

            Write-DTSLog -Message "Requested user with name ""$UserName"" and id ""$UserId""" -Component="Get-DTSUserApi" -Type "Info"

            # Get user
            $_user = Get-DTSUser -UserBasePath $UserBasePath -UserId $UserId -UserName $UserName
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Get-DTSUserApi" -Type "Error"
            $_user = New-Object -Type psobject
            $_user | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get the requested user" -Force
            $_user | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force

        } finally {
            # return user to requester
            Write-PodeJsonResponse -Value ($_user | ConvertTo-Json)
        }
    } -ArgumentList @{"UserBasePath" = $script:_user_base_bath}
}

Format-DTSUser {
    [CmdletBinding()]
    param (
        $User,
        [string]$UserSecret
    )

    # Do not anything when nothing is give
    if([string]::IsNullOrEmpty($User)) {
        return $User
    }

    $_user_authenticated = $false

    # Authenticate when a password is given (otherwise will create a minimal object)
    if(-Not [string]::IsNullOrEmpty($UserSecret)) {
        Write-DTSLog -Message "Try to authenticate against the user" -Component "Format-DTSUser" -Type "Info"
        $_user_authenticated = Grant-DTSUserAccess -User $User -UserSecret $UserSecret
    }

    # Authenticated, return full object (without secrets)
    if($_user_authenticated) {
        Write-DTSLog -Message "Return full object" -Component "Format-DTSUser" -Type "Info"
        $_user_obj = $User
        $_user_obj.PSObject.Properties.Remove("userSalt")
        $_user_obj.PSObject.Properties.Remove("userSecret")

    # Not authenticated, create the minimal object
    } else {
        Write-DTSLog -Message "Return minimal object" -Component "Format-DTSUser" -Type "Info"
        $_user_obj = New-Object -Type psobject
        $_user_obj | Add-Member -MemberType NoteProperty -Name "userId" -Value $User.userId -Force
        $_user_obj | Add-Member -MemberType NoteProperty -Name "userName" -Value $User.userName -Force
        $_user_obj | Add-Member -MemberType NoteProperty -Name "userTimestamp" -Value $User.userTimestamp -Force
    }
    return $_user_obj
}

function Grant-DTSUserAccess {

    [OutputType([bool])]

    [CmdletBinding()]
    param (
        $User,
        [string]$UserSecret
    )

    # Do not anything when nothing is give
    if([string]::IsNullOrEmpty($User)) {
        return $false
    }

    # Create the hash value from given secret
    Write-DTSLog -Message "Create hash from given secret" -Component "Grant-DTSUserAccess" -Type "Info"
    $_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($User)$($User.userSalt)")) -Algorithm SHA256).Hash
    $UserSecret = $null

    if($_user_secret_hash -ne $($User.userSecret)) {
        Write-DTSLog -Message "Secret did not match" -Component "Grant-DTSUserAccess" -Type "Info"
        return $false
    }

    Write-DTSLog -Message "Secret OK" -Component "Grant-DTSUserAccess" -Type "Info"
    return $true
}

function Get-DTSUser {
    [CmdletBinding()]
    param (
        [string]$UserBasePath,
        [string]$UserName,
        [string]$UserId
    )

    [PSCustomObject]$_user = $null

    # Prefer to get the user by the id
    if(-Not [string]::IsNullOrEmpty($UserId)) {
        Write-DTSLog -Message "Get user by ID" -Component "Get-DTSUser" -Type "Info"

        foreach($_user_file in (Get-ChildItem -Path "$UserBasePath" | Where-Object { $_.Name -like "*.json" } )) {
            try {
                if($($_user_file.Name) -eq "$($UserId).json") {
                    Write-DTSLog -Message "Found file $($UserId).json with matching Id" -Component "Get-DTSUser" -Type "Info"
                    $_user = (Get-Content -Path "$UserBasePath\$($_user_file.Name)" -Raw) | ConvertFrom-Json
                    $_user = Format-DTSUser -User $_user
                }
            } catch {
                Write-Output "$_.Exception.Message"
                Write-DTSLog -Message "Failed to get data for user file $_user_file" -Component "Get-DTSUser" -Type "Info"
            }
        }

    # Get the user by its name
    } elseif (-Not [string]::IsNullOrEmpty($UserName)) {
        Write-DTSLog -Message "Execute Get-DTSUserList to get user by name" -Component "Get-DTSUser" -Type "Info"
        $_user = Get-DTSUserList -UserBasePath $UserBasePath -UserName $UserName

    # Neither ID or username is given -> exit
    } else {
        throw "User ""Id"" (prefered) or ""name"" must be given"
    }

    # Report that no object was found
    if($null -eq $_user) {
        Write-DTSLog -Message "No user found" -Component "Get-DTSUser" -Type "Info"
    }

    return $_user
}

function Get-DTSUserList {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$UserBasePath,
        [string]$UserName
    )

    # Initialize array variable which we will return
    $_return_obj_list = @()

    foreach($_user_file in (Get-ChildItem -Path "$UserBasePath" | Where-Object { $_.Name -like "*.json" } )) {
        Write-DTSLog -Message "Found file ""$($_user_file.Name)""" -Component "Get-DTSUserList" -Type "Info"
        try {
            $_user_obj = (Get-Content -Path "$UserBasePath\$($_user_file.Name)" -Raw) | ConvertFrom-Json

            if(-not ([string]::IsNullOrEmpty($UserName))) {
                Write-DTSLog -Message "Filter with ""$UserName"" on user name ""$($_user_obj.userName)""" -Component "Get-DTSUserList" -Type "Info"
                if($($_user_obj.userName) -eq $UserName) {
                    $_user_obj = Format-DTSUser -User $_user_obj
                    $_return_obj_list += $_user_obj
                    break;
                }
            } else {
                $_user_obj = Format-DTSUser -User $_user_obj
                $_return_obj_list += $_user_obj
            }

        } catch {
            Write-Output "$_.Exception.Message"
            Write-DTSLog -Message "Failed to get data for user file $_user_file" -Component "Get-DTSUserList" -Type "Info"
        }
    }

    return $_return_obj_list
}

function Format-DTSUser {

    [CmdletBinding()]
    param (
        $User
    )

    # Do not anything when nothing is give
    if([string]::IsNullOrEmpty($User)) {
        return $User
    }

    Write-DTSLog -Message "Format user object" -Component "Format-DTSUser" -Type "Info"
    $User.PSObject.Properties.Remove("userSalt")
    $User.PSObject.Properties.Remove("userSecret")

    return $User

}