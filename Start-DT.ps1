if (Get-Module DeskTool) { 
    Remove-Module DeskTool -Force
}

if (-Not (Test-Path $env:LOCALAPPDATA\Frickeldave\DT)) {
    New-Item -Path $env:LOCALAPPDATA\Frickeldave\DT -ItemType Directory | Out-Null
}

Copy-Item -Path "$PSScriptRoot\DT\DT.psd1" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DT.psd1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DT\DT.psm1" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DT.psm1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DT\DTConfig.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DTConfig.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DT\DTConfig.json" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DTConfig.json" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DT\DTHelper.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DTHelper.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DT\DTPages.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DTPages.ps1" -Recurse -Force

if(-not (Test-Path "$env:LOCALAPPDATA\Frickeldave\DT\img")) { New-Item -Path "$env:LOCALAPPDATA\Frickeldave\DT\img" -ItemType Directory -Force | Out-Null }
Copy-Item -Path "$PSScriptRoot\DT\img\*" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\img" -Recurse -Force

Copy-Item -Path "$PSScriptRoot\DTC\DTCConfig.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DTCConfig.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTC\DTCHelper.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DTCHelper.ps1" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\DTC\DTCLog.ps1" -Destination "$env:LOCALAPPDATA\Frickeldave\DT\DTCLog.ps1" -Recurse -Force

Import-Module "$env:LOCALAPPDATA\Frickeldave\DT\DT.psd1" -Force
Start-DT
