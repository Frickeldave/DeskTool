Describe 'User API methods' {

    $script:_api_user_one_id = $null

    It 'Get the empty list of users' {
        $_api_user_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/user/getuserlist'
        $_api_user_list.Count | Should -Be 4
    }

    It 'Add user 1' {
        $_api_user = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/user/adduser?name=user01&secret=IAmUser1'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\user\$($_api_user.userId).json" | Should -Exist
        $_api_user.userName | Should -Be 'user01'
        $script:_api_user_one_id = $($_api_user.userId)
    }
    It 'Add user 2' {
        $_api_user = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/user/adduser?name=user02&secret=IAmUser2'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\user\$($_api_user.userId).json" | Should -Exist
        $_api_user.userName | Should -Be 'user02'
    }
    It 'Add user 3' {
        $_api_user = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/user/adduser?name=user03&secret=IAmUser3'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\user\$($_api_user.userId).json" | Should -Exist
        $_api_user.userName | Should -Be 'user03'
    }
    It 'Add user 4' {
        $_api_user = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/user/adduser?name=user04&secret=IAmUser4'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\user\$($_api_user.userId).json" | Should -Exist
        $_api_user.userName | Should -Be 'user04'
    }

    It 'Get the list of users' {
        $_api_user_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/user/getuserlist'
        $_api_user_list.Count | Should -Be 8
    }

    It 'Get the first user by its Id' {
        $_api_user = Invoke-RestMethod -Method Get -Uri "http://localhost:8082/api/v1/dts/user/getuser?id=$($script:_api_user_one_id)"
        $_api_user.userId | Should -Be $script:_api_user_one_id
        $_api_user.userName | Should -Be "user01"
    }

    It 'Get the first user by its Name' {
        $_api_user = Invoke-RestMethod -Method Get -Uri "http://localhost:8082/api/v1/dts/user/getuser?name=user01"
        $_api_user.userId | Should -Be $script:_api_user_one_id
        $_api_user.userName | Should -Be "user01"
    }
}