[CmdletBinding()]
param (
    [Parameter()]
    [switch]$Test
)

. $PSScriptRoot\Start-Helper.ps1

try {
    if (Get-Module DTS) { 
        Remove-Module DTS -Force
    }

    $_target_dir = "$env:ProgramData\Frickeldave\DTS"
    
    if($Test) {

        # Stop previously created and running test jobs
        if (-not ($null -eq (Get-Job -Name "Start-DTS-Pester" -ErrorAction SilentlyContinue))) { 
            Get-Job -Name "Start-DTS-Pester" | Where-Object { $_.State -eq "Completed" } | Stop-Job
            Get-Job -Name "Start-DTS-Pester" | Remove-Job -Force
        }

        Import-SDTModule -ModuleName "PSScriptAnalyzer" -ModuleVersion "1.21.0"

        $_target_dir = "$env:ProgramData\Frickeldave\DTS-Pester"
        if(Test-Path $env:ProgramData\Frickeldave\DTS-Pester) {
            Remove-Item $env:ProgramData\Frickeldave\DTS-Pester -Recurse
        }
    }

    if (-Not (Test-Path $_target_dir)) {
        New-Item -Path $_target_dir -ItemType Directory | Out-Null
    }

    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTS.psd1" -TargetFile "$_target_dir\DTS.psd1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTS.psm1" -TargetFile "$_target_dir\DTS.psm1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSConfig.ps1" -TargetFile "$_target_dir\DTSConfig.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSConfig.json" -TargetFile "$_target_dir\DTSConfig.json" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSEndpointsCommon.ps1" -TargetFile "$_target_dir\DTSEndpointsCommon.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSEndpointsPoker.ps1" -TargetFile "$_target_dir\DTSEndpointsPoker.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSEndpointsPokerHelper.ps1" -TargetFile "$_target_dir\DTSEndpointsPokerHelper.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSEndpointsUser.ps1" -TargetFile "$_target_dir\DTSEndpointsUser.ps1" -Test:$Test

    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCConfig.ps1" -TargetFile "$_target_dir\DTCConfig.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCHelper.ps1" -TargetFile "$_target_dir\DTCHelper.ps1" -Test:$Test
    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCLog.ps1" -TargetFile "$_target_dir\DTCLog.ps1" -Test:$Test
   
    $_api_job = Start-Job -Name "Start-DTS-Pester" -ScriptBlock {

        param (
			$inputArgs
		)
        $TargetDir = $($inputArgs["TargetDir"])
        
        Import-Module "$TargetDir\DTS.psd1" -Force
        Initialize-DTS -BasePathApp $TargetDir
    } -ArgumentList @{"TargetDir" = $_target_dir}
    
    if($Test) {
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

        Import-SDTModule -ModuleName "Pester" -ModuleVersion "5.4.1"

        Invoke-Pester $PSScriptRoot\DTS\DTSEndpointsCommon.Tests.ps1
        Invoke-Pester $PSScriptRoot\DTS\DTSEndpointsPoker.Tests.ps1
        Write-Host "Stop"
        #$_api_job.StopJob()
    }

}  catch {
    Write-Host "Exception in Start-DTS"
    "$($_.Exception.Message)" | Out-Host
    $_api_job.StopJob()
}