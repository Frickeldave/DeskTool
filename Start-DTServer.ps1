if (Get-Module DeskToolServer) { 
    Remove-Module DeskToolServer -Force
}

if (-Not (Test-Path $env:LOCALAPPDATA\DeskToolServer)) {
    New-Item -Path $env:LOCALAPPDATA\DeskToolServer -ItemType Directory | Out-Null
}

Copy-Item -Path "$PSScriptRoot\DeskToolServer\*" -Destination "$env:LOCALAPPDATA\DeskToolServer" -Recurse -Force

Import-Module "$env:LOCALAPPDATA\DeskToolServer\DeskTool.psd1" -Force
Start-DeskToolServer
