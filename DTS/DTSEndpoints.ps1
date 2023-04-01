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

    $script:_endpoint_config_base_path = $ConfigBasePath
    $script:_endpoint_config_folder = $ConfigFolder
    $script:_endpoint_folder = $EndpointFolder

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\$EndpointFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder\$EndpointFolder -ItemType Directory | Out-Null
    }
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

    if (-Not (Test-Path "$script:_endpoint_config_base_path\$script:_endpoint_config_folder\$script:_endpoint_folder\poker")) {
        New-Item -Path "$script:_endpoint_config_base_path\$script:_endpoint_config_folder\$script:_endpoint_folder\poker" -ItemType Directory | Out-Null
    }
    
    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/gettable' -ArgumentList @{_endpoint_config_base_path = $script:_endpoint_config_base_path; _endpoint_config_folder = $script:_endpoint_config_folder; _endpoint_folder = $script:_endpoint_folder} -ScriptBlock {

        Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/poker/gettable"; Component="Get-DTSEndpointPokerGetTable"; Type="Info"}

        $_poker_table_name = $WebEvent.Query['name']
        $_poker_table_password = $WebEvent.Query['password']

        Write-PodeLog -Name "log" -InputObject @{ Message="Requested table name: $_poker_table_name with password $_poker_table_password"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
        
        $_poker_table_json=$null

        Write-PodeLog -Name "log" -InputObject @{ Message="$_endpoint_config_base_path\$_endpoint_config_folder\$_endpoint_folder\poker\$_poker_table_name.json"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }

        if(Test-Path ("$_endpoint_config_base_path\$_endpoint_config_folder\$_endpoint_folder\poker\$_poker_table_name.json")) {
            
            Write-PodeLog -Name "log" -InputObject @{ Message="Table already exist"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }
            $_poker_table_json=(Get-Content -Path $InstanceConfig -Raw) | ConvertFrom-Json

        } else {
            Write-PodeLog -Name "log" -InputObject @{ Message="Table doesn't exist"; Component="Get-DTSEndpointPokerGetTable"; Type="Info" }

            $_poker_table_obj = New-Object -Type psobject
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value $_poker_table_name -Force
            $_poker_table_obj | Add-Member -MemberType NoteProperty -Name "pokerTablePassword" -Value $_poker_table_password -Force
            $_poker_table_json=Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
        }
        Write-PodeJsonResponse -Value ($_poker_table_json | ConvertTo-Json)
    }
}
