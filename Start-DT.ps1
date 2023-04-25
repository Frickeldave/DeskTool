[CmdletBinding()]
param (
    [Parameter()]
    [switch]$Test
)

. $PSScriptRoot\Start-Helper.ps1

try {
    # Remove module first to get the newest version in session
    if (Get-Module DT) { 
        Remove-Module DT -Force
    }

    $_target_dir = Add-DTTargetDir -BasePath "$($env:LOCALAPPDATA)\Frickeldave" -DirName "DT" -Test:$Test

    # Copy all needed files into target directory
    Install-DTFile -SourceFile "$PSScriptRoot\DT\DT.psd1" -TargetFile "$_target_dir\DT.psd1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DT\DT.psm1" -TargetFile "$_target_dir\DT.psm1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DT\DTConfig.ps1" -TargetFile "$_target_dir\DTConfig.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DT\DTConfig.json" -TargetFile "$_target_dir\DTConfig.json" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DT\DTHelper.ps1" -TargetFile "$_target_dir\DTHelper.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DT\DTPages.ps1" -TargetFile "$_target_dir\DTPages.ps1" -Test:$Test

    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCConfig.ps1" -TargetFile "$_target_dir\DTCConfig.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCHelper.ps1" -TargetFile "$_target_dir\DTCHelper.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCLog.ps1" -TargetFile "$_target_dir\DTCLog.ps1" -Test:$Test

    if(-not (Test-Path "$_target_dir\img")) { New-Item -Path "$_target_dir\img" -ItemType Directory -Force | Out-Null }
    Copy-Item -Path "$PSScriptRoot\DT\img\*" -Destination "$_target_dir\img" -Recurse -Force

    Import-Module "$_target_dir\DT.psd1" -Force
    Initialize-DT

} catch {
    Write-Host "Exception in Start-DT"
    "$($_.Exception.Message)" | Out-Host
}
