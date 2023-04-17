function Install-DTS {
    [CmdletBinding()]
    param (
        [string]$SourceFile,
        [string]$TargetFile
    )

    $_sa_test_result = Invoke-ScriptAnalyzer "$SourceFile"
    if(-not ($null -eq $_sa_test_result)) {
        $_sa_test_result
        throw "Script analyzer failed for script ""$SourceFile""."
    }

    Copy-Item -Path "$SourceFile" -Destination "$TargetFile" -Recurse -Force
}