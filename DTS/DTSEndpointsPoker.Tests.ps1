Describe 'Poker API methods' {

    $script:_api_poker_table_one_id = $null

    It 'Get the empty list of poker tables' {
        $_api_poker_table_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/poker/gettablelist'
        $_api_poker_table_list | Should -Be ''
    }

    It 'Add poker table 1' {
        $_api_poker_table = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint01&secret=ThatsMyPassword1'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table.pokerTableId).json" | Should -Exist
        $_api_poker_table.pokerTableName | Should -Be 'sprint01'
        $_api_poker_table.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
        $script:_api_poker_table_one_id = $($_api_poker_table.pokerTableId)
    }
    It 'Add poker table 2' {
        $_api_poker_table = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint02&secret=ThatsMyPassword2'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table.pokerTableId).json" | Should -Exist
        $_api_poker_table.pokerTableName | Should -Be 'sprint02'
        $_api_poker_table.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
    }
    It 'Add poker table 3' {
        $_api_poker_table = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint03&secret=ThatsMyPassword3'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table.pokerTableId).json" | Should -Exist
        $_api_poker_table.pokerTableName | Should -Be 'sprint03'
        $_api_poker_table.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
    }
    It 'Add poker table 4' {
        $_api_poker_table = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint04&secret=ThatsMyPassword4'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table.pokerTableId).json" | Should -Exist
        $_api_poker_table.pokerTableName | Should -Be 'sprint04'
        $_api_poker_table.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
    }

    It 'Get all 4 poker tables as list' {
        $_api_poker_table_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/poker/gettablelist'
        $_api_poker_table_list.Count | Should -Be 4
    }

    It 'Get the first poker table by its Id' {
        $_api_poker_table = Invoke-RestMethod -Method Get -Uri "http://localhost:8082/api/v1/dts/poker/gettable?id=$($script:_api_poker_table_one_id)&secret=ThatsMyPassword4"
        $_api_poker_table.pokerTableId | Should -Be $_api_poker_table_one_id
        $_api_poker_table.pokerTableName | Should -Be "sprint01"
    }

    It 'Get the first poker table by its Name' {
        $_api_poker_table = Invoke-RestMethod -Method Get -Uri "http://localhost:8082/api/v1/dts/poker/gettable?name=sprint01&secret=ThatsMyPassword1"
        $_api_poker_table.pokerTableId | Should -Be $_api_poker_table_one_id
        $_api_poker_table.pokerTableName | Should -Be "sprint01"
    }

    It 'Register some user to table 1' {
        $_api_poker_table = Invoke-RestMethod -Method Put -Uri "http://localhost:8082/api/v1/dts/poker/registerparticipant?name=sprint01&secret=ThatsMyPassword1&participant=5cd67325-258b-4a15-962d-1ff34f880d2a"
        $_api_poker_table = Invoke-RestMethod -Method Put -Uri "http://localhost:8082/api/v1/dts/poker/registerparticipant?name=sprint01&secret=ThatsMyPassword1&participant=7f9e7dcd-86c8-492c-8d7a-adaaad24dd66"
        $_api_poker_table = Invoke-RestMethod -Method Put -Uri "http://localhost:8082/api/v1/dts/poker/registerparticipant?name=sprint01&secret=ThatsMyPassword1&participant=9f050f96-17fe-4d10-96e0-e65f2f65d0ad"
        $_api_poker_table = Invoke-RestMethod -Method Put -Uri "http://localhost:8082/api/v1/dts/poker/registerparticipant?name=sprint01&secret=ThatsMyPassword1&participant=80a69c0c-60a4-43b1-b249-26fc033ad6c6"
        $_api_poker_table.pokerTableParticipants.Count | Should -Be 4
    }
}