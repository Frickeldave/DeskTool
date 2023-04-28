
function Import-DTCModule {
    [CmdletBinding()]
    param (
        [string]$ModuleName,
        [string]$ModuleVersion
    )
    try {

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
    catch {
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
    } finally {

    }
}

function Remove-DTCOhMyPosh {

    [CmdletBinding(SupportsShouldProcess=1)]
    param()

    if (Get-Module -Name oh-my-posh-core) {
        Remove-Module oh-my-posh-core -ErrorAction SilentlyContinue  >$null 2>&1
    }
    if (Get-Module -Name posh-git) {
        Remove-Module posh-git -ErrorAction SilentlyContinue >$null 2>&1
    }
    if (Get-Module -Name Terminal-Icons) {
        Remove-Module Terminal-Icons -ErrorAction SilentlyContinue >$null 2>&1
    }

}

