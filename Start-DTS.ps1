if (Get-Module DTS) { 
    Remove-Module DTS -Force
}
$_target_dir = "$env:ProgramData\Frickeldave\DTS"

if (-Not (Test-Path $_target_dir)) {
    New-Item -Path $_target_dir -ItemType Directory | Out-Null
}

Copy-Item -Path "$PSScriptRoot\DTS\DTS.psd1" -Destination "$_target_dir\DTS.psd1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTS.psm1" -Destination "$_target_dir\DTS.psm1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSConfig.ps1" -Destination "$_target_dir\DTSConfig.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSConfig.json" -Destination "$_target_dir\DTSConfig.json" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSEndpointsPoker.ps1" -Destination "$_target_dir\DTSEndpointsPoker.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSEndpointsPokerHelper.ps1" -Destination "$_target_dir\DTSEndpointsPokerHelper.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSEndpointsUser.ps1" -Destination "$_target_dir\DTSEndpointsUser.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSEndpointsUserHelper.ps1" -Destination "$_target_dir\DTSEndpointsUserHelper.ps1" -Recurse -Force

Copy-Item -Path "$PSScriptRoot\DTC\DTCConfig.ps1" -Destination "$_target_dir\DTCConfig.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTC\DTCHelper.ps1" -Destination "$_target_dir\DTCHelper.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTC\DTCLog.ps1" -Destination "$_target_dir\DTCLog.ps1" -Recurse -Force

Import-Module "$_target_dir\DTS.psd1" -Force
Start-DTS
