Install-Module PSRabbitMq -Scope CurrentUser
Import-Module PSRabbitMq -Force
$_rbmq_password=ConvertTo-SecureString "rbmqadmin" -AsPlainText -Force
$_rbmq_credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "rbmqadmin", $_rbmq_password
Set-RabbitMQConfig -ComputerName 172.16.20.86

#Send a message
$_rbmq_message1 = [PSCustomObject]@{testname1='name1';testvalue1='value1'} | ConvertTo-Json
Send-RabbitMQMessage -Exchange stream_chat -Key 'Message1' -InputObject $_rbmq_message1 -Credential $_rbmq_credentials -Ssl None

# Receive a message
Wait-RabbitMQMessage -Exchange "stream_chat" -Key "Message1" -QueueName "stream_chat" -Timeout 20000 -Credential $_rbmq_credentials -Ssl None