# Get properties from input args
$PokerBasePath = "C:\ProgramData\Frickeldave\DTS\Endpoints\poker"
$PokerTableName = "sprint01"
$PokerTableSecret = "ThatsMyPassword1"

. $PSScriptRoot\DTSEndpointsPokerHelper.ps1

$_poker_table1 = Get-DTSEndpointHelperPokerTable -PokerBasePath $PokerBasePath -PokerTableId $PokerTableId -PokerTableName $PokerTableName -PokerTableSecret $PokerTableSecret

echo "bla"