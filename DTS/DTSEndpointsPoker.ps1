$script:_poker_base_bath = $null

function Initialize-PokerEndpoint {

    [CmdletBinding()]
        param (
            [string]$ConfigBasePath,
            [string]$ConfigFolder,
            [string]$EndpointFolder
        )

    Write-DTSLog -Message "Initialize poker endpoint configuration" -Component "Initialize-PokerEndpoint"
    $script:_poker_base_bath = "$ConfigBasePath\$ConfigFolder\$EndpointFolder\poker"

    Write-DTSLog -Message "Create all needed directories for the poker endpoint" -Component "Initialize-PokerEndpoint"
    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder -ItemType Directory  | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\$EndpointFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder\$EndpointFolder -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path "$script:_poker_base_bath")) {
        New-Item -Path "$script:_poker_base_bath" -ItemType Directory | Out-Null
    }
Write-DTSLog -Message "Initialized data path ""$script:_poker_base_bath""" -Component "Initialize-PokerEndpoint"
}

function Get-DTSPokerTableListApi {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/gettablelist'-ScriptBlock {

        param (
			$inputArgs
		)

        try {

            # Load functions
            . $PSScriptRoot\DTSEndpointsCommon.ps1
            . $PSScriptRoot\DTSEndpointsPoker.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/poker/gettablelist" -Component "Get-DTSPokerTableListApi" -Type "Info"

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])

            # Call function to read all poker table files
            Write-DTSLog -Message "Load poker tables from file system" -Component "Get-DTSPokerTableListApi" -Type "Info"
            $_return_obj_list = Get-DTSPokerTableList -PokerBasePath $PokerBasePath
            Write-DTSLog -Message "Return data" -Component "Get-DTSPokerTableListApi" -Type "Info"
            if($null -eq $_return_obj_list) {
                $_return_obj_list = ""
            }
            Write-PodeJsonResponse -Value ($_return_obj_list | ConvertTo-Json)
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Get-DTSPokerTableListApi" Type="Error"
            $_poker_table_list_obj = New-Object -Type psobject
            $_poker_table_list_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get poker tables" -Force
            $_poker_table_list_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
            Write-PodeJsonResponse -Value ($_poker_table_list_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath}
}

function Add-DTSPokerTableApi {

    Add-PodeRoute -Method Post -Path '/api/v1/dts/poker/addtable'-ScriptBlock {

        param (
			$inputArgs
		)

        try {

            # Load functions
            . $PSScriptRoot\DTSEndpointsCommon.ps1
            . $PSScriptRoot\DTSEndpointsPoker.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/poker/createtable" -Component "Add-DTSPokerTable" -Type "Info"

            # Get URL based properties
            $PokerTableName = $WebEvent.Query['name']
            $PokerTableSecret = $WebEvent.Query['secret']
            $PokerTableOwnerSecret = $WebEvent.Query['ownersecret']
            $_poker_table_secret_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
            $_poker_table_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($PokerTableSecret)$($_poker_table_secret_salt)")) -Algorithm SHA256).Hash
            $_poker_table_owner_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($PokerTableOwnerSecret)$($_poker_table_secret_salt)")) -Algorithm SHA256).Hash
            $_poker_table_guid = [guid]::NewGuid().ToString()

            Write-DTSLog -Message="Requested table name ""$PokerTableName""" -Component "Add-DTSPokerTableApi" -Type "Info"

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])

            # Initialize json variable which we will return
            $_poker_table_json=$null

            # Check if table with same name already exist
            Write-DTSLog -Message "Check if poker table exist" -Component "Add-DTSPokerTableApi" -Type "Info"
            $_poker_table_obj = (Get-DTSPokerTable -PokerBasePath $PokerBasePath -PokerTableName $PokerTableName)

            if($null -eq $_poker_table_obj -or "" -eq $_poker_table_obj) {

                # Create a powershell object with new table
                Write-DTSLog -Message "Table doesn't exist -> create new file" -Component "Add-DTSPokerTableApi" -Type "Info"

                $_poker_table_creation_timestamp = Get-Date -format "yyyy-MM-dd HH:MM"

                $_poker_table_obj = New-Object -Type psobject
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableId" -Value $_poker_table_guid -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value $PokerTableName -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableSecret" -Value $_poker_table_secret_hash -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableOwnerSecret" -Value $_poker_table_owner_secret_hash -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableSalt" -Value $_poker_table_secret_salt -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableTimestamp" -Value $_poker_table_creation_timestamp -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableEstimationMethod" -Value "fibonacci_classic"-Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableParticipants" -Value $_poker_table_participants -Force

                # Convert to json and save to file
                Write-DTSLog -Message "Save file" -Component "Add-DTSPokerTableApi" -Type "Info"
                $_poker_table_json = ($_poker_table_obj | ConvertTo-Json)

                # TODO: Move to central save function
                $_poker_table_json | Out-File -Append -Encoding UTF8 -FilePath "$PokerBasePath\$_poker_table_guid.json"
            } else {
                # Table already exist
                Write-DTSLog -Message "Poker table ""$PokerTableName"" already exist" -Component "Add-DTSPokerTableApi" -Type "Info"
            }

            # format object
            $_poker_table_obj = Format-DTSPokerTable -PokerTable $_poker_table_obj -PokerTableSecret $PokerTableSecret

        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Add-DTSPokerTableApi" -Type "Error"
            $_poker_table_obj = New-Object -Type psobject
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to create table" -Force
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
        } finally {
            #return object to requester
            Write-PodeJsonResponse -Value ($_poker_table_obj | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath}
}

