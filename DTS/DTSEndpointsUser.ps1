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

function Add-DTSEndpointUser {

    Add-PodeRoute -Method Post -Path '/api/v1/dts/user/adduser'-ScriptBlock {

        param (
			$inputArgs
		)

        try {
            Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/user/adduser"; Component="Add-DTSEndpointUser"; Type="Info"}

            . $PSScriptRoot\DTSEndpointsUserHelper.ps1

            # Get URL based properties
            $UserName = $WebEvent.Query['name']
            $UserSecret = $WebEvent.Query['secret']
            $_user_secret_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
            $_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($UserSecret)$($_user_secret_salt)")) -Algorithm SHA256).Hash
            $_user_guid = [guid]::NewGuid().ToString()

            Write-PodeLog -Name "log" -InputObject @{ Message="Requested user name ""$UserName"""; Component="Add-DTSEndpointUser"; Type="Info" }

            # Get properties from input args
            $UserBasePath = $($inputArgs["UserBasePath"])

            # Initialize json variable which we will return
            $_user_json=$null

            # Call function to read all user files
            Write-PodeLog -Name "log" -InputObject @{Message="Check if user exist"; Component="Add-DTSEndpointUser"; Type="Info"}
            $_user_obj = (Get-DTSEndpointUserHelper -UserBasePath $UserBasePath -UserName $UserName)

            if($null -eq $_user_obj -or "" -eq $_user_obj) {

                # Create a powershell object with new user
                Write-PodeLog -Name "log" -InputObject @{ Message="User doesn't exist -> create new file"; Component="Add-DTSEndpointUser"; Type="Info" }

                $_user_creation_timestamp = Get-Date -format "yyyy-MM-dd HH:MM"

                $_user_obj = New-Object -Type psobject
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userId" -Value $_user_guid -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userName" -Value $UserName -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userSecret" -Value $_user_secret_hash -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userSalt" -Value $_user_secret_salt -Force
                $_user_obj | Add-Member -MemberType NoteProperty -Name "userTimestamp" -Value $_user_creation_timestamp -Force

                # Convert to json and save to file
                Write-PodeLog -Name "log" -InputObject @{ Message="Save file"; Component="Add-DTSEndpointUser"; Type="Info" }
                $_user_json = ($_user_obj | ConvertTo-Json)
                $_user_json | Out-File -Append -Encoding UTF8 -FilePath "$UserBasePath\$_user_guid.json"
            } else {
                # User already exist
                Write-PodeLog -Name "log" -InputObject @{ Message="User ""$UserName"" already exist"; Component="Add-DTSEndpointUser"; Type="Info" }
            }

            # return the json file to requester
            $_user_obj = Format-DTSEndpointHelperUser -User $_user_obj -UserSecret $UserSecret
            Write-PodeJsonResponse -Value $_user_obj
        }
        catch {
            Write-PodeLog -Name "log" -InputObject @{ Message="$($_.Exception.Message)"; Component="Add-DTSEndpointUser"; Type="Error" }
            $_user_obj = New-Object -Type psobject
            $_user_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to create user" -Force
            $_user_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_user_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"UserBasePath" = $script:_user_base_bath}
}