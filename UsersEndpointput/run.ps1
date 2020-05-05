using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
function new-scimuser ($prop){
    $userobj=[pscustomobject]@{
        schemas=@('urn:ietf:params:scim:schemas:core:2.0:User')
        id=$prop.RowKey
    }
    foreach ($attr in $schemaAttributes.name.where{$_ -notin ('schemas','id')}){
        if ($prop.$attr){$userobj | add-member -notepropertyname $attr -notepropertyvalue $prop.$attr}
    }
    $timestampnow=(get-date).GetDateTimeFormats()[114].replace(' ','T')
    if ($prop.tabletimestamp){
        $timestamp=($prop.TableTimestamp).GetDateTimeFormats()[114].replace(' ','T')
    }else{
        $timestamp=$timestampnow
    }
    $meta=[pscustomobject]@{
        resourceType='User'
        created = $timestamp
        lastModified = $timestampnow
        location="https://$($Request.Headers.'disguised-host')/api/Users/$($prop.RowKey)"
    }
    $userobj | add-member -notepropertyname meta -notepropertyvalue $meta
    return $userobj
}
#if ($null -eq (Get-AzContext)){Connect-AzAccount -Identity}
Az.Storage\New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
$userid=$Request.Params.path
if ($Request.Body -ne $null -and $Request.Body.gettype().name -eq 'string'){
    $userjson=$Request.Body | convertfrom-json -depth 100
}else{
    $userjson=$Request.Body
}
if (-not $userid){
    $userid=$Request.Body.id
}
$storage=Get-AzStorageAccount -Name $tableconnection.accountname -ResourceGroupName $tableconnection.accountname
$table=Get-AzStorageTable -Context $storage.Context -Name 'User'
$tableuser=Get-AzTableRow -RowKey $userid -PartitionKey 'User' -Table $table.cloudtable
if ($tableuser){
    $schematable=Get-AzStorageTable -Context $storage.Context -Name 'SchemaAttributes'
    $schemaAttributes=Get-AzTableRow -Table $schematable.CloudTable
    $update=$false
    $myvalue=@{
        PartitionKey=$tableuser.PartitionKey
        RowKey=$tableuser.RowKey
    }
    foreach ($attr in $schemaAttributes.where{$_.PartitionKey -eq $myvalue.PartitionKey -and $_.mutability -eq 'readWrite'}.name){
        if ($userjson.$attr -and $tableuser.$attr -ne $userjson.$attr){$myvalue.$attr=$userjson.$attr;$update=$true; $attr}
    }
    if ($update){
        $restattributetable=Get-AzStorageTable -Context $storage.Context -Name 'restattributes'
        $restattributes=Get-AzTableRow -Table $restattributetable.CloudTable
        foreach ($attr in $restattributes){
            $restrequestbody=$attr.input | convertfrom-json
            foreach ($prop in ($restrequestbody.properties | gm).where{$_.MemberType -eq 'NoteProperty'}.name){
                $restrequestbody.properties.$prop=$myvalue.$prop
            }
            $restresult=Invoke-RestMethod -UseBasicParsing -Uri $attr.url -Method Post -Body ($restrequestbody.properties | convertto-json)
            $restoutput=$attr.output | convertfrom-json
            foreach ($prop in ($restoutput.properties | gm).where{$_.MemberType -eq 'NoteProperty'}.name){
                $myvalue.$prop=$restresult.$prop
            }
        }
        Add-AzTableRow -PartitionKey 'User' -RowKey $guid -Table $table.CloudTable -property $myvalue -UpdateExisting
    }
    $tableuser=Get-AzTableRow -RowKey $userid -PartitionKey 'User' -Table $table.cloudtable

    $body=new-scimuser $tableuser
}else{
    $body=[pscustomobject]@{
        schemas=@("urn:ietf:params:scim:api:messages:2.0:Error")
        detail="User not found"
        status=404
    }
}
$status = [HttpStatusCode]::OK
write-host ($status | convertto-json -depth 10) 
write-host ($Body | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $Body | convertto-json -depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})
