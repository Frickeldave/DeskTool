[CmdletBinding()]
param (
    [Parameter()]
    [switch]$Test
)

. $PSScriptRoot\Start-Helper.ps1

try {
    # Remove module first to get the newest version in session
    if (Get-Module DTS) { 
        Remove-Module DTS -Force
    }
    
    if($Test) { 
        $_target_dir = Add-DTTargetDir -BasePath "$($env:ProgramData)\Frickeldave\DTS-Test" -Test:$Test 
    } else {
        $_target_dir = Add-DTTargetDir -BasePath "$($env:ProgramData)\Frickeldave\DTS" -Test:$Test
    }

    # Copy all needed files into target directory
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTS.psd1" -TargetFile "$_target_dir\DTS.psd1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTS.psm1" -TargetFile "$_target_dir\DTS.psm1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSConfig.ps1" -TargetFile "$_target_dir\DTSConfig.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSLog.ps1" -TargetFile "$_target_dir\DTSLog.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSConfig.json" -TargetFile "$_target_dir\DTSConfig.json" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSUserAPI.ps1" -TargetFile "$_target_dir\DTSUserAPI.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSUserDB.ps1" -TargetFile "$_target_dir\DTSUserDB.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSCommonAPI.ps1" -TargetFile "$_target_dir\DTSCommonAPI.ps1" -Test:$Test

    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCConfig.ps1" -TargetFile "$_target_dir\DTCConfig.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCHelper.ps1" -TargetFile "$_target_dir\DTCHelper.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCLog.ps1" -TargetFile "$_target_dir\DTCLog.ps1" -Test:$Test
   

    if($Test) { 

        Get-Job -Name "DTS-Test" | Stop-Job
        Get-Job -Name "DTS-Test" | Remove-Job

 
        Start-Job -Name "DTS-Test" -ScriptBlock {
            param (
                $inputArgs
            )

            $TargetDir = $($inputArgs["TargetDir"])
            
            Import-Module "$TargetDir\DTS.psd1" -Force
            Initialize-DTS
        } -ArgumentList @{"TargetDir" = $_target_dir}
        
        # Wait until DTS is available
        $_api_status = "Invalid"
        $_api_status_count = 1
        
        # Do a 5-seconds loop in case the API tooks a while to start
        Do {
            try {
                $_api_status = Invoke-RestMethod -Method Get -Uri http://localhost:8082/api/v1/dts/status
            } catch { 
                $_api_status = "Invalid"
            }
            Start-Sleep 1

            $_api_status_count++
            if($_api_status_count -eq 6) {
                throw "API start timed out"
            }
        }
        while ($($_api_status.status) -ne "OK")
            Import-DTModule -ModuleName "Pester" -ModuleVersion "5.4.1"

            Invoke-Pester $PSScriptRoot\DTS\DTS.Tests.ps1
            Invoke-Pester $PSScriptRoot\DTS\DTSUser.Tests.ps1

    } else {
        # Start process in foreground
        Import-Module "$_target_dir\DTS.psd1" -Force
        Initialize-DTS
    }
}  catch {
    Write-Host "Exception in Start-DTS"
    "$($_.Exception.Message)" | Out-Host
}