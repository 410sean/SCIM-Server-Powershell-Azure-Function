using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
$body=Test-BasicAuthCred -authorization ($request.Headers.Authorization)
if ($null -ne $body){
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = $body
        headers = @{"Content-Type"= "application/scim+json"}
    })
    $keepgoing=$false
}
<#GET for retrieval of resources; POST for creation,
searching, and bulk modification; PUT for attribute replacement
within resources; PATCH for partial update of attributes; and DELETE
for removing resources#>
# Write to the Azure Functions log stream.
$patchop=$request.body | convertfrom-json
$scimuser=get-scimuser -path $request.Params.path
foreach ($op in $patchop.Operations){
    switch ($op.op){
        add{$scimuser.(($op.value | gm -type noteproperty).name)=$op.value.(($op.value | gm -type noteproperty).name)}
    }
}
$timestamp=(get-date).ToUniversalTime().getdatetimeformats()[101]
$scimuser.meta=@{
    resourceType='User'
    created = $scimuser.meta.created
    lastModified = $timestamp
    location="https://$($Request.Headers.'disguised-host')/api/Users/$($scimuser.id)"
} | convertto-json

$storagecontext=New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
$table=Get-AzStorageTable -Context $storageContext -Name 'User'
$response=Add-AzTableRow -PartitionKey 'User' -RowKey $guid -Table $table.CloudTable -property $scimuser -UpdateExisting
$response=get-scimuser -path $request.Params.path

$status = [HttpStatusCode]::OK
#$response.meta.location="https://$($Request.Headers.'disguised-host')/api/ServiceProviderConfig"
if($response.schemas -contains 'urn:ietf:params:scim:api:messages:2.0:Error'){
    $status = get-HttpStatusCode -code ($response.status)
}else {
    $status = get-HttpStatusCode -code 200
}
write-host "status:$($status | convertto-json -depth 10)"
write-host "Response:$($response | convertto-json -depth 10)"
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $response | convertto-json -Depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})
