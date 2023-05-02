function Get-DTSUserApi {

    Write-DTSLog -Message "Load user/get api" -Component "Get-DTSUserListAPI" -Type "Info"

    Add-PodeRoute -Method Get -Path '/api/v1/dts/user/get' -Authentication 'Login' -ScriptBlock {

        $_user = $null

        try {
            # Load functions
            . $PSScriptRoot\DTSUserDB.ps1
            . $PSScriptRoot\DTSLog.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/get" -Component "Get-DTSUserApi" -Type "Info"

            # Get URL based properties
            $UserName = $WebEvent.Query['name']
            $UserId = $WebEvent.Query['id']

            Write-DTSLog -Message "Requested user with name ""$UserName"" and id ""$UserId""" -Component="Get-DTSUserApi" -Type "Info"

            # Get user
            $_user = Get-DTSUserDB -UserName $UserName -UserId $UserId
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
    }
}

function Get-DTSUserListAPI {

    Write-DTSLog -Message "Load user/getlist api" -Component "Get-DTSUserListAPI" -Type "Info"

    Add-PodeRoute -Method Get -Path '/api/v1/dts/user/getlist' -Authentication 'Login' -ScriptBlock {

        try {
            # Load functions
            . $PSScriptRoot\DTSUserDB.ps1
            . $PSScriptRoot\DTSLog.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/getlist" -Component "Get-DTSUserListAPI" -Type "Info"

            $UserName = $WebEvent.Query['name']

            # Call function to read all user files
            Write-DTSLog -Message "Load users from file system" -Component "Get-DTSUserListAPI" -Type "Info"
            $_return_obj_list = Get-DTSUserListDB -UserName $UserName

            Write-DTSLog -Message "Return data" -Component "Get-DTSUserListAPI" -Type "Info"
            if($null -eq $_return_obj_list) {
                $_return_obj_list = ""
            }
            Write-PodeJsonResponse -Value ($_return_obj_list | ConvertTo-Json)
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Get-DTSUserListAPI" -Type "Error"
            $_user_list_obj = New-Object -Type psobject
            $_user_list_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get users" -Force
            $_user_list_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_user_list_obj | ConvertTo-Json)
        }
    }
}

# function Add-DTSUserAPI {

#     Add-PodeRoute -Method Post -Path '/api/v1/dts/user/add' -ScriptBlock {

#         param (
# 			$inputArgs
# 		)

#         try {

#             # Load functions
#             . $PSScriptRoot\DTSUserDB.ps1
#             . $PSScriptRoot\DTSLog.ps1

#             Write-DTSLog -Message "Got incoming request on path /api/v1/dts/user/add" -Component "Add-DTSUserAPI" -Type "Info"

#             # Get URL based properties
#             $UserName = $WebEvent.Query['name']
#             $UserSecret = $WebEvent.Query['secret']
#             $_user_secret_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
#             $_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($UserSecret)$($_user_secret_salt)")) -Algorithm SHA256).Hash
#             $_user_guid = [guid]::NewGuid().ToString()

#             Write-DTSLog -Message "Requested to create user with name ""$UserName"" and id ""$_user_guid""" -Component "Add-DTSUserApi" -Type "Info"

#             # Get properties from input args
#             $UserBasePath = $($inputArgs["UserBasePath"])

#             # Initialize json variable which we will return
#             $_user_json=$null

#             # Call function to read all user files
#             Write-DTSLog -Message "Check if user exist" -Component "Add-DTSUserApi" -Type "Info"
#             $_user = (Get-DTSUser -UserBasePath $UserBasePath -UserName $UserName)
#             if ($null -ne $_user) { throw "User already exist" }

#             if($null -eq $_user -or "" -eq $_user) {

#                 # Create a powershell object with new user
#                 Write-DTSLog -Message "User doesn't exist -> create new file" -Component "Add-DTSUserApi" -Type "Info"

#                 $_user_creation_timestamp = Get-Date -format "yyyy-MM-dd HH:MM"

#                 $_user = New-Object -Type psobject
#                 $_user | Add-Member -MemberType NoteProperty -Name "userId" -Value $_user_guid -Force
#                 $_user | Add-Member -MemberType NoteProperty -Name "userName" -Value $UserName -Force
#                 $_user | Add-Member -MemberType NoteProperty -Name "userSecret" -Value $_user_secret_hash -Force
#                 $_user | Add-Member -MemberType NoteProperty -Name "userSalt" -Value $_user_secret_salt -Force
#                 $_user | Add-Member -MemberType NoteProperty -Name "userTimestamp" -Value $_user_creation_timestamp -Force

#                 # Convert to json and save to file
#                 Write-DTSLog -Message "Save file" -Component "Add-DTSUserApi" -Type "Info"
#                 $_user_json = ($_user | ConvertTo-Json)

#                 # TODO: Move this to a common-save-file method
#                 $_user_json | Out-File -Append -Encoding UTF8 -FilePath "$UserBasePath\$_user_guid.json"
#             } else {
#                 # User already exist
#                 Write-DTSLog -Message "User ""$UserName"" already exist" -Component "Add-DTSUserApi" -Type "Info"
#             }

#             # format object
#             $_user = Format-DTSUser -User $_user
#         }
#         catch {
#             Write-DTSLog -Message "$($_.Exception.Message)" -Component "Add-DTSUserApi" -Type "Error"
#             $_user = New-Object -Type psobject
#             $_user | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to create user" -Force
#             $_user | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
#         } finally {
#             # return json to requester
#             Write-PodeJsonResponse -Value ($_user | ConvertTo-Json)
#         }
#     } -ArgumentList @{"UserBasePath" = $script:_user_base_bath}
# }
