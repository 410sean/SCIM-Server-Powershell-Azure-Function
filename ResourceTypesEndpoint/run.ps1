using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$status=get-HttpStatusCode -code 200

#get response code
if ($Request.params.path){
  $response=get-scimitem -schemaURI 'urn:ietf:params:scim:schemas:core:2.0:ResourceType' -path $Request.params.path
}else{
  $response=get-scimitem -schemaURI 'urn:ietf:params:scim:schemas:core:2.0:ResourceType'
} 

#set meta location scriptlet
if ($response.schemas -contains 'urn:ietf:params:scim:api:messages:2.0:ListResponse')
{
  foreach ($resource in $response.resources){
    write-host "setting '$($response.schemas)' meta location $("https://$($Request.Headers.'disguised-host')/api/ResourceTypes/$($resource.id)")"
    $resource.meta.location="https://$($Request.Headers.'disguised-host')/api/ResourceTypes/$($resource.id)"
  }
}elseif($response.schemas -contains 'urn:ietf:params:scim:api:messages:2.0:Error'){
  $status = get-HttpStatusCode -code $response.status
}else{
  write-host "setting '$($response.schemas)' meta location $("https://$($Request.Headers.'disguised-host')/api/ResourceTypes/$($resource.id)")"
  $response.meta.location="https://$($Request.Headers.'disguised-host')/api/ResourceTypes/$($response.id)" 
}


write-host "status:$($status | convertto-json -depth 10)"
write-host "Response:$($response | convertto-json -depth 10)"
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $response | convertto-json -Depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})
