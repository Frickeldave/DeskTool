Describe 'Poker API methods' {

    $script:_api_poker_table_one_id = $null

    It 'Get the empty list of poker tables' {
        $_api_poker_table_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/poker/gettablelist'
        $_api_poker_table_list | Should -Be ''
    }

    It 'Add poker table 1' {
        $_api_poker_table_one = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint01&secret=ThatsMyPassword1'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table_one.pokerTableId).json" | Should -Exist
        $_api_poker_table_one.pokerTableName | Should -Be 'sprint01'
        $_api_poker_table_one.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
        $script:_api_poker_table_one_id = $($_api_poker_table_one.pokerTableId)
    }
    It 'Add poker table 2' {
        $_api_poker_table_one = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint02&secret=ThatsMyPassword2'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table_one.pokerTableId).json" | Should -Exist
        $_api_poker_table_one.pokerTableName | Should -Be 'sprint02'
        $_api_poker_table_one.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
    }
    It 'Add poker table 3' {
        $_api_poker_table_one = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint03&secret=ThatsMyPassword3'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table_one.pokerTableId).json" | Should -Exist
        $_api_poker_table_one.pokerTableName | Should -Be 'sprint03'
        $_api_poker_table_one.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
    }
    It 'Add poker table 4' {
        $_api_poker_table_one = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint04&secret=ThatsMyPassword4'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table_one.pokerTableId).json" | Should -Exist
        $_api_poker_table_one.pokerTableName | Should -Be 'sprint04'
        $_api_poker_table_one.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
    }

    It 'Get all 4 poker tables as list' {
        $_api_poker_table_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/poker/gettablelist'
        $_api_poker_table_list.Count | Should -Be 4
    }

    It 'Get the first poker table by its Id' {
        $_api_poker_table_one = Invoke-RestMethod -Method Get -Uri "http://localhost:8082/api/v1/dts/poker/gettable?id=$($script:_api_poker_table_one_id)&secret=ThatsMyPassword4"
        $_api_poker_table_one.pokerTableId | Should -Be $_api_poker_table_one_id
        $_api_poker_table_one.pokerTableName | Should -Be "sprint01"
    }

    It 'Get the first poker table by its Name' {
        $_api_poker_table_one = Invoke-RestMethod -Method Get -Uri "http://localhost:8082/api/v1/dts/poker/gettable?name=sprint01&secret=ThatsMyPassword1"
        $_api_poker_table_one.pokerTableId | Should -Be $_api_poker_table_one_id
        $_api_poker_table_one.pokerTableName | Should -Be "sprint01"
    }

    It 'Join some user to table' {
        $_api_poker_table_one = Invoke-RestMethod -Method Put -Uri "http://localhost:8082/api/v1/dts/poker/jointable?name=sprint01&secret=ThatsMyPassword1&participant=user01"
        $_api_poker_table_one = Invoke-RestMethod -Method Put -Uri "http://localhost:8082/api/v1/dts/poker/jointable?name=sprint01&secret=ThatsMyPassword1&participant=user02"
        $_api_poker_table_one = Invoke-RestMethod -Method Put -Uri "http://localhost:8082/api/v1/dts/poker/jointable?id=$($script:_api_poker_table_one_id)&secret=ThatsMyPassword1&participant=user03"
        $_api_poker_table_one = Invoke-RestMethod -Method Put -Uri "http://localhost:8082/api/v1/dts/poker/jointable?id=$($script:_api_poker_table_one_id)&secret=ThatsMyPassword1&participant=user04"
        $_api_poker_table_one.pokerTableParticipants.Count | Should -Be 4
    }
}