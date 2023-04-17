
function Import-DTCModule {
    [CmdletBinding()]
    param (
        [string]$ModuleName,
        [string]$ModuleVersion
    )

    Write-DTCLog "Start function Import-DTCModule" -Component "Import-DTCModule"

    try {

        # Check if module is installed
        if (-Not ((Get-Module -ListAvailable -Name $ModuleName).Version -eq $ModuleVersion)) {
            Write-DTCLog "Module $ModuleName in version $ModuleVersion is not installed" -Component "Import-DTCModule"  -Type Warning

            Write-DTCLog "Set PSGallery to trusted to avoid WARNING messages" -Component "Import-DTCModule"
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

            Write-DTCLog "Install Module $ModuleName in version $ModuleVersion" -Component "Import-DTCModule"
            Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Scope CurrentUser

            Write-DTCLog "Set PSGallery to untrusted" -Component "Import-DTCModule"
            Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
        } else {
            Write-DTCLog "Module $ModuleName in version $ModuleVersion already installed" -Component "Import-DTCModule"
        }

        # Check if module is imported
        if (-Not ((Get-Module -Name $ModuleName).Version -eq $ModuleVersion)) {
            Write-DTCLog "Module $ModuleName in version $ModuleVersion is not imported to current session" -Component "Import-DTCModule" -Type Warning

            Write-DTCLog "Import module $ModuleName in version $ModuleVersion" -Component "Import-DTCModule"
            Import-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Scope Local
        } else {
            Write-DTCLog "Module $ModuleName in version $ModuleVersion already imported" -Component "Import-DTCModule"
        }

    }
    catch {
        Write-DTCLog "The installation/loading of module Module $ModuleName in version $ModuleVersion was not successful. Details: $($_.Exception)" -Component "Import-DTCModule" -Type Error
        Write-DTCLog "Set PSGallery to untrusted" -Component "Import-DTCModule"
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
    } finally {

    }
}

function Remove-DTCOhMyPosh {

    [CmdletBinding(SupportsShouldProcess=1)]
    param()

    if (Get-Module -Name oh-my-posh-core) {
        Write-DTCLog "Remove oh-my-posh-core from current session" -Component "Remove-DTCOhMyPosh"
        Remove-Module oh-my-posh-core -ErrorAction SilentlyContinue  >$null 2>&1
    }
    if (Get-Module -Name posh-git) {
        Write-DTCLog "Remove oh-my-posh-git from current session" -Component "Remove-DTCOhMyPosh"
        Remove-Module posh-git -ErrorAction SilentlyContinue >$null 2>&1
    }
    if (Get-Module -Name Terminal-Icons) {
        Write-DTCLog "Remove Terminal-Icons from current session" -Component "Remove-DTCOhMyPosh"
        Remove-Module Terminal-Icons -ErrorAction SilentlyContinue >$null 2>&1
    }

}

