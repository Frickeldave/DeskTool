$script:_endpoint_config_base_path = $null
$script:_endpoint_config_folder = $null
$script:_endpoint_folder = $null

function Initialize-DTSEndpoints {
    [CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFolder,
        [string]$EndpointFolder
    )

    Write-DTCLog "Initialize endpoint configuration" -Component "Initialize-DTSEndpoints"
    
    $script:_endpoint_config_base_path = $ConfigBasePath
    $script:_endpoint_config_folder = $ConfigFolder
    $script:_endpoint_folder = $EndpointFolder

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\$EndpointFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder\$EndpointFolder -ItemType Directory | Out-Null
    }

    Write-DTCLog "Initialized data path ""$ConfigBasePath\$ConfigFolder\$EndpointFolder""" -Component "Initialize-DTSEndpoints"
}

function Get-DTSEndpointStatus {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/status' -ScriptBlock {
		
        Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/poker/status"; Component="Get-DTSEndpointStatus"; Type="Info"}

        $_return = New-Object -Type psobject
        $_return | Add-Member -MemberType NoteProperty -Name "currentTime" -Value (Get-Date -Format "yyyy-MM-dd HH:mm K") -Force
        $_return | Add-Member -MemberType NoteProperty -Name "status" -Value "OK" -Force
        Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
    }
}
function Get-DTSEndpointPokerGetTable {

    $_poker_base_bath = "$script:_endpoint_config_base_path\$script:_endpoint_config_folder\$script:_endpoint_folder\poker"

    Write-DTCLog "Start endpoint ""pokergettable"" with data path ""$_poker_base_bath""" -Component "Get-DTSEndpointPokerGetTable"

    if (-Not (Test-Path "$_poker_base_bath")) {
        New-Item -Path "$_poker_base_bath" -ItemType Directory | Out-Null
    }
    
    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/gettable'-ScriptBlock {

        param (
			$inputArgs
		)

        try {
            Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/poker/gettable"; Component="Get-DTSEndpointPokerGetTable"; Type="Info"}

            # Get URL based properties
            $PokerTableName = $WebEvent.Query['name']
            $PokerTablePassword = $WebEvent.Query['password']

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])
            Write-PodeLog -Name "log" -InputObject @{ Message="Requested table name ""$PokerTableName"""; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
            
            # Initialize json variable which we will return
            $_poker_table_json=$null

            Write-PodeLog -Name "log" -InputObject @{ Message="Datafile name is ""$PokerBasePath\$PokerTableName.json"""; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }

            # File (poker table) already exist
            if(Test-Path ("$PokerBasePath\$PokerTableName.json")) {
                
                # Get the content of the json file
                Write-PodeLog -Name "log" -InputObject @{ Message="Table already exist -> load existing file"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
                $_poker_table_json=(Get-Content -Path "$PokerBasePath\$PokerTableName.json" -Raw) | ConvertFrom-Json

                $_poker_table_password_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($PokerTablePassword)$($_poker_table_json.pokerTableSalt)")) -Algorithm SHA256).Hash
                $PokerTablePassword = $null

                Write-PodeLog -Name "log" -InputObject @{ Message="File password: $($_poker_table_json.pokerTablePassword)"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
                Write-PodeLog -Name "log" -InputObject @{ Message="Given password: $($_poker_table_password_hash)"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }

                if($_poker_table_password_hash -ne $($_poker_table_json.pokerTablePassword)) {
                    throw "Wrong table password given"
                }

            # lets create a new file (initialize the poker table)
            } else { 
                
                # Create a powershell object we convert into a json later
                Write-PodeLog -Name "log" -InputObject @{ Message="Table doesn't exist -> create new file"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
                
                #new-object System.Security.Cryptography.SHA256Managed | ForEach-Object {$_.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("$PokerTablePassword"))} | ForEach-Object {$_.ToString("x2")} | Write-Host -NoNewline
                $_poker_table_password_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
                $_poker_table_password_hash = Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($PokerTablePassword)$($_poker_table_password_salt)")) -Algorithm SHA256
                $PokerTablePassword = $null
                $_poker_table_creation_timestamp = Get-Date -format "yyyy-MM-dd HH:MM"

                $_poker_table_obj = New-Object -Type psobject
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value $PokerTableName -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTablePassword" -Value $($_poker_table_password_hash.Hash) -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableSalt" -Value $_poker_table_password_salt -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableTimestamp" -Value $_poker_table_creation_timestamp -Force

                # Convert to json and save to file
                Write-PodeLog -Name "log" -InputObject @{ Message="Save file"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
                $_poker_table_json = $_poker_table_obj | ConvertTo-Json
                $_poker_table_json | Out-File -Append -Encoding UTF8 -FilePath "$PokerBasePath\$PokerTableName.json"
            }
            # return the json file to requester
            $_poker_table_obj = New-Object -Type psobject
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value $PokerTableName -Force
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableTimestamp" -Value $_poker_table_creation_timestamp -Force
            Write-PodeJsonResponse -Value ($_poker_table_obj | ConvertTo-Json)
        }
        catch {
            Write-PodeLog -Name "log" -InputObject @{ Message="$($_.Exception.Message)"; Component="Get-DTSEndpointPokerGetTable"; Type="Error" }
            $_poker_table_obj = New-Object -Type psobject
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to create or join a table" -Force
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_poker_table_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $_poker_base_bath;"bla" = "blubb"} 
}
