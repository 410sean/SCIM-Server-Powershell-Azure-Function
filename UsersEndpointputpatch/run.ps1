using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $inputTable)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
if ((Test-BasicAuthCred -authorization ($request.Headers.Authorization)) -eq $false){
    write-host "failed basic auth"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = @{
            status='401'
            response=@{
                schemas= @("urn:ietf:params:scim:api:messages:2.0:Error")
                scimType="invalidValue"
                detail="$($env:basicauth) recieved $($request.Headers.authorization)"
                status='401'
            }
        }
        headers = @{"Content-Type"= "application/scim+json"}
    })
    $keepgoing=$false
}
<#GET for retrieval of resources; POST for creation,
searching, and bulk modification; PUT for attribute replacement
within resources; PATCH for partial update of attributes; and DELETE
for removing resources#>
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


$status = [HttpStatusCode]::OK
write-host ($status | convertto-json -depth 10) 
write-host ($Body | convertto-json -depth 10) 
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
    headers = @{"Content-Type"= "application/json"}
})
