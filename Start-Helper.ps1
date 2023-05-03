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