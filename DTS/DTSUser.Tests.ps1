
Describe 'User login tests' {
    BeforeAll {
        $_url = "http://localhost:8082"
        $_user01_username = "schennk"
        $_user01_password = "IAmUser01"
        $_user01_sid = $null

        $_sec_password = ConvertTo-SecureString $_user01_password -AsPlainText -Force
        $_credential = New-Object System.Management.Automation.PSCredential($_user01_username, $_sec_password)
        $_user01_sid = (Invoke-WebRequest -Uri "$_url/login" -Method Post -Credential $_credential -AllowUnencryptedAuthentication).Headers['pode.sid']
        $_user01_sid | Should -Not -Be $null
    }

    It 'Login with no sid should fail' {
        $_result = $null
        try { Invoke-RestMethod -Uri $_url/api/v1/dts/user/get -Method Get } catch {$_result = $_.Exception.Response.StatusCode}
        $_result | Should -Be 401
        
        $_result = $null
        try { Invoke-RestMethod -Uri $_url/api/v1/dts/user/getlist -Method Get } catch {$_result = $_.Exception.Response.StatusCode}
        $_result | Should -Be 401
    }

    It 'Get the list of users' {
        [Array]$_userList = Invoke-RestMethod -Uri $_url/api/v1/dts/user/getlist -Method Get -Headers @{ 'pode.sid' = "$_user01_sid" }
        $_userList.Count | Should -Be 4
    }

    It 'Create a new user and update properties' {
        $_user = Invoke-RestMethod -Uri "$_url/api/v1/dts/user/add?name=wellem&secret=IAmUser06" -Method Post
        $_user.userName | Should -Be "wellem"
        $_user = Invoke-RestMethod -Uri "$_url/api/v1/dts/user/update?name=wellem&firstname=Mirko&lastname=Welle" -Method Patch -Headers @{ 'pode.sid' = "$_user01_sid" }
        $_user.userFirstname | Should -Be "Mirko"
        $_user.userLastname | Should -Be "Welle"
    }
}

# Describe 'User API methods' {

#     $script:_api_user_one_id = $null

#     It 'Get the empty list of users' {
#         $_api_user_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/user/getuserlist'
#         $_api_user_list.Count | Should -Be 4
#     }

#     It 'Add user 1' {
#         $_api_user = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/user/adduser?name=user01&secret=IAmUser1'
#         "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\user\$($_api_user.userId).json" | Should -Exist
#         $_api_user.userName | Should -Be 'user01'
#         $script:_api_user_one_id = $($_api_user.userId)
#     }
#     It 'Add user 2' {
#         $_api_user = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/user/adduser?name=user02&secret=IAmUser2'
#         "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\user\$($_api_user.userId).json" | Should -Exist
#         $_api_user.userName | Should -Be 'user02'
#     }
#     It 'Add user 3' {
#         $_api_user = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/user/adduser?name=user03&secret=IAmUser3'
#         "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\user\$($_api_user.userId).json" | Should -Exist
#         $_api_user.userName | Should -Be 'user03'
#     }
#     It 'Add user 4' {
#         $_api_user = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/user/adduser?name=user04&secret=IAmUser4'
#         "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\user\$($_api_user.userId).json" | Should -Exist
#         $_api_user.userName | Should -Be 'user04'
#     }

#     It 'Get the list of users' {
#         $_api_user_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/user/getuserlist'
#         $_api_user_list.Count | Should -Be 8
#     }

#     It 'Get the first user by its Id' {
#         $_api_user = Invoke-RestMethod -Method Get -Uri "http://localhost:8082/api/v1/dts/user/getuser?id=$($script:_api_user_one_id)"
#         $_api_user.userId | Should -Be $script:_api_user_one_id
#         $_api_user.userName | Should -Be "user01"
#     }

#     It 'Get the first user by its Name' {
#         $_api_user = Invoke-RestMethod -Method Get -Uri "http://localhost:8082/api/v1/dts/user/getuser?name=user01"
#         $_api_user.userId | Should -Be $script:_api_user_one_id
#         $_api_user.userName | Should -Be "user01"
#     }
# }