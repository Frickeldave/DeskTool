
function Import-DTModule {
    [CmdletBinding()]
    param (
        [string]$ModuleName,
        [string]$ModuleVersion
    )
    
    Write-DTLog "Start function Load-DTModule" -Component "Load-DTModule"

    try {
        
        # Check if module is installed
        if (-Not ((Get-Module -ListAvailable -Name $ModuleName).Version -eq $ModuleVersion)) {
            Write-DTLog "Module $ModuleName in version $ModuleVersion is not installed" -Component "Load-DTModule"  -Type Warning

            Write-DTLog "Set PSGallery to trusted to avoid WARNING messages" -Component "Load-DTModule"
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            
            Write-DTLog "Install Module $ModuleName in version $ModuleVersion" -Component "Load-DTModule"
            Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Scope CurrentUser

            Write-DTLog "Set PSGallery to untrusted" -Component "Load-DTModule"
            Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
        } else {
            Write-DTLog "Module $ModuleName in version $ModuleVersion already installed" -Component "Load-DTModule"
        }

        # Check if module is imported
        if (-Not ((Get-Module -Name $ModuleName).Version -eq $ModuleVersion)) {
            Write-DTLog "Module $ModuleName in version $ModuleVersion is not imported to current session" -Component "Load-DTModule" -Type Warning
          
            Write-DTLog "Import module $ModuleName in version $ModuleVersion" -Component "Load-DTModule"
            Import-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Scope Local
        } else {
            Write-DTLog "Module $ModuleName in version $ModuleVersion already imported" -Component "Load-DTModule"
        }

    }
    catch {
        Write-DTLog "The installation/loading of module Module $ModuleName in version $ModuleVersion was not successful. Details: $($_.Exception)" -Component "Load-DTModule" -Type Error
        Write-DTLog "Set PSGallery to untrusted" -Component "Load-DTModule"
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
    } finally {
        
    }
} 

function Remove-OhMyPosh {

    if (Get-Module -Name oh-my-posh-core) {
        Write-DTLog "Remove oh-my-posh-core from current session" -Component "Remove-OhMyPosh"
        Remove-Module oh-my-posh-core -ErrorAction SilentlyContinue  >$null 2>&1
    }
    if (Get-Module -Name posh-git) {
        Write-DTLog "Remove oh-my-posh-git from current session" -Component "Remove-OhMyPosh"
        Remove-Module posh-git -ErrorAction SilentlyContinue >$null 2>&1
    }
    if (Get-Module -Name Terminal-Icons) {
        Write-DTLog "Remove Terminal-Icons from current session" -Component "Remove-OhMyPosh"
        Remove-Module Terminal-Icons -ErrorAction SilentlyContinue >$null 2>&1
    }

}

function Get-CefSharp {

    [CmdletBinding()]
    param (
        [string]$RedistVersion,
        [string]$CommonVersion,
        [string]$WpfVersion
    )

    Write-DTLog "Check CefSharp directories" -Component "Get-CefSharp"
    if (-Not (Test-Path $global:_dt_base_path_app\$global:_dt_app_name)) {
        New-Item -Path $global:_dt_base_path_app\$global:_dt_app_name -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $global:_dt_base_path_app\$global:_dt_app_name\temp)) {
        New-Item -Path $global:_dt_base_path_app\$global:_dt_app_name\temp -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp)) {
        New-Item -Path $global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp -ItemType Directory | Out-Null
    }

    if(-not (Test-Path $global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp\libcef.dll) -or -not ((Get-Item $global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp\libcef.dll).VersionInfo.FileVersion).StartsWith("$($RedistVersion)+")) {
        Write-DTLog "Download CEFSharp redis" -Component "Get-CefSharp"
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/cef.redist.x64/$RedistVersion -OutFile "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_redis_$RedistVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_redis_$RedistVersion.zip" -DestinationPath "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_redis_$RedistVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_redis_$RedistVersion\CEF\*" -Destination "$global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp" -Recurse -Force
    }

    if(-not (Test-Path $global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp\CefSharp.Wpf.dll) -or -not ((Get-Item $global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp\CefSharp.Wpf.dll).VersionInfo.FileVersion).StartsWith("$($WpfVersion)")) {
        Write-DTLog "Download CEFSharp WPF" -Component "Get-CefSharp"
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/CefSharp.Wpf/$WpfVersion -OutFile "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_wpf_$WpfVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_wpf_$WpfVersion.zip" -DestinationPath "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_wpf_$WpfVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_wpf_$WpfVersion\lib\net462\*" -Destination "$global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp" -Recurse -Force
    }

    if(-not (Test-Path $global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp\CefSharp.Core.dll) -or -not ((Get-Item $global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp\CefSharp.Core.dll).VersionInfo.FileVersion).StartsWith("$($WpfVersion)")) {
        Write-DTLog "Download CEFSharp common" -Component "Get-CefSharp"
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/CefSharp.Common/$CommonVersion -OutFile "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_common_$CommonVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_common_$CommonVersion.zip" -DestinationPath "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_common_$CommonVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_common_$CommonVersion\lib\net452\*" -Destination "$global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp" -Recurse -Force
        Copy-Item -Path "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_common_$CommonVersion\CefSHarp\x64\*" -Destination "$global:_dt_base_path_app\$global:_dt_app_name\lib\CefSharp" -Recurse -Force
    }
    Remove-Item "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_redis_$RedistVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_common_$CommonVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_wpf_$WpfVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_redis_$RedistVersion" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_common_$CommonVersion" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$global:_dt_base_path_app\$global:_dt_app_name\temp\cef_wpf_$WpfVersion" -Recurse -ErrorAction SilentlyContinue
}