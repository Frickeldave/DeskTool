$AppName = "DeskTool"

if (Get-Module DeskTool) { 
    Remove-Module DeskTool -Force
}

if (-Not (Test-Path $env:LOCALAPPDATA\DeskTool)) {
    New-Item -Path $env:LOCALAPPDATA\DeskTool -ItemType Directory | Out-Null
}

Copy-Item -Path "$PSScriptRoot\DeskTool\*" -Destination "$env:LOCALAPPDATA\$AppName" -Recurse -Force

Import-Module "$env:LOCALAPPDATA\DeskTool\DeskTool.psd1" -Force
Start-DeskTool
