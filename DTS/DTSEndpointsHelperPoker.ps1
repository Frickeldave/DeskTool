
function Format-DTSEndpointHelperPokerTable {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $PokerTable,
        [switch]$Full
    )

    # Do not anything when nothing is give
    if([string]::IsNullOrEmpty($PokerTable)) {
        return $PokerTable
    }

    if($($PokerTable.pokerTableTimestamp) -lt (Get-Date).AddDays(-1)) {
        Write-PodeLog -Name "log" -InputObject @{Message="Poker table ""$($PokerTable.pokerTableName)"" outdated. Ignore it."; Component="Format-DTSEndpointHelperPokerTable"; Type="Info"}
    } else {
        Write-PodeLog -Name "log" -InputObject @{ Message="Format data for table file ""$($PokerTable.pokerTableName)"""; Component="Format-DTSEndpointHelperPokerTable"; Type="Info" }
        $_poker_table_obj = New-Object -Type psobject
        $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableId" -Value $PokerTable.pokerTableId -Force
        $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value $PokerTable.pokerTableName -Force
        $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableTimestamp" -Value $PokerTable.pokerTableTimestamp -Force
        if($Full) {
            Write-PodeLog -Name "log" -InputObject @{ Message="Return full object"; Component="Format-DTSEndpointHelperPokerTable"; Type="Info" }
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableSecret" -Value $PokerTable.pokerTableSecret -Force
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableSalt" -Value $PokerTable.pokerTableSalt -Force
        }
        return $_poker_table_obj
    }
}
function Get-DTSEndpointHelperPokerTableList {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$PokerBasePath,
        [switch]$Full
    )

    # Initialize array variable which we will return
    $_return_obj_list = @()

    foreach($_poker_file in (Get-ChildItem -Path "$PokerBasePath" | Where-Object { $_.Name -like "*.json" } )) {
        try {
            $_poker_table_obj=(Get-Content -Path "$PokerBasePath\$_poker_file" -Raw) | ConvertFrom-Json
            $_return_obj_list += Format-DTSEndpointHelperPokerTable -PokerTable $_poker_table_obj -Full:$Full
        } catch {
            Write-Output "$_.Exception.Message"
            Write-PodeLog -Name "log" -InputObject @{ Message="Failed to get data for table file $_poker_file"; Component="Get-DTSEndpointHelperPokerTableList"; Type="Info" }
        }
    }

    return $_return_obj_list
}

function Get-DTSEndpointHelperPokerTable {
    [CmdletBinding()]
    param (
        [string]$PokerBasePath,
        [string]$PokerTableName,
        [string]$PokerTableId,
        [switch]$Full
    )   

    $_poker_table = $null

    # Prefer to get the table by the id
    if(-Not [string]::IsNullOrEmpty($PokerTableId)) {
        Write-PodeLog -Name "log" -InputObject @{ Message="Get table by ID"; Component="Get-DTSEndpointPokerTable"; Type="Info" }
        
        foreach($_poker_file in (Get-ChildItem -Path "$PokerBasePath" | Where-Object { $_.Name -like "*.json" } )) {
            try {
                if($_poker_file.Name -eq "$PokerTableId.json") {
                    $_poker_table_obj=(Get-Content -Path "$PokerBasePath\$_poker_file" -Raw) | ConvertFrom-Json
                    $_poker_table = Format-DTSEndpointHelperPokerTable -PokerTable $_poker_table_obj -Full:$Full
                }
            } catch {
                Write-Output "$_.Exception.Message"
                Write-PodeLog -Name "log" -InputObject @{ Message="Failed to get data for table file $_poker_file"; Component="Get-DTSEndpointHelperPokerTable"; Type="Info" }
            }
        }

    # Get the table by its name
    } elseif (-Not [string]::IsNullOrEmpty($PokerTableName)) {
        Write-PodeLog -Name "log" -InputObject @{Message="Execute Get-DTSEndpointHelperPokerTableList to get table by name"; Component="Get-DTSEndpointHelperPokerTable"; Type="Info"}
        $_poker_table_list = Get-DTSEndpointHelperPokerTableList -PokerBasePath $PokerBasePath -Full:$Full

        foreach($_table in $_poker_table_list) {
            if($_table.pokerTableName -eq $PokerTableName) {
                Write-PodeLog -Name "log" -InputObject @{Message="Found table with id $($_table.pokerTableName)"; Component="Get-DTSEndpointHelperPokerTable"; Type="Info"}
                $_poker_table = $_table
                break; # Get the first item and ignore all other results
            }
        }
    # Neither ID or table name is given -> exit
    } else {
        throw "Table ID (prefered) or name must be given"
    }

    # Report that no object was found 
    if($null -eq $_poker_table) {
        Write-PodeLog -Name "log" -InputObject @{Message="No table found"; Component="Get-DTSEndpointHelperPokerGetTable"; Type="Info"}
    }

    if($null -eq $_poker_table) {
        return ""
    } else {
        return $_poker_table
    }
}

function Grant-DTSEndpointPokerTableAccess {

    [CmdletBinding()]
    param (
        $PokerTable,
        [string]$PokerTableSecret
    )

    # Do not anything when nothing is give
    if([string]::IsNullOrEmpty($PokerTable)) {
        return $PokerTable
    }

    # Create the hash value form given secret
    Write-PodeLog -Name "log" -InputObject @{ Message="Create hash from given secret"; Component="Grant-DTSEndpointPokerTableAccess"; Type="Info" }
    $_poker_table_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($PokerTableSecret)$($PokerTable.pokerTableSalt)")) -Algorithm SHA256).Hash
    $PokerTableSecret = $null
    $_poker_table_authenticated = $false

    if($_poker_table_secret_hash -ne $($PokerTable.pokerTableSecret)) {
        Write-PodeLog -Name "log" -InputObject @{ Message="Secret did not match"; Component="Grant-DTSEndpointPokerTableAccess"; Type="Info" }
    } else {
        Write-PodeLog -Name "log" -InputObject @{ Message="Secret OK"; Component="Grant-DTSEndpointPokerTableAccess"; Type="Info" }
        $_poker_table_authenticated = $true
    }
    return $_poker_table_authenticated
}