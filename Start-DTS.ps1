[CmdletBinding()]
param (
    [Parameter()]
    [switch]$InitData,
    [switch]$Async,
    [switch]$RunTests
)

# Normally the directory %ProgramData%\Frickeldave\DTS is used. In case of a test (where everything is deleted)
# we create a dedicated directory to prevent the deletion of potential productively used data. 
$_target_app_name = $(if($RunTests) { "DTS-Test" } else { "DTS" })

# Specify the target directory for the installation
$_target_dir = "$($env:ProgramData)\Frickeldave\$_target_app_name"

# The version of pester is used for tests
$_pester_version = "5.4.1"

# Import some helper functions
. $PSScriptRoot\Start-Helper.ps1

try {

    # Remove existing directory in case of a TEST
    if($RunTests) {
        if(Test-Path "$_target_dir") { Remove-Item "$_target_dir" -Recurse }
    }

    # Create target directory if it not exist
    if (-Not (Test-Path $_target_dir)) { New-Item -Path $_target_dir -ItemType Directory | Out-Null  }

    # Remove module first to get the newest version in session
    if (Get-Module DTS) { 
        Remove-Module DTS -Force
    }

    # Copy all needed files into target directory
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTS.psd1" -TargetFile "$_target_dir\DTS.psd1" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTS.psm1" -TargetFile "$_target_dir\DTS.psm1" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSConfig.ps1" -TargetFile "$_target_dir\DTSConfig.ps1" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSLog.ps1" -TargetFile "$_target_dir\DTSLog.ps1" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSConfig.json" -TargetFile "$_target_dir\DTSConfig.json" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSUserAPI.ps1" -TargetFile "$_target_dir\DTSUserAPI.ps1" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSUserDB.ps1" -TargetFile "$_target_dir\DTSUserDB.ps1" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTS\DTSCommonAPI.ps1" -TargetFile "$_target_dir\DTSCommonAPI.ps1" -Test:$RunTests

    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCConfig.ps1" -TargetFile "$_target_dir\DTCConfig.ps1" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCHelper.ps1" -TargetFile "$_target_dir\DTCHelper.ps1" -Test:$RunTests
    Install-DTFile -SourceFile "$PSScriptRoot\DTC\DTCLog.ps1" -TargetFile "$_target_dir\DTCLog.ps1" -Test:$RunTests
   
    # Copy initial data
    if($InitData) {
        
        # Copy user testdata
        if (-Not (Test-Path "$_target_dir\data\db\user")) { New-Item -Path "$_target_dir\data\db\user" -ItemType Directory | Out-Null  }
        Copy-Item -Path "$PSScriptRoot\DTS\Testdata\User\*.json" -Destination "$_target_dir\data\db\user"
    }

    if($Async) { 
        # Stop previously created and running jobs
        if (-not ($null -eq (Get-Job -Name "$_target_app_name" -ErrorAction SilentlyContinue))) { 
            Get-Job -Name "$_target_app_name" | Where-Object { $_.State -eq "Completed" } | Stop-Job
            Get-Job -Name "$_target_app_name" | Remove-Job -Force
        }

        Start-Job -Name "$_target_app_name" -ScriptBlock {
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
    } else {
        # Start process in foreground
        Import-Module "$_target_dir\DTS.psd1" -Force
        Initialize-DTS
    }

    if($RunTests) {
        Import-DTModule -ModuleName "Pester" -ModuleVersion "$_pester_version"

        Invoke-Pester $PSScriptRoot\DTS\DTS.Tests.ps1
        Invoke-Pester $PSScriptRoot\DTS\DTSUser.Tests.ps1
    }

}  catch {
    Write-Host "Exception in Start-DTS"
    "$($_.Exception.Message)" | Out-Host
}