function Get-DTSPokerTableApi {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/gettable'-ScriptBlock {

        param (
			$inputArgs
		)

        $_poker_table = $null

        try {

            # Load functions
            . $PSScriptRoot\DTSEndpointsCommon.ps1
            . $PSScriptRoot\DTSEndpointsPoker.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/poker/gettable" -Component "Get-DTSPokerTableApi" -Type "Info"

            # Get URL based properties
            $PokerTableName = $WebEvent.Query['name']
            $PokerTableId = $WebEvent.Query['id']
            $PokerTableSecret = $WebEvent.Query['secret']

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])
            Write-DTSLog -Message "Requested table with name ""$PokerTableName"" and id ""$PokerTableId""" -Component "Get-DTSPokerTableApi" -Type "Info"

            # Get poker table
            $_poker_table = Get-DTSPokerTable -PokerBasePath $PokerBasePath -PokerTableId $PokerTableId -PokerTableName $PokerTableName -PokerTableSecret $PokerTableSecret
        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Get-DTSPokerTableApi" -Type "Error"
            $_poker_table = New-Object -Type psobject
            $_poker_table | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to get the requested table" -Force
            $_poker_table | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force

        } finally {
            # return to requester
            Write-PodeJsonResponse -Value ($_poker_table | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath}
}

function Register-DTSPokerTableParticipantApi {

    Add-PodeRoute -Method Put -Path '/api/v1/dts/poker/registerparticipant'-ScriptBlock {

        param (
			$inputArgs
		)

        $_poker_table = $null

        try {

            # Load functions
            . $PSScriptRoot\DTSEndpointsCommon.ps1
            . $PSScriptRoot\DTSEndpointsPoker.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/poker/registerparticipant" -Component "Register-DTSPokerTableParticipantApi" -Type "Info"

            # Get URL based properties
            $PokerTableName = $WebEvent.Query['name']
            $PokerTableId = $WebEvent.Query['id']
            $PokerTableSecret = $WebEvent.Query['secret']
            $PokerTableParticipant = $WebEvent.Query['participant']

            if([string]::IsNullOrEmpty($PokerTableName) -and [string]::IsNullOrEmpty($PokerTableId)) {
                throw "No poker table name or Id given"
            }

            if([string]::IsNullOrEmpty($PokerTableParticipant)) {
                throw "No poker table participant given"
            }

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])
            Write-DTSLog -Message "Register participant ""$PokerTableParticipant"" to join table with name ""$PokerTableName"" and id ""$PokerTableId""" -Component "Register-DTSPokerTableParticipantApi" -Type "Info"

            # Get poker table
            $_poker_table = Get-DTSPokerTable -PokerBasePath $PokerBasePath -PokerTableId $PokerTableId -PokerTableName $PokerTableName -PokerTableSecret $PokerTableSecret
            if([bool]($_poker_table.PSobject.Properties.name -match "pokerTableParticipants") -eq $true) {
                Write-DTSLog -Message "Found poker table with Id $($_poker_table.pokerTableId)" -Component "Register-DTSPokerTableParticipantApi" -Type "Info"
            } else {
                throw "You are not permitted to join table with Id $($_poker_table.pokerTableId)"
            }

            if($null -eq $_poker_table.pokerTableParticipants) {
                Write-DTSLog -Message "No participants in object, initialize array" -Component "Register-DTSPokerTableParticipantApi" -Type "Info"
                $_poker_table_participants = @()
                $_poker_table.pokerTableParticipants = $_poker_table_participants
            }

            # Add participant to poker table
            if(-Not ($_poker_table.pokerTableParticipants.Contains($PokerTableParticipant))) {
                Write-DTSLog -Message "Participant ""$PokerTableParticipant"" not in list, add it" -Component "Register-DTSPokerTableParticipantApi" -Type "Info"
                $_poker_table.pokerTableParticipants += $PokerTableParticipant
            } else {
                Write-DTSLog -Message "Participant ""$PokerTableParticipant"" is already in list" -Component "Register-DTSPokerTableParticipantApi" -Type "Info"
            }

            # Save poker table to filesystem
            # TODO: Move to central save function
            Write-DTSLog -Message "Save table to file" -Component "Register-DTSPokerTableParticipantApi" -Type "Info"
            Save-DTSPokerTable -PokerBasePath $PokerBasePath -PokerTable $_poker_table

        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Register-DTSPokerTableParticipantApi" -Type "Error"
            $_poker_table = New-Object -Type psobject
            $_poker_table | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to register participant to table" -Force
            $_poker_table | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
        }
        finally {
            # return table to requester
            Write-PodeJsonResponse -Value ($_poker_table | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath}
}

