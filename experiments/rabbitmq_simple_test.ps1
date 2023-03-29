# Install-Module PSRabbitMq -Scope CurrentUser
# Import-Module PSRabbitMq -Force
Import-Module .\..\PSRabbitMq\PSRabbitMq\PSRabbitMq.psd1 -Scope Local
$_rbmq_password=ConvertTo-SecureString "rbmqadmin" -AsPlainText -Force
$_rbmq_credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "rbmqadmin", $_rbmq_password
Set-RabbitMQConfig -ComputerName 192.168.56.100

#Send a message
$_rbmq_message1 = [PSCustomObject]@{testname1='name1';testvalue1='value1'} | ConvertTo-Json
Send-RabbitMQMessage -Exchange "desktool_poker" -Key "Message1" -InputObject $_rbmq_message1 -Credential $_rbmq_credentials

# Receive a message
Wait-RabbitMQMessage -Exchange "desktool_poker" -Key "Message1" -QueueName "desktool_poker" -Timeout 20000 -Credential $_rbmq_credentials -Ssl None