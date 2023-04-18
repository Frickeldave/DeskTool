
$script:_log_file_dir = $null
$script:_log_file_name = $null
$script:_log_target = $null

function Initialize-CommonEndpoint{

    [CmdletBinding()]
        param (
            [string]$LogFileDir,
            [string]$LogFileName,
            [string]$LogTarget
        )

    Write-DTCLog -Message "Initialize common endpoint configuration" -Component "Initialize-CommonEndpoint"
    # TODO: Remove the following 3 lines
    Write-DTCLog -Message "Dir: $LogFileDir" -Component "Initialize-CommonEndpoint"
    Write-DTCLog -Message "Name: $LogFileName" -Component "Initialize-CommonEndpoint"
    Write-DTCLog -Message "Target: $LogTarget" -Component "Initialize-CommonEndpoint"
    $script:_log_file_dir = $LogFileDir
    $script:_log_file_name = $LogFileName
    $script:_log_target = $LogTarget

}

function Get-DTSStatusApi {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/status' -ScriptBlock {

        #Load functions
        . $PSScriptRoot\DTSEndpointsCommon.ps1

        Write-DTSLog -Message "Got incoming request on path /api/v1/dts/status" -Component "Get-DTStatus" -Type "Info"
        $_return = New-Object -Type psobject
        $_return | Add-Member -MemberType NoteProperty -Name "currentTime" -Value (Get-Date -Format "yyyy-MM-dd HH:mm") -Force
        $_return | Add-Member -MemberType NoteProperty -Name "status" -Value "OK" -Force
        Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
    }
}

function Write-DTSLog {

    [CmdletBinding()]
    param (
        [string]$Message,
        [string]$Component,
        [string]$Type
    )

    # Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogdir"
    # Get-DTSConfigValue -ConfigGroup "common" -ConfigName "dtslogfile"

    # TODO: This is staticall added because i was not able to get the values from outside
    $script:_log_file_dir = "C:\ProgramData\Frickeldave\DTS-Pester\DTS"
    $script:_log_file_name = "DTS.log"
    $script:_log_target = "File"

    Write-PodeLog -Name "log" -InputObject @{Message=$Message; Component=$Component; Type=$Type; LogFileDir=$script:_log_file_dir; LogFileName=$script:_log_file_name; LogTarget=$script:_log_target}
}