function Install-DTFile {
    [CmdletBinding()]
    param (
        [string]$SourceFile,
        [string]$TargetFile,
        [switch]$Test
    )

    if($Test) {
        
        $_sa_test_result = Invoke-ScriptAnalyzer "$SourceFile"
        if(-not ($null -eq $_sa_test_result)) {
            $_sa_test_result
            throw "Script analyzer failed for script ""$SourceFile""."
        }
    }

    Copy-Item -Path "$SourceFile" -Destination "$TargetFile" -Recurse -Force
}

function Import-DTModule {
    [CmdletBinding()]
    param (
        [string]$ModuleName,
        [string]$ModuleVersion
    )

    # Check if module is installed
    if (-Not ((Get-Module -ListAvailable -Name $ModuleName).Version -eq $ModuleVersion)) {

        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Scope CurrentUser
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
    }

    # Check if module is imported
    if (-Not ((Get-Module -Name $ModuleName).Version -eq $ModuleVersion)) {
        Import-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Scope Local
    } 
}

function Add-DTTargetDir {
    
    [CmdletBinding()]
    param (
        [switch]$Test,
        [string]$DirName
    )

    $_target_dir = "$env:ProgramData\Frickeldave\$DirName"
    
    if($Test) {

        # Stop previously created and running test jobs
        if (-not ($null -eq (Get-Job -Name "Start-DTS-Pester" -ErrorAction SilentlyContinue))) { 
            Get-Job -Name "Start-DTS-Pester" | Where-Object { $_.State -eq "Completed" } | Stop-Job
            Get-Job -Name "Start-DTS-Pester" | Remove-Job -Force
        }

        Import-DTModule -ModuleName "PSScriptAnalyzer" -ModuleVersion "1.21.0"

        $_target_dir = "$env:ProgramData\Frickeldave\$DirName-Pester"
        if(Test-Path "$_target_dir") {
            Remove-Item "$_target_dir" -Recurse
        }
    }

    if (-Not (Test-Path $_target_dir)) {
        New-Item -Path $_target_dir -ItemType Directory | Out-Null
    }

    return $_target_dir

}