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
        Write-DTSLog -Message "Execute Get-DTSUserList to get user by name" -Component "Get-DTSUserDB" -Type "Info"
        [Array]$_user_list = Get-DTSUserListDB -UserBasePath $user_base_path -UserName $UserName
        if($($_user_list.Count) -eq 1) {
            $_user = $_user_list[0]
        } else {
            throw "More than one user found matching pattern"
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

    Write-DTSLog -Message "Search for user files in ""$user_base_path""" -Component "Get-DTSUserListDB" -Type "Info"

    foreach($_user_file in (Get-ChildItem -Path "$user_base_path" | Where-Object { $_.Name -like "*.json" } )) {
        Write-DTSLog -Message "Found file ""$($_user_file.Name)""" -Component "Get-DTSUserListDB" -Type "Info"
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

function Grant-DTSUserAccessDB {

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
    Write-DTSLog -Message "Create hash from given secret" -Component "Grant-DTSUserAccessDB" -Type "Info"
    $_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($UserSecret)$($User.userSalt)")) -Algorithm SHA256).Hash

    $UserSecret = $null

    if($_user_secret_hash -ne $($User.userSecret)) {
        Write-DTSLog -Message "Secret did not match" -Component "Grant-DTSUserAccessDB" -Type "Info"
        return $false
    }

    Write-DTSLog -Message "Secret OK" -Component "Grant-DTSUserAccessDB" -Type "Info"
    return $true
}