function Unregister-DTSPokerTableParticipantApi {

    Add-PodeRoute -Method Put -Path '/api/v1/dts/poker/unregisterparticipant'-ScriptBlock {

        param (
			$inputArgs
		)

        $_poker_table = $null

        try {

            # Load functions
            . $PSScriptRoot\DTSEndpointsCommon.ps1
            . $PSScriptRoot\DTSEndpointsPoker.ps1

            Write-DTSLog -Message "Got incoming request on path /api/v1/dts/poker/unregisterparticipant" -Component "Unregister-DTSPokerTableParticipantApi" -Type "Info"

            # Get URL based properties
            $PokerTableName = $WebEvent.Query['name']
            $PokerTableId = $WebEvent.Query['id']
            $PokerTableSecret = $WebEvent.Query['secret']
            $PokerTableParticipant = $WebEvent.Query['participant']

            if([string]::IsNullOrEmpty($PokerTableName) -and [string]::IsNullOrEmpty($PokerTableId)) {
                throw "No poker table name or Id given"
            }

            if([string]::IsNullOrEmpty($PokerTableParticipant)) {
                throw "No poker table participant given"
            }

            # Get properties from input args
            $PokerBasePath = $($inputArgs["PokerBasePath"])
            Write-DTSLog -Message "Unregister participant ""$PokerTableParticipant"" asked from table with name ""$PokerTableName"" and id ""$PokerTableId""" -Component "Unregister-DTSPokerTableParticipantApi" -Type "Info"

            # Get poker table
            $_poker_table = Get-DTSPokerTable -PokerBasePath $PokerBasePath -PokerTableId $PokerTableId -PokerTableName $PokerTableName -PokerTableSecret $PokerTableSecret
            Write-DTSLog -Message "Found poker table with Id $($_poker_table.pokerTableId)" -Component "Unregister-DTSPokerTableParticipantApi" -Type "Info"

            if($null -eq $_poker_table.pokerTableParticipants) {
                Write-DTSLog -Message "No participants in object, initialize array" -Component "Unregister-DTSPokerTableParticipantApi" -Type "Info"
                $_poker_table_participants = @()
                $_poker_table.pokerTableParticipants = $_poker_table_participants
            }

            # Add participant to poker table
            if(-Not ($_poker_table.pokerTableParticipants.Contains($PokerTableParticipant))) {
                Write-DTSLog -Message "Participant ""$PokerTableParticipant"" not in list" -Component "Unregister-DTSPokerTableParticipantApi" -Type "Info"
            } else {
                Write-DTSLog -Message "Participant ""$PokerTableParticipant"" is in list. Remove it" -Component "Unregister-DTSPokerTableParticipantApi" -Type "Info"
                $_poker_table.pokerTableParticipants -= $PokerTableParticipant
            }

            # Save poker table to filesystem
            # TODO: Move to central save function
            Write-DTSLog -Message "Save table to file" -Component "Unregister-DTSPokerTableParticipantApi" -Type "Info"
            Save-DTSPokerTable -PokerBasePath $PokerBasePath -PokerTable $_poker_table

        }
        catch {
            Write-DTSLog -Message "$($_.Exception.Message)" -Component "Unregister-DTSPokerTableParticipantApi" -Type "Error"
            $_poker_table = New-Object -Type psobject
            $_poker_table | Add-Member -MemberType NoteProperty -Name "Exception" -Value "Failed to unregister participant from table" -Force
            $_poker_table | Add-Member -MemberType NoteProperty -Name "Message" -Value $($_.Exception.Message) -Force
        }
        finally {
            # return table to requester
            Write-PodeJsonResponse -Value ($_poker_table | ConvertTo-Json)
        }
    } -ArgumentList @{"PokerBasePath" = $script:_poker_base_bath}
}

