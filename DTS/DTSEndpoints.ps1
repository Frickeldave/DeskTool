$script:_endpoint_config_base_path = $null
$script:_endpoint_config_folder = $null
$script:_endpoint_folder = $null
$script:_poker_base_bath = $null

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

    Write-DTCLog "Create all needed directories" -Component "Initialize-DTSEndpoints"
    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\$EndpointFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder\$EndpointFolder -ItemType Directory | Out-Null
    }

    $script:_poker_base_bath = "$script:_endpoint_config_base_path\$script:_endpoint_config_folder\$script:_endpoint_folder\poker"
    if (-Not (Test-Path "$script:_poker_base_bath")) {
        New-Item -Path "$script:_poker_base_bath" -ItemType Directory | Out-Null
    }
    Write-DTCLog "Initialized data path ""$script:_poker_base_bath""" -Component "Initialize-DTSEndpoints"
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

function Get-DTSEndpointPokerTableList {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/gettablelist'-ScriptBlock {

        param (
			$inputArgs
		)

        try {
            Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/poker/gettablelist"; Component="Get-DTSEndpointPokerTableList"; Type="Info"}

            . $PSScriptRoot\DTSEndpointsHelperPoker.ps1

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])

            # Call function to read all poker table files
            Write-PodeLog -Name "log" -InputObject @{Message="Load poker tables from file system"; Component="Get-DTSEndpointPokerTableList"; Type="Info"}
            $_return_obj_list = Get-DTSEndpointHelperPokerTableList -PokerBasePath $PokerBasePath
            Write-PodeLog -Name "log" -InputObject @{Message="Return data"; Component="Get-DTSEndpointPokerTableList"; Type="Info"}
            if($null -eq $_return_obj_list) {
                $_return_obj_list = ""
            } 
            Write-PodeJsonResponse -Value ($_return_obj_list | ConvertTo-Json) 
        }
        catch {
            Write-PodeLog -Name "log" -InputObject @{ Message="$($_.Exception.Message)"; Component="Get-DTSEndpointPokerTableList"; Type="Error" }
            $_poker_table_list_obj = New-Object -Type psobject
            $_poker_table_list_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get poker tables" -Force
            $_poker_table_list_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_poker_table_list_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath}
}

function Get-DTSEndpointPokerCreateTable {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/createtable'-ScriptBlock {

        param (
			$inputArgs
		)

        try {
            Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/poker/createtable"; Component="Get-DTSEndpointPokerCreateTable"; Type="Info"}

            . $PSScriptRoot\DTSEndpointsHelperPoker.ps1

            # Get URL based properties
            $PokerTableName = $WebEvent.Query['name']
            $PokerTableSecret = $WebEvent.Query['secret']
            $_poker_table_secret_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
            $_poker_table_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($PokerTableSecret)$($_poker_table_secret_salt)")) -Algorithm SHA256).Hash
            $PokerTableSecret = $null
            $_poker_table_guid = [guid]::NewGuid().ToString()

            Write-PodeLog -Name "log" -InputObject @{ Message="Requested table name ""$PokerTableName"""; Component="Get-DTSEndpointPokerCreateTable"; Type="Info" }

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])
            
            # Initialize json variable which we will return
            $_poker_table_json=$null

            # Call function to read all poker table files
            Write-PodeLog -Name "log" -InputObject @{Message="Check if poker table exist"; Component="Get-DTSEndpointPokerCreateTable"; Type="Info"}
            
            # Check if table already exist
            $_poker_table_obj = (Get-DTSEndpointHelperPokerTable -PokerBasePath $PokerBasePath -PokerTableName $PokerTableName)

            if($null -eq $_poker_table_obj -or "" -eq $_poker_table_obj) {
                
                # Create a powershell object with new table
                Write-PodeLog -Name "log" -InputObject @{ Message="Table doesn't exist -> create new file"; Component="Get-DTSEndpointPokerCreateTable"; Type="Info" }

                $_poker_table_creation_timestamp = Get-Date -format "yyyy-MM-dd HH:MM"

                $_poker_table_obj = New-Object -Type psobject
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableId" -Value $_poker_table_guid -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value $PokerTableName -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableSecret" -Value $_poker_table_secret_hash -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableSalt" -Value $_poker_table_secret_salt -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableTimestamp" -Value $_poker_table_creation_timestamp -Force

                # Convert to json and save to file
                Write-PodeLog -Name "log" -InputObject @{ Message="Save file"; Component="Get-DTSEndpointPokerCreateTable"; Type="Info" }
                $_poker_table_json = ($_poker_table_obj | ConvertTo-Json)
                $_poker_table_json | Out-File -Append -Encoding UTF8 -FilePath "$PokerBasePath\$_poker_table_guid.json"
            } else {
                # Table already exist
                Write-PodeLog -Name "log" -InputObject @{ Message="Poker table ""$PokerTableName"" already exist"; Component="Get-DTSEndpointPokerCreateTable"; Type="Info" }
            }

            # return the json file to requester
            $_poker_table_obj = Format-DTSEndpointHelperPokerTable -PokerTable $_poker_table_obj
            Write-PodeJsonResponse -Value $_poker_table_obj
        }
        catch {
            Write-PodeLog -Name "log" -InputObject @{ Message="$($_.Exception.Message)"; Component="Get-DTSEndpointPokerCreateTable"; Type="Error" }
            $_poker_table_obj = New-Object -Type psobject
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to create table" -Force
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_poker_table_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath} 
}

