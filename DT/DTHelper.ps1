function Get-DTCefSharp {

    [CmdletBinding()]
    param (
        [string]$ConfigBasePath,
        [string]$ConfigFolder,
        [string]$RedistVersion,
        [string]$CommonVersion,
        [string]$WpfVersion
    )


    Write-DTCLog "Check CefSharp directories" -Component "Get-CefSharp"
    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\temp)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder\temp -ItemType Directory | Out-Null
    }

    if (-Not (Test-Path $ConfigBasePath\$ConfigFolder\lib\CefSharp)) {
        New-Item -Path $ConfigBasePath\$ConfigFolder\lib\CefSharp -ItemType Directory | Out-Null
    }

    if(-not (Test-Path $ConfigBasePath\$ConfigFolder\lib\CefSharp\libcef.dll) -or -not ((Get-Item $ConfigBasePath\$ConfigFolder\lib\CefSharp\libcef.dll).VersionInfo.FileVersion).StartsWith("$($RedistVersion)+")) {
        Write-DTCLog "Download CEFSharp redis" -Component "Get-CefSharp"
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/cef.redist.x64/$RedistVersion -OutFile "$ConfigBasePath\$ConfigFolder\temp\cef_redis_$RedistVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$ConfigBasePath\$ConfigFolder\temp\cef_redis_$RedistVersion.zip" -DestinationPath "$ConfigBasePath\$ConfigFolder\temp\cef_redis_$RedistVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$ConfigBasePath\$ConfigFolder\temp\cef_redis_$RedistVersion\CEF\*" -Destination "$ConfigBasePath\$ConfigFolder\lib\CefSharp" -Recurse -Force
    }

    if(-not (Test-Path $ConfigBasePath\$ConfigFolder\lib\CefSharp\CefSharp.Wpf.dll) -or -not ((Get-Item $ConfigBasePath\$ConfigFolder\lib\CefSharp\CefSharp.Wpf.dll).VersionInfo.FileVersion).StartsWith("$($WpfVersion)")) {
        Write-DTCLog "Download CEFSharp WPF" -Component "Get-CefSharp"
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/CefSharp.Wpf/$WpfVersion -OutFile "$ConfigBasePath\$ConfigFolder\temp\cef_wpf_$WpfVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$ConfigBasePath\$ConfigFolder\temp\cef_wpf_$WpfVersion.zip" -DestinationPath "$ConfigBasePath\$ConfigFolder\temp\cef_wpf_$WpfVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$ConfigBasePath\$ConfigFolder\temp\cef_wpf_$WpfVersion\lib\net462\*" -Destination "$ConfigBasePath\$ConfigFolder\lib\CefSharp" -Recurse -Force
    }

    if(-not (Test-Path $ConfigBasePath\$ConfigFolder\lib\CefSharp\CefSharp.Core.dll) -or -not ((Get-Item $ConfigBasePath\$ConfigFolder\lib\CefSharp\CefSharp.Core.dll).VersionInfo.FileVersion).StartsWith("$($WpfVersion)")) {
        Write-DTCLog "Download CEFSharp common" -Component "Get-CefSharp"
        Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/CefSharp.Common/$CommonVersion -OutFile "$ConfigBasePath\$ConfigFolder\temp\cef_common_$CommonVersion.zip" | Out-Null
        Expand-Archive -LiteralPath "$ConfigBasePath\$ConfigFolder\temp\cef_common_$CommonVersion.zip" -DestinationPath "$ConfigBasePath\$ConfigFolder\temp\cef_common_$CommonVersion" -ErrorAction SilentlyContinue | Out-Null
        Copy-Item -Path "$ConfigBasePath\$ConfigFolder\temp\cef_common_$CommonVersion\lib\net452\*" -Destination "$ConfigBasePath\$ConfigFolder\lib\CefSharp" -Recurse -Force
        Copy-Item -Path "$ConfigBasePath\$ConfigFolder\temp\cef_common_$CommonVersion\CefSHarp\x64\*" -Destination "$ConfigBasePath\$ConfigFolder\lib\CefSharp" -Recurse -Force
    }
    Remove-Item "$ConfigBasePath\$ConfigFolder\temp\cef_redis_$RedistVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$ConfigBasePath\$ConfigFolder\temp\cef_common_$CommonVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$ConfigBasePath\$ConfigFolder\temp\cef_wpf_$WpfVersion.zip" -ErrorAction SilentlyContinue
    Remove-Item "$ConfigBasePath\$ConfigFolder\temp\cef_redis_$RedistVersion" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$ConfigBasePath\$ConfigFolder\temp\cef_common_$CommonVersion" -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$ConfigBasePath\$ConfigFolder\temp\cef_wpf_$WpfVersion" -Recurse -ErrorAction SilentlyContinue
}
