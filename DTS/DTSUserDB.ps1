function Get-DTSUserDB {
    [CmdletBinding()]
    param (
        [string]$UserName,
        [string]$UserId
    )

    [string]$user_base_path = "$PSScriptRoot\data\db\user"

    [PSCustomObject]$_user = $null

    # Prefer to get the user by the id
    if(-Not [string]::IsNullOrEmpty($UserId)) {
        Write-DTSLog -Message "Get user by ID" -Component "Get-DTSUserDB" -Type "Info"

        foreach($_user_file in (Get-ChildItem -Path "$user_base_path" | Where-Object { $_.Name -like "*.json" } )) {
            try {
                if($($_user_file.Name) -eq "$($UserId).json") {
                    Write-DTSLog -Message "Found file $($UserId).json with matching Id" -Component "Get-DTSUserDB" -Type "Info"
                    $_user = (Get-Content -Path "$user_base_path\$($_user_file.Name)" -Raw) | ConvertFrom-Json
                    #$_user = Format-DTSUserDB -User $_user
                }
            } catch {
                Write-Output "$_.Exception.Message"
                Write-DTSLog -Message "Failed to get data for user file $_user_file" -Component "Get-DTSUserDB" -Type "Info"
            }
        }

    # Get the user by its name
    } elseif (-Not [string]::IsNullOrEmpty($UserName)) {
        Write-DTSLog -Message "Execute Get-DTSUserListDB to get user by name" -Component "Get-DTSUserDB" -Type "Info"
        [Array]$_user_list = Get-DTSUserListDB -UserName $UserName
        if($($_user_list.Count) -eq 1) {
            $_user = $_user_list[0]
        }
        if($null -eq $_user_list -or ($($_user_list.Count) -eq 0)) {
            $_user = $null
        }
        if($($_user_list.Count) -gt 1) {
            throw "More than one ($($_user_list.Count)) user found matching pattern ""$UserName"""
        }
    # Neither ID or username is given -> exit
    } else {
        throw "User ""Id"" (prefered) or ""name"" must be given"
    }

    # Report that no object was found
    if($null -eq $_user) {
        Write-DTSLog -Message "No user found" -Component "Get-DTSUserDB" -Type "Info"
    }

    return $_user
}

function Get-DTSUserListDB {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$UserName
    )

    [string]$user_base_path = "$PSScriptRoot\data\db\user"

    # Initialize array variable which we will return
    $_return_list = @()

    foreach($_user_file in (Get-ChildItem -Path "$user_base_path" | Where-Object { $_.Name -like "*.json" } )) {
        try {
            $_user = (Get-Content -Path "$user_base_path\$($_user_file.Name)" -Raw) | ConvertFrom-Json

            if(-not ([string]::IsNullOrEmpty($UserName)) -and $($_user.userName) -eq $UserName) {
                $_return_list += $_user
            }
            if([string]::IsNullOrEmpty($UserName)) {
                $_return_list += $_user
            }

        } catch {
            Write-Output "$_.Exception.Message"
            Write-DTSLog -Message "Failed to get data for user file $_user_file" -Component "Get-DTSUserListDB" -Type "Info"
        }
    }

    Write-DTSLog -Message "Found $($_return_list.Count) user objects" -Component "Get-DTSUserListDB" -Type "Info"
    return $_return_list
}

function Add-DTSUserDB {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$UserName,
        [string]$UserSecret
    )

    [string]$user_base_path = "$PSScriptRoot\data\db\user"

    # Get user to check if already exist
    Write-DTSLog -Message "Check if user exist" -Component "Add-DTSUserDB" -Type "Info"
    $_user = (Get-DTSUserDB -UserName $UserName)
    if ($null -ne $_user) { throw "User already exist" }

    # Create a powershell object with new user
    Write-DTSLog -Message "User doesn't exist -> create new user" -Component "Add-DTSUserDB" -Type "Info"
    $_user_secret_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
    $_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($UserSecret)$($_user_secret_salt)")) -Algorithm SHA256).Hash
    $_user_guid = [guid]::NewGuid().ToString()
    $_user_timestamp = Get-Date -format "yyyy-MM-dd HH:MM"

    $_user = New-Object -Type psobject
    $_user | Add-Member -MemberType NoteProperty -Name "userId" -Value $_user_guid -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userName" -Value $UserName -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userSecret" -Value $_user_secret_hash -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userSalt" -Value $_user_secret_salt -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userTimestamp" -Value $_user_timestamp -Force

    # Convert to json and save to file
    Write-DTSLog -Message "Save user to filesystem" -Component "Add-DTSUserDB" -Type "Info"
    $_user_json = ($_user | ConvertTo-Json)
    $_user_json | Out-File -Append -Encoding UTF8 -FilePath "$user_base_path\$_user_guid.json"

    return $_user
}

function Update-DTSUserDB {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='None')]
    param (
        [Parameter()]
        [string]$UserId,
        [string]$UserName,
        [string]$UserFirstName,
        [string]$UserLastName
    )
    $PSCmdlet.ShouldProcess("dummy")

    [string]$user_base_path = "$PSScriptRoot\data\db\user"

    # Get user to check if already exist
    Write-DTSLog -Message "Check if user exist" -Component "Update-DTSUserDB" -Type "Info"
    $_old_user = (Get-DTSUserDB -UserId $UserId -UserName $UserName)
    if ($null -eq $_old_user) { throw "User doesn't exist" }

    # Create a powershell object with new user
    Write-DTSLog -Message "User exist -> Update user" -Component "Update-DTSUserDB" -Type "Info"

    $_user_first_name = if([string]::IsNullOrEmpty($UserFirstName)) { $($_old_user.userFirstname) } else { $UserFirstName }
    $_user_last_name = if([string]::IsNullOrEmpty($UserLastName)) { $($_old_user.userLastname) } else { $UserLastName }
    $_user = New-Object -Type psobject
    $_user | Add-Member -MemberType NoteProperty -Name "userId" -Value $($_old_user.userId) -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userName" -Value $($_old_user.userName) -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userSecret" -Value $($_old_user.userSecret) -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userSalt" -Value $($_old_user.userSalt) -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userTimestamp" -Value $($_old_user.Timestamp) -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userFirstname" -Value $_user_first_name -Force
    $_user | Add-Member -MemberType NoteProperty -Name "userLastname" -Value $_user_last_name -Force

    # Convert to json and save to file
    Write-DTSLog -Message "Save user to filesystem" -Component "Update-DTSUserDB" -Type "Info"
    $_user_json = ($_user | ConvertTo-Json)
    $_user_json | Out-File -Encoding UTF8 -FilePath "$user_base_path\$($_user.userId).json"

    return $_user
}


function Format-DTSUser {

    [CmdletBinding()]
    param (
        $User
    )

    # Do not anything when nothing is given
    if([string]::IsNullOrEmpty($User)) {
        return $User
    }

    Write-DTSLog -Message "Format user object by removing secrets" -Component "Format-DTSUser" -Type "Info"
    $User.PSObject.Properties.Remove("userSecret")
    $User.PSObject.Properties.Remove("userSalt")

    Write-DTSLog -Message "$User" -Component "Format-DTSUser" -Type "Info"
    HIER TUT DIE FICKE EINFACH WIEDER MAL NICHT
    return $User
}