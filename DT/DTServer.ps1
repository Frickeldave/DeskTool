Write-DTLog -Message "Import Server functions into session" -Component "DTServer" -Type "Info" -LogSource "main"

function Grant-DTServerAccess {
    [CmdletBinding()]
    param (
        [string]$UserName,
        [string]$Secret
    )

    $_user = $null

    try {

        Write-DTLog -Message "Grant access to server" -Component "Grant-DTServerAccess" -Type "Info" -LogSource "main"

        $_address = Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtserveraddress"
        $_port = Get-DTConfigValue -ConfigGroup "common" -ConfigName "dtserverport"

        $_url = "http://$($_address):$($_port)"
        Write-DTLog -Message "Connect to $_url" -Component "Grant-DTServerAccess" -Type "Info" -LogSource "main"

        $_sec_secret = ConvertTo-SecureString $Secret -AsPlainText -Force
        $_credential = New-Object System.Management.Automation.PSCredential($Username, $_sec_secret)
        [string]$_sid = (Invoke-WebRequest -Uri "$_url/login" -Method Post -Credential $_credential -AllowUnencryptedAuthentication).Headers['pode.sid']

        if([string]::IsNullOrEmpty($_sid)) {
            throw "Login failed, no SID received" 
        }

        Write-DTLog -Message "Login successful, try to get all user information" -Component "Grant-DTServerAccess" -Type "Info" -LogSource "main" 
        $_user = Invoke-RestMethod -Uri "$_url/api/v1/dts/user/get?name=$UserName" -Method Get -Headers @{ 'pode.sid' = "$_sid" }
        $_user | Add-Member -MemberType NoteProperty -Name 'userSid' -Value $_sid

        return $_user

    } catch {
        Write-DTLog -Message "Login failed. Details: $($_.Exception.Message)" -Component "Grant-DTServerAccess" -Type "Error" -LogSource "main"
    }
}