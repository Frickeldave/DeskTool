function Get-DTCefSharp {

    [CmdletBinding()]
    param (
        [string]$RedistVersion,
        [string]$CommonVersion,
        [string]$WpfVersion
    )


    Write-DTLog -Message "Check CefSharp directories" -Component "Get-CefSharp" -Type "Info" -LogSource "main"

    if (-Not (Test-Path "$PSScriptRoot")) {
        New-Item -Path "$PSScriptRoot" -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path "$PSScriptRoot\temp")) {
        New-Item -Path "$PSScriptRoot\temp" -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path "$PSScriptRoot\lib\CefSharp")) {
        New-Item -Path "$PSScriptRoot\lib\CefSharp" -ItemType Directory | Out-Null
    }

    if(-not (Test-Path "$PSScriptRoot\lib\CefSharp\libcef.dll") -or -not ((Get-Item "$PSScriptRoot\lib\CefSharp\libcef.dll").VersionInfo.FileVersion).StartsWith("$($RedistVersion)+")) {
        Write-DTLog -Message "Download CEFSharp redis" -Component "Get-CefSharp" -Type "Info" -LogSource "main"
        Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/cef.redist.x64/$RedistVersion" -OutFile "$PSScriptRoot\temp\cef_redis_$RedistVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$PSScriptRoot\temp\cef_redis_$RedistVersion.zip" -DestinationPath "$PSScriptRoot\temp\cef_redis_$RedistVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$PSScriptRoot\temp\cef_redis_$RedistVersion\CEF\*" -Destination "$PSScriptRoot\lib\CefSharp" -Recurse -Force
    }

    if(-not (Test-Path "$PSScriptRoot\lib\CefSharp\CefSharp.Wpf.dll") -or -not ((Get-Item "$PSScriptRoot\lib\CefSharp\CefSharp.Wpf.dll").VersionInfo.FileVersion).StartsWith("$($WpfVersion)")) {
        Write-DTLog -Message "Download CEFSharp WPF" -Component "Get-CefSharp" -Type "Info" -LogSource "main"
        Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/CefSharp.Wpf/$WpfVersion" -OutFile "$PSScriptRoot\temp\cef_wpf_$WpfVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$PSScriptRoot\temp\cef_wpf_$WpfVersion.zip" -DestinationPath "$PSScriptRoot\temp\cef_wpf_$WpfVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$PSScriptRoot\temp\cef_wpf_$WpfVersion\lib\net462\*" -Destination "$PSScriptRoot\lib\CefSharp" -Recurse -Force
    }

    if(-not (Test-Path "$PSScriptRoot\lib\CefSharp\CefSharp.Core.dll") -or -not ((Get-Item "$PSScriptRoot\lib\CefSharp\CefSharp.Core.dll").VersionInfo.FileVersion).StartsWith("$($WpfVersion)")) {
        Write-DTLog -Message "Download CEFSharp common" -Component "Get-CefSharp" -Type "Info" -LogSource "main"
        Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/CefSharp.Common/$CommonVersion" -OutFile "$PSScriptRoot\temp\cef_common_$CommonVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$PSScriptRoot\temp\cef_common_$CommonVersion.zip" -DestinationPath "$PSScriptRoot\temp\cef_common_$CommonVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$PSScriptRoot\temp\cef_common_$CommonVersion\lib\net452\*" -Destination "$PSScriptRoot\lib\CefSharp" -Recurse -Force
        Copy-Item -Path "$PSScriptRoot\temp\cef_common_$CommonVersion\CefSHarp\x64\*" -Destination "$PSScriptRoot\lib\CefSharp" -Recurse -Force
    }
    Remove-Item "$PSScriptRoot\temp\cef_redis_$RedistVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$PSScriptRoot\temp\cef_common_$CommonVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$PSScriptRoot\temp\cef_wpf_$WpfVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$PSScriptRoot\temp\cef_redis_$RedistVersion" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$PSScriptRoot\temp\cef_common_$CommonVersion" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$PSScriptRoot\temp\cef_wpf_$WpfVersion" -Recurse -ErrorAction SilentlyContinue

    Write-DTLog -Message "CefSharp installation finished" -Component "Get-CefSharp" -Type "Info" -LogSource "main"
}
