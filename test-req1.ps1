
# NAtive method
$username = "user05"
$password = "ThatsMyPassword5!"
$pair = "{0}:{1}" -f ($username, $password)
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$token = [System.Convert]::ToBase64String($bytes)
$headers = @{Authorization = "Basic {0}" -f ($token)}

Invoke-RestMethod -Uri "http://localhost:8082/login" -Headers $headers

# Powershell method

$securePassword = ConvertTo-SecureString -String $password -AsPlainText
$credential = [PSCredential]::new($username, $securePassword)
Invoke-RestMethod -Uri "http://localhost:8082/login" -Authentication Basic -Credential $credential