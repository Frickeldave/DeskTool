function Get-DTSStatus {

    Add-PodeRoute -Method Get -Path '/api/v1/dts/status' -ScriptBlock {

        Write-PodeLog -Name "log" -InputObject @{Message="Got incoming request on path /api/v1/dts/status"; Component="Get-DTStatus"; Type="Info"}

        $_return = New-Object -Type psobject
        $_return | Add-Member -MemberType NoteProperty -Name "currentTime" -Value (Get-Date -Format "yyyy-MM-dd HH:mm K") -Force
        $_return | Add-Member -MemberType NoteProperty -Name "status" -Value "OK" -Force
        Write-PodeJsonResponse -Value ($_return | ConvertTo-Json)
    }
}