function Get-DTSPokerTable {
    [CmdletBinding()]
    param (
        [string]$PokerBasePath,
        [string]$PokerTableName,
        [string]$PokerTableId,
        [string]$PokerTableSecret
    )

    [PSCustomObject]$_poker_table = $null

    # Prefer to get the table by the id
    if(-Not [string]::IsNullOrEmpty($PokerTableId)) {
        Write-DTSLog -Message "Get table by ID" -Component "Get-DTSPokerTable" -Type "Info"

        foreach($_poker_file in (Get-ChildItem -Path "$PokerBasePath" | Where-Object { $_.Name -like "*.json" } )) {
            try {

                if($($_poker_file.Name) -eq "$($PokerTableId).json") {
                    Write-DTSLog -Message "Found file $($PokerTableId).json with matching table Id" -Component "Get-DTSPokerTable" -Type "Info"
                    $_poker_table_obj = (Get-Content -Path "$PokerBasePath\$($_poker_file.Name)" -Raw) | ConvertFrom-Json
                    $_poker_table = Format-DTSPokerTable -PokerTable $_poker_table_obj -PokerTableSecret $PokerTableSecret
                }
            } catch {
                Write-Output "$_.Exception.Message"
                Write-DTSLog -Message "Failed to get data for table file $_poker_file" -Component "Get-DTSPokerTable" -Type "Info"
            }
        }

    # Get the table by its name
    } elseif (-Not [string]::IsNullOrEmpty($PokerTableName)) {
        Write-DTSLog -Message "Execute Get-DTSPokerTableList to get table by name" -Component "Get-DTSPokerTable" -Type "Info"
        $_poker_table = Get-DTSPokerTableList -PokerBasePath $PokerBasePath -PokerTableSecret $PokerTableSecret -PokerTableName $PokerTableName

    # Neither ID or table name is given -> exit
    } else {
        throw "Table ""Id"" (prefered) or ""name"" must be given"
    }

    # Report that no object was found
    if($null -eq $_poker_table) {
        Write-DTSLog -Message "No table found" -Component "Get-DTSPokerTable" -Type "Info"
    }

    return $_poker_table
}

function Get-DTSPokerTableList {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$PokerBasePath,
        [string]$PokerTableSecret,
        [string]$PokerTableName
    )

    # Initialize array variable which we will return
    $_return_obj_list = @()

    foreach($_poker_file in (Get-ChildItem -Path "$PokerBasePath" | Where-Object { $_.Name -like "*.json" } )) {
        Write-DTSLog -Message "Found file ""$($_poker_file.Name)""" -Component "Get-DTSPokerTableList" -Type "Info"
        try {
            $_poker_table_obj = (Get-Content -Path "$PokerBasePath\$($_poker_file.Name)" -Raw) | ConvertFrom-Json

            if(-not ([string]::IsNullOrEmpty($PokerTableName))) {
                Write-DTSLog -Message "Filter with ""$PokerTableName"" on poker table name ""$($_poker_table_obj.pokerTableName)""" -Component "Get-DTSPokerTableList" -Type "Info"
                if($($_poker_table_obj.pokerTableName) -eq $PokerTableName) {
                    $_poker_table_obj = Format-DTSPokerTable -PokerTable $_poker_table_obj -PokerTableSecret $PokerTableSecret
                    $_return_obj_list += $_poker_table_obj
                    break;
                }
            } else {
                $_poker_table_obj = Format-DTSPokerTable -PokerTable $_poker_table_obj -PokerTableSecret $PokerTableSecret
                $_return_obj_list += $_poker_table_obj
            }

        } catch {
            Write-Output "$_.Exception.Message"
            Write-DTSLog -Message "Failed to get data for table file $_poker_file in ""Get-DTSPokerTableList"". Details: $($_.Exception.Message)" -Component "Get-DTSPokerTableList" -Type "Info"
        }
    }

    return $_return_obj_list
}

