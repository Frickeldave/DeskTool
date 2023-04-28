function Get-DTSCommonStatusAPI {
    Write-DTSLog -Message "Load status api" -Component "Get-DTSCommonStatusAPI" -Type "Info"

    Add-PodeRoute -Method Get -Path '/api/v1/dts/status' -ScriptBlock {

        # Load functions
		. $PSScriptRoot\DTSLog.ps1

        Write-DTSLog -Message "Got incoming request on path /api/v1/dts/status" -Component "Get-DTSCommonStatusAPI" -Type "Info"
        $_return = New-Object -Type psobject
        $_return | Add-Member -MemberType NoteProperty -Name "currentTime" -Value (Get-Date -Format "yyyy-MM-dd HH:mm") -Force
        $_return | Add-Member -MemberType NoteProperty -Name "status" -Value "OK" -Force
        Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
    }
}