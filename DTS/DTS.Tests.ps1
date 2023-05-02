Describe 'General tests' {
        
    It 'Copy test files into target directory' {

        # Copy user testdata
        Copy-Item -Path "$PSScriptRoot\Testdata\User\*.json" -Destination "$_target_dir\data\db\user"

        "$env:ProgramData\Frickeldave\DTS-Test\data\db\user\5cd67325-258b-4a15-962d-1ff34f880d2a.json" | Should -Exist
        "$env:ProgramData\Frickeldave\DTS-Test\data\db\user\7f9e7dcd-86c8-492c-8d7a-adaaad24dd66.json" | Should -Exist
        "$env:ProgramData\Frickeldave\DTS-Test\data\db\user\9f050f96-17fe-4d10-96e0-e65f2f65d0ad.json" | Should -Exist
        "$env:ProgramData\Frickeldave\DTS-Test\data\db\user\80a69c0c-60a4-43b1-b249-26fc033ad6c6.json" | Should -Exist
    }
    It 'Get status of the API' {
        $_api_status = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/status'
        $_api_status.status | Should -Be 'OK'
    }
}