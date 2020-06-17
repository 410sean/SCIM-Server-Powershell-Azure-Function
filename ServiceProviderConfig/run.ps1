using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$status = [HttpStatusCode]::OK
$response=get-scimitem -schemaURI 'urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'
$response.meta.location="https://$($Request.Headers.'disguised-host')/api/ServiceProviderConfig"

write-host ($status | convertto-json -depth 10) 
write-host ($psbody | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $response | convertto-json -Depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})