function Format-DTSPokerTable {

    [CmdletBinding()]
    param (
        $PokerTable,
        [string]$PokerTableSecret
    )

    # Do not anything when nothing is give
    if([string]::IsNullOrEmpty($PokerTable)) {
        return $PokerTable
    }

    # Ignore outdated poker tables
    if($($PokerTable.pokerTableTimestamp) -lt (Get-Date).AddDays(-1)) {
        Write-DTSLog -Message "Poker table ""$($PokerTable.pokerTableName)"" outdated. Ignore it." -Component "Format-DTSPokerTable" -Type "Info"
        return $null
    }

    $_poker_table_authenticated = $false

    # Authenticate when a password is given (otherwise will create a minimal object)
    if(-Not [string]::IsNullOrEmpty($PokerTableSecret)) {
        Write-DTSLog -Message "Try to authenticate against the poker table" -Component "Format-DTSPokerTable" -Type "Info"
        $_poker_table_authenticated = Grant-DTSTableAccess -PokerTable $PokerTable -PokerTableSecret $PokerTableSecret
    }

    # Authenticated, return full object (without secrets)
    if($_poker_table_authenticated) {
        Write-DTSLog -Message "Return full object" -Component "Format-DTSPokerTable" -Type "Info"
        $_poker_table_obj = $PokerTable
        $_poker_table_obj.PSObject.Properties.Remove("pokerTableSalt")
        $_poker_table_obj.PSObject.Properties.Remove("pokerTableSecret")
        $_poker_table_obj.PSObject.Properties.Remove("pokerTableOwnerSecret")

    # Not authenticated, create the minimal object
    } else {
        Write-DTSLog -Message "Return minimal object" -Component "Format-DTSPokerTable" -Type "Info"
        $_poker_table_obj = New-Object -Type psobject
        $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableId" -Value $PokerTable.pokerTableId -Force
        $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value $PokerTable.pokerTableName -Force
        $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableTimestamp" -Value $PokerTable.pokerTableTimestamp -Force
    }
    return $_poker_table_obj
}

function Grant-DTSTableAccess {

    [OutputType([bool])]

    [CmdletBinding()]
    param (
        $PokerTable,
        [string]$PokerTableSecret
    )

    # Do not anything when nothing is give
    if([string]::IsNullOrEmpty($PokerTable)) {
        return $false
    }

    # Create the hash value from given secret
    Write-DTSLog -Message "Create hash from given secret" -Component "Grant-DTSTableAccess" -Type "Info"
    $_poker_table_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($PokerTableSecret)$($PokerTable.pokerTableSalt)")) -Algorithm SHA256).Hash
    $PokerTableSecret = $null

    if($_poker_table_secret_hash -ne $($PokerTable.pokerTableSecret)) {
        Write-DTSLog -Message "Secret did not match" -Component "Grant-DTSTableAccess" -Type "Info"
        return $false
    }

    Write-DTSLog -Message "Secret OK" -Component "Grant-DTSTableAccess" -Type "Info"
    return $true
}

function Save-DTSPokerTable {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$PokerBasePath,
        $PokerTable
    )

    try {

        foreach($_poker_file in (Get-ChildItem -Path "$PokerBasePath" | Where-Object { $_.Name -like "*.json" } )) {

            if($($_poker_file.Name) -eq "$($PokerTable.pokerTableId).json") {

                $_poker_table_obj = (Get-Content -Path "$PokerBasePath\$($_poker_file.Name)" -Raw) | ConvertFrom-Json

                Write-DTSLog -Message "Update estimation method" -Component "Save-DTSPokerTable" -Type "Info"
                $_poker_table_obj.pokerTableEstimationMethod = $PokerTable.pokerTableEstimationMethod
                Write-DTSLog -Message "Update participants" -Component "Save-DTSPokerTable" -Type "Info"
                $_poker_table_obj.pokerTableParticipants = $PokerTable.pokerTableParticipants

                # Convert to json and save to file
                Write-DTSLog -Message "Save file" -Component "Save-DTSPokerTable" -Type "Info"
                $_poker_table_json = ($_poker_table_obj | ConvertTo-Json)
                $_poker_table_json | Out-File -Encoding UTF8 -FilePath "$PokerBasePath\$($_poker_file.Name)"

                break;
            }
        }
    } catch {
        Write-Output "$_.Exception.Message"
        Write-DTSLog -Message "Failed to save data for table file $_poker_file" -Component "Save-DTSPokerTable" -Type "Info"
    }

}