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
if ($request.Params.path -eq $null){
    $params=@{
        request=$request.body
    }
    $response=new-scimUser @params
}
#$response.meta.location="https://$($Request.Headers.'disguised-host')/api/ServiceProviderConfig"
if($response.schemas -contains 'urn:ietf:params:scim:api:messages:2.0:Error'){
    $status = [HttpStatusCode]::($response.status)
}
write-host ($status | convertto-json -depth 10) 
write-host ($psbody | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $response | convertto-json -Depth 10
    headers = @{"Content-Type"= "application/scim+json"}
})
