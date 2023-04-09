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
$script:_poker_base_bath = $null

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

$script:_poker_base_bath = "$script:_endpoint_config_base_path\$script:_endpoint_config_folder\$script:_endpoint_folder\user"
if (-Not (Test-Path "$script:_poker_base_bath")) {
    New-Item -Path "$script:_poker_base_bath" -ItemType Directory | Out-Null
}
Write-DTCLog "Initialized data path ""$script:_poker_base_bath""" -Component "DTSEndpointsUser"
