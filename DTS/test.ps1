# Get properties from input args
$PokerBasePath = "C:\ProgramData\Frickeldave\DTS\Endpoints\poker"

. $PSScriptRoot\DTSEndpointsHelperPoker.ps1

$_poker_table_list = Get-DTSEndpointHelperPokerGetTableList -PokerBasePath $PokerBasePath -Full

$_poker_Table_name = "sprint01"

foreach($_poker_table in $_poker_table_list) {
    if($_poker_table.pokerTableName -eq $_poker_Table_name) {
        echo $_poker_table.pokerTableId
    }
}