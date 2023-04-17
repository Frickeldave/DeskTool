[CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFolder,
        [string]$EndpointFolder
    )

Write-DTCLog "Initialize user endpoint configuration" -Component "DTSEndpointsUser"
$script:_endpoint_config_base_path = $null
$script:_endpoint_config_folder = $null
$script:_endpoint_folder = $null
$script:_user_base_bath = $null

$script:_endpoint_config_base_path = $ConfigBasePath
$script:_endpoint_config_folder = $ConfigFolder
$script:_endpoint_folder = $EndpointFolder

Write-DTCLog "Create all needed directories for the user endpoint" -Component "DTSEndpointsUser"
if (-Not (Test-Path $ConfigBasePath\$ConfigFolder)) {
    New-Item -Path $ConfigBasePath\$ConfigFolder -ItemType Directory | Out-Null
}

if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\$EndpointFolder)) {
    New-Item -Path $ConfigBasePath\$ConfigFolder\$EndpointFolder -ItemType Directory | Out-Null
}

$script:_user_base_bath = "$script:_endpoint_config_base_path\$script:_endpoint_config_folder\$script:_endpoint_folder\user"
if (-Not (Test-Path "$script:_user_base_bath")) {
    New-Item -Path "$script:_user_base_bath" -ItemType Directory | Out-Null
}
Write-DTCLog "Initialized data path ""$script:_user_base_bath""" -Component "DTSEndpointsUser"

function Add-DTSUser {

    Add-PodeRoute -Method Post -Path '/api/v1/dts/user/adduser'-ScriptBlock {

        param (
			$inputArgs
		)

        try {
            Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/user/adduser"; Component="Add-DTSUser"; Type="Info"}

            # Get URL based properties
            $UserName = $WebEvent.Query['name']
            $UserSecret = $WebEvent.Query['secret']
            $_user_secret_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
            $_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($UserSecret)$($_user_secret_salt)")) -Algorithm SHA256).Hash
            $UserSecret = $null
            $_user_guid = [guid]::NewGuid().ToString()

            Write-PodeLog -Name "log" -InputObject @{ Message="Requested to create user with name ""$UserName"" and id ""$_user_guid"""; Component="Add-DTSUser"; Type="Info" }

            # Get properties from input args
            $UserBasePath = $($inputArgs["UserBasePath"])

            # Initialize json variable which we will return
            $_user_json=$null

            # Call function to read all user files
            Write-PodeLog -Name "log" -InputObject @{Message="Check if user exist"; Component="Add-DTSUser"; Type="Info"}
            $_user_obj = (Get-DTSUser -UserBasePath $UserBasePath -UserName $UserName)

            if($null -eq $_user_obj -or "" -eq $_user_obj) {

                # Create a powershell object with new user
                Write-PodeLog -Name "log" -InputObject @{ Message="User doesn't exist -> create new file"; Component="Add-DTSUser"; Type="Info" }

                $_user_creation_timestamp = Get-Date -format "yyyy-MM-dd HH:MM"

                $_user_obj = New-Object -Type psobject
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userId" -Value $_user_guid -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userName" -Value $UserName -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userSecret" -Value $_user_secret_hash -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userSalt" -Value $_user_secret_salt -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userTimestamp" -Value $_user_creation_timestamp -Force

                # Convert to json and save to file
                Write-PodeLog -Name "log" -InputObject @{ Message="Save file"; Component="Add-DTSUser"; Type="Info" }
                $_user_json = ($_user_obj | ConvertTo-Json)
                $_user_json | Out-File -Append -Encoding UTF8 -FilePath "$UserBasePath\$_user_guid.json"
            } else {
                # User already exist
                Write-PodeLog -Name "log" -InputObject @{ Message="User ""$UserName"" already exist"; Component="Add-DTSUser"; Type="Info" }
            }

            # return the json file to requester
            $_user_obj = Format-DTSUser -User $_user_obj
        }
        catch {
            Write-PodeLog -Name "log" -InputObject @{ Message="$($_.Exception.Message)"; Component="Add-DTSUser"; Type="Error" }
            $_user_obj = New-Object -Type psobject
            $_user_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to create user" -Force
            $_user_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
        } finally {
            Write-PodeJsonResponse -Value ($_user_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"UserBasePath" = $script:_user_base_bath}
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
        Write-PodeLog -Name "log" -InputObject @{ Message="Get user by ID"; Component="Get-DTSUser"; Type="Info" }

        foreach($_user_file in (Get-ChildItem -Path "$UserBasePath" | Where-Object { $_.Name -like "*.json" } )) {
            try {

                if($($_user_file.Name) -eq "$($UserId).json") {
                    Write-PodeLog -Name "log" -InputObject @{ Message="Found file $($UserId).json with matching Id"; Component="Get-DTSUser"; Type="Info" }
                    $_user = (Get-Content -Path "$UserBasePath\$($_user_file.Name)" -Raw) | ConvertFrom-Json
                    $_user = Format-DTSUser -User $_user
                }
            } catch {
                Write-Output "$_.Exception.Message"
                Write-PodeLog -Name "log" -InputObject @{ Message="Failed to get data for user file $_user_file"; Component="Get-DTSUser"; Type="Info" }
            }
        }

    # Get the user by its name
    } elseif (-Not [string]::IsNullOrEmpty($UserName)) {
        Write-PodeLog -Name "log" -InputObject @{Message="Execute Get-DTSUserList to get user by name"; Component="Get-DTSUser"; Type="Info"}
        $_user_list = Get-DTSUserList -UserBasePath $UserBasePath

        foreach($_user in $_user_list) {
            if($_user.userName -eq $UserName) {
                Write-PodeLog -Name "log" -InputObject @{Message="Found user with id $($_user.UserId)"; Component="Get-DTSUser"; Type="Info"}
                $_user = Format-DTSUser -User $_user
                break; # Get the first item and ignore all other results
            }
        }
    # Neither ID or username is given -> exit
    } else {
        throw "User ""Id"" (prefered) or ""name"" must be given"
    }

    # Report that no object was found
    if($null -eq $_user) {
        Write-PodeLog -Name "log" -InputObject @{Message="No user found"; Component="Get-DTSUser"; Type="Info"}
    }

    return $_user
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

    Write-PodeLog -Name "log" -InputObject @{ Message="Format user object"; Component="Format-DTSUser"; Type="Info" }
    $User.PSObject.Properties.Remove("userSalt")
    $User.PSObject.Properties.Remove("userSecret")

    return $User

}