function Get-DTSEndpointPokerGetTable {
    
    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/gettable'-ScriptBlock {

        param (
			$inputArgs
		)

        try {
            Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/poker/gettable"; Component="Get-DTSEndpointPokerGetTable"; Type="Info"}

            . $PSScriptRoot\DTSEndpointsHelperPoker.ps1

            # Get URL based properties
            $PokerTableName = $WebEvent.Query['name']
            $PokerTableId = $WebEvent.Query['id']
            $PokerTableSecret = $WebEvent.Query['secret']

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])
            Write-PodeLog -Name "log" -InputObject @{ Message="Requested table with name ""$PokerTableName"" and id ""$PokerTableId"""; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
            
            # Get poker table
            $_poker_table = Get-DTSEndpointHelperPokerTable -PokerBasePath $PokerBasePath -PokerTableId $PokerTableId -PokerTableName $PokerTableName -PokerTableSecret $PokerTableSecret
            

            # # Check if user has access to table
            # if((Grant-DTSEndpointPokerTableAccess -PokerTable $_poker_table -PokerTableSecret $PokerTableSecret) -eq $false) {
            #     throw "Give secret doesn't match with table secret" }
                
            # $_poker_table = Format-DTSEndpointHelperPokerTable -PokerTable $_poker_table

            # return table to user
            Write-PodeJsonResponse -Value ($_poker_table | ConvertTo-Json)

        }
        catch {
            Write-PodeLog -Name "log" -InputObject @{ Message="$($_.Exception.Message)"; Component="Get-DTSEndpointPokerGetTable"; Type="Error" }
            $_poker_table_obj = New-Object -Type psobject
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get the requested table" -Force
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_poker_table_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath} 
}

function Get-DTSEndpointPokerJoinTable {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/jointable'-ScriptBlock {

        param (
			$inputArgs
		)

        try {
            Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/poker/jointable"; Component="Get-DTSEndpointPokerJoinTable"; Type="Info"}

            Write-PodeLog -Name "log" -InputObject @{Message="Initialize helper functions"; Component="Get-DTSEndpointPokerJoinTable"; Type="Info"}
            . $PSScriptRoot\DTSEndpointsHelperPoker.ps1

            # Get URL based properties
            $PokerTableName = $WebEvent.Query['name']
            $PokerTableId = $WebEvent.Query['id']
            $PokerTableSecret = $WebEvent.Query['secret']

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])
            Write-PodeLog -Name "log" -InputObject @{ Message="Requested table with name ""$PokerTableName"" and id ""$PokerTableId"""; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
            
            # Get poker table
            $_poker_table = Get-DTSEndpointHelperPokerTable -PokerBasePath $PokerBasePath -PokerTableId $PokerTableId -PokerTableName $PokerTableName -Full

            # Create the hash value form given secret
            Write-PodeLog -Name "log" -InputObject @{ Message="Check poker table secret"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
            $_poker_table_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($PokerTableSecret)$($_poker_table.pokerTableSalt)")) -Algorithm SHA256).Hash
            $PokerTableSecret = $null

            # Return the poker table to requester
            if($_poker_table_secret_hash -ne $($_poker_table.pokerTableSecret)) {
                throw "Wrong table secret given"
            } else {
                $_poker_table.PSObject.Properties.Remove("pokerTableSalt") 
                $_poker_table.PSObject.Properties.Remove("pokerTableSecret") 
                Write-PodeJsonResponse -Value ($_poker_table | ConvertTo-Json)
            }
        }
        catch {
            Write-PodeLog -Name "log" -InputObject @{ Message="$($_.Exception.Message)"; Component="Get-DTSEndpointPokerGetTable"; Type="Error" }
            $_poker_table_obj = New-Object -Type psobject
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get the requested table" -Force
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_poker_table_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath}     
}

