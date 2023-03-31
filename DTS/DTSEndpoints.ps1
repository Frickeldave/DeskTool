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
    
    Add-PodeRoute -Method Get -Path '/api/v1/dts/poker/gettable' -ScriptBlock {

        Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/poker/gettable"; Component="Get-DTSEndpointPokerGetTable"; Type="Info"}

        $_return = New-Object -Type psobject
        $_return | Add-Member -MemberType NoteProperty -Name "pokerTableName" -Value "Wurschtsemmel" -Force
        Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
    }
}