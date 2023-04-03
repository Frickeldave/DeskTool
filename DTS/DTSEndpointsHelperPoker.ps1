function Get-DTSEndpointHelperPokerGetTableList {
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
            $_poker_table_json=(Get-Content -Path "$PokerBasePath\$_poker_file" -Raw) | ConvertFrom-Json

            if([datetime]$_poker_table_json.pokerTableTimestamp -lt (Get-Date).AddDays(-1)) {
                Write-PodeLog -Name "log" -InputObject @{Message="Poker table file ""$_poker_file"" outdated. Ignore it."; Component="Get-DTSEndpointHelperPokerGetTableList"; Type="Info"}
            } else {
                Write-PodeLog -Name "log" -InputObject @{ Message="Get data for table file $_poker_file"; Component="Get-DTSEndpointHelperPokerGetTableList"; Type="Info" }
                $_poker_table_obj = New-Object -Type psobject
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableId" -Value $_poker_table_json.pokerTableId -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value $_poker_table_json.pokerTableName -Force
                $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableTimestamp" -Value $_poker_table_json.pokerTableTimestamp -Force
                if($Full) {
                    $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTablePassword" -Value $_poker_table_json.pokerTablePassword -Force
                    $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableSalt" -Value $_poker_table_json.pokerTableSalt -Force
                }
                $_return_obj_list += $_poker_table_obj
            }
        } catch {
            Write-Output "$_.Exception.Message"
            Write-PodeLog -Name "log" -InputObject @{ Message="Failed to get data for table file $_poker_file"; Component="Get-DTSEndpointHelperPokerGetTableList"; Type="Info" }
        }
    }

    return $_return_obj_list
}

function Get-DTSEndpointHelperPokerGetTableByName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$PokerBasePath,
        [Parameter()]
        [string]$PokerTableName,
        [switch]$Full
    )   

    Write-PodeLog -Name "log" -InputObject @{Message="Execute Get-DTSEndpointHelperPokerGetTableList"; Component="Get-DTSEndpointHelperPokerGetTableByName"; Type="Info"}
    $_poker_table_list = Get-DTSEndpointHelperPokerGetTableList -PokerBasePath $PokerBasePath -Full:$Full

    foreach($_poker_table in $_poker_table_list) {
        if($_poker_table.pokerTableName -eq $PokerTableName) {
            Write-PodeLog -Name "log" -InputObject @{Message="Found table with id $($_poker_table.pokerTableId)"; Component="Get-DTSEndpointHelperPokerGetTableByName"; Type="Info"}
            return $_poker_table
        }
    }
    
    Write-PodeLog -Name "log" -InputObject @{Message="No table found"; Component="Get-DTSEndpointHelperPokerGetTableByName"; Type="Info"}
    return $null
}

function Get-DTSEndpointHelperPokerGetTableById {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$PokerBasePath,
        [Parameter()]
        [string]$PokerTableId,
        [switch]$Full
    )   

    Write-PodeLog -Name "log" -InputObject @{Message="Execute Get-DTSEndpointHelperPokerGetTableList"; Component="Get-DTSEndpointHelperPokerGetTableById"; Type="Info"}
    $_poker_table_list = Get-DTSEndpointHelperPokerGetTableList -PokerBasePath $PokerBasePath -Full:$Full

    foreach($_poker_table in $_poker_table_list) {
        if($_poker_table.pokerTableId -eq $PokerTableId) {
            Write-PodeLog -Name "log" -InputObject @{Message="Found table with name $($_poker_table.pokerTableName)"; Component="Get-DTSEndpointHelperPokerGetTableById"; Type="Info"}
            return $_poker_table
        }
    }
    
    Write-PodeLog -Name "log" -InputObject @{Message="No table found"; Component="Get-DTSEndpointHelperPokerGetTableById"; Type="Info"}
    return $null
}