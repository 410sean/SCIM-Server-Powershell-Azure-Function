using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
$body=Test-BasicAuthCred -authorization ($request.Headers.Authorization)
if ($null -ne $body){
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = $body
        headers = @{"Content-Type"= "application/scim+json"}
    })
    $keepgoing=$false
}
$guid=$Request.Params.path
$tableuser=get-scimuser -path $guid
if ($Request.Body -ne $null -and $Request.Body.gettype().name -eq 'string'){
    $userjson=$Request.Body | convertfrom-json -depth 100
}else{
    $userjson=$Request.Body
}
$userid=$request.Params.path
if (-not $userid){
    $userid=$Request.Body.id
}
if ($tableuser){
    $schematable=Get-AzStorageTable -Context $storageContext -Name 'SchemaAttributes'
    $schemaAttributes=
    
    $myvalue=@{
        PartitionKey=$tableuser.PartitionKey
        RowKey=$tableuser.RowKey
    }
    foreach ($attr in $schemaAttributes.where{$_.PartitionKey -eq $myvalue.PartitionKey -and $_.mutability -eq 'readWrite'}.name){
        if ($userjson.$attr -and $tableuser.$attr -ne $userjson.$attr){$myvalue.$attr=$userjson.$attr;$update=$true; $attr}
    }
    if ($update){
        $restattributetable=Get-AzStorageTable -Context $storageContext -Name 'restattributes'
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
    $body=get-scimUser -path $userid
}else{
    $body=new-scimError -status 404 -detail "user not found"
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
