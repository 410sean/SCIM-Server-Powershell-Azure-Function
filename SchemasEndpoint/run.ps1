using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$status = [HttpStatusCode]::OK
#get response code
if ($Request.params.path){
  $response=get-scimitem -schemaURI 'urn:ietf:params:scim:schemas:core:2.0:Schema' -path $Request.params.path
}else{
  $response=get-scimitem -schemaURI 'urn:ietf:params:scim:schemas:core:2.0:Schema'
} 

#set meta location scriptlet
if ($response.schemas -contains 'urn:ietf:params:scim:api:messages:2.0:ListResponse')
{
  foreach ($resource in $response.resources){
    write-host "setting '$($response.schemas)' meta location $("https://$($Request.Headers.'disguised-host')/api/schemas/$($resource.id)")"
    $resource.meta.location="https://$($Request.Headers.'disguised-host')/api/schemas/$($resource.id)"
  }
}elseif($response.schemas -contains 'urn:ietf:params:scim:api:messages:2.0:Error'){
  $status = [HttpStatusCode]::($response.status)
}else{
  write-host "setting '$($response.schemas)' meta location $("https://$($Request.Headers.'disguised-host')/api/schemas/$($resource.id)")"
  $response.meta.location="https://$($Request.Headers.'disguised-host')/api/schemas/$($response.id)" 
}

write-host ($status | convertto-json -depth 10) 
write-host ($psbody | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $response | convertto-json -Depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})
