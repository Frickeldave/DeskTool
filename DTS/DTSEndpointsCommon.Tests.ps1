Describe 'Common API methods' {

    It 'Get status of the API' {
        $_api_status = Invoke-RestMethod -Method Get -Uri 'http://localhost:8082/api/v1/dts/status'
        $_api_status.status | Should Be 'OK'
    }
}