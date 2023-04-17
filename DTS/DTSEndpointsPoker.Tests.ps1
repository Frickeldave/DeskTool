Describe 'Poker API methods' {

    It 'Get the empty list of poker tables' {
        $_api_poker_table_list = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/poker/gettablelist'
        $_api_poker_table_list | Should -Be ''
    }

    It 'Add poker table 1' {
        $_api_poker_table_one = Invoke-RestMethod -Method Post -Uri 'http://localhost:8082/api/v1/dts/poker/addtable?name=sprint01&secret=ThatsMyPassword1'
        "$env:ProgramData\Frickeldave\DTS-Pester\DTS\Endpoints\poker\$($_api_poker_table_one.pokerTableId).json" | Should -Exist
        $_api_poker_table_one.pokerTableName | Should -Be 'sprint01'
        $_api_poker_table_one.pokerTableEstimationMethod | Should -Be 'fibonacci_classic'
    }
}