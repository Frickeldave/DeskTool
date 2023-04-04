# Get properties from input args
$PokerBasePath = "C:\ProgramData\Frickeldave\DTS\Endpoints\poker"

. $PSScriptRoot\DTSEndpointsHelperPoker.ps1

foreach($_poker_file in (Get-ChildItem -Path "$PokerBasePath" | Where-Object { $_.Name -like "*.json" } )) {
    echo "bla"

}