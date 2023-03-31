if (Get-Module DTS) { 
    Remove-Module DTS -Force
}

if (-Not (Test-Path $env:LOCALAPPDATA\Frickeldave\DTS)) {
    New-Item -Path $env:LOCALAPPDATA\Frickeldave\DTS -ItemType Directory | Out-Null
}

Copy-Item -Path "$PSScriptRoot\DTS\DTS.psd1" -Destination "$env:LOCALAPPDATA\Frickeldave\DTS\DTS.psd1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTS.psm1" -Destination "$env:LOCALAPPDATA\Frickeldave\DTS\DTS.psm1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSConfig.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DTS\DTSConfig.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSConfig.json" -Destination "$env:LOCALAPPDATA\Frickeldave\DTS\DTSConfig.json" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTS\DTSEndpoints.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DTS\DTSEndpoints.ps1" -Recurse -Force

Copy-Item -Path "$PSScriptRoot\DTC\DTCConfig.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DTS\DTCConfig.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTC\DTCHelper.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DTS\DTCHelper.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTC\DTCLog.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DTS\DTCLog.ps1" -Recurse -Force

Import-Module "$env:LOCALAPPDATA\Frickeldave\DTS\DTS.psd1" -Force
Start-DTS
