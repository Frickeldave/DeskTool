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
        [string]$BasePath,
        [switch]$Test
    )

    if($Test) {

        # Stop previously created and running test jobs
        if (-not ($null -eq (Get-Job -Name "Start-DTS-Test" -ErrorAction SilentlyContinue))) { 
            Get-Job -Name "Start-DTS-Test" | Where-Object { $_.State -eq "Completed" } | Stop-Job
            Get-Job -Name "Start-DTS-Test" | Remove-Job -Force
        }

        Import-DTModule -ModuleName "PSScriptAnalyzer" -ModuleVersion "1.21.0"


        if(Test-Path "$BasePath") {
            Remove-Item "$BasePath" -Recurse
        }
    }

    if (-Not (Test-Path $BasePath)) {
        New-Item -Path $BasePath -ItemType Directory | Out-Null
    }

    return $BasePath
}