# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}
if (get-varindexNeeded -or  ($null -eq (get-varIndexTime)) -or ((get-varIndexTime) -lt (get-date).ToUniversalTime().AddMinutes(-15))){
    if (get-varindexRunning){continue}
    set-varindexRunning -value $true
    #get users to check index
    $storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
    $table=Get-AzStorageTable -Context $storageContext -Name 'User'
    $TableQuery = New-Object -TypeName "Microsoft.Azure.Cosmos.Table.TableQuery"
    $selectColumns=New-Object System.Collections.Generic.List[string]
    $selectColumns.add('index')
    $TableQuery.SelectColumns=$selectColumns
    $users=ExecuteQueryAsync -Table $table.CloudTable -TableQuery $TableQuery
    $users=$users.where{$_.RowKey -and $_.PartitionKey}

    #store total
    set-varuserCount -value $users.count

    #clear index over total in case deletes happened
    foreach ($person in $users.where{$_.Properties.index.Int32Value -gt $users.count}){
        $row=Get-AzTableRow -Table $table.CloudTable -RowKey $person.RowKey -PartitionKey $person.PartitionKey
        $row.index=$null
        $row | update-aztablerow -table $table.cloudtable
        $person.Properties.index.Int32Value=$null
    }

    #add index num to users missing it
    $unindexed=$users.where{$null -eq $_.Properties.index.Int32Value}
    $indexenums=$users.Properties.index.Int32Value | Sort-Object
    $k=0
    for ($i=1;$i -le $users.count; $i++){
        if ($i -notin $indexenums){
            $row=Get-AzTableRow -Table $table.CloudTable -RowKey $unindexed[$k].RowKey -PartitionKey $unindexed[$k].PartitionKey
            $row | Add-Member -NotePropertyName 'index' -NotePropertyValue $i
            $row | update-aztablerow -table $table.cloudtable
            $k++
        }
    }
    set-varindexNeeded -value $false
    set-varIndexTime -value (get-date).ToUniversalTime()
    set-varindexRunning -value $false
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
