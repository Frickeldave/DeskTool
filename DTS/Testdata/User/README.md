# User test data

These are user that are needed during automated tests.
The passwords of the users are:

| ID                                   | Username   | Password  | Source   | Fullname        |
|--------------------------------------|------------|-----------|----------|-----------------|
| 9f050f96-17fe-4d10-96e0-e65f2f65d0ad | schennk    | IAmUser01 | Testdata | Knut Schenn     |
| 7f9e7dcd-86c8-492c-8d7a-adaaad24dd66 | clinger    | IAmUser02 | Testdata | Caro Linger     |
| 80a69c0c-60a4-43b1-b249-26fc033ad6c6 | sittert    | IAmUser03 | Testdata | Till Sitter     |
| 5cd67325-258b-4a15-962d-1ff34f880d2a | sfaehrlich | IAmUser04 | Testdata | Sergej Fährlich |
| ---                                  | pastea     | IAmUser05 | DTS.http | Andi Paste      |
| ---                                  | wellem     | IAmUser06 | Pester   | Mirko Welle     |

## How to test with Powershell

With a base64 encrypted string:

```powershell

$_username = "schennk"
$_password = "IAmUser01"
$_pair = "{0}:{1}" -f ($_username, $_password)
$_bytes = [System.Text.Encoding]::ASCII.GetBytes($_pair)
$_token = [System.Convert]::ToBase64String($_bytes)
$_headers = @{Authorization = "Basic {0}" -f ($_token)}
Invoke-WebRequest -Uri "http://localhost:8082/login" -Headers $_headers -Method Post

```

With a SecureString:

```powershell

$_username = "schennk"
$_password= "IAmUser01"
$_sec_password = ConvertTo-SecureString $_password -AsPlainText -Force
$_credential = New-Object System.Management.Automation.PSCredential($_username, $_sec_password)
Invoke-WebRequest -Uri "http://localhost:8082/login" -Method Post -Credential $_credential

```

## How to create a user has with powershell

```powershell

$_password= "IAmUser01"
$_user_secret_salt = $(-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
Write-Host $_user_secret_salt
$_user_secret_hash = (Get-FileHash -InputStream $([IO.MemoryStream]::new([byte[]][char[]]"$($_password)$($_user_secret_salt)")) -Algorithm SHA256).Hash
Write-Host $_user_secret_hash

```
