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

$status = [HttpStatusCode]::OK
#get response code
$params=@{
    startindex=$request.query.startindex
    itemsPerPage=$request.query.count
    attributes=$request.query.attributes
    filter=$request.query.filter
    path=$request.Params.path
}
$response=get-scimUser @params

#set meta location scriptlet
if ($response.schemas -contains 'urn:ietf:params:scim:api:messages:2.0:ListResponse')
{
  foreach ($resource in $response.resources){
    write-host "setting '$($response.schemas)' meta location $("https://$($Request.Headers.'disguised-host')/api/Users/$($resource.name)")"
    $resource.meta.location="https://$($Request.Headers.'disguised-host')/api/Users/$($resource.name)"
  }
}else{
  write-host "setting '$($response.schemas)' meta location $("https://$($Request.Headers.'disguised-host')/api/Users/$($resource.name)")"
  $response.meta.location="https://$($Request.Headers.'disguised-host')/api/Users/$($response.name)" 
}

write-host ($status | convertto-json -depth 10) 
write-host ($psbody | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $response | convertto-json -Depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})
