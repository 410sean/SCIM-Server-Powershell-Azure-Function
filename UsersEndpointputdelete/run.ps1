using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $inputTable)
write-host ($request | convertto-json -depth 10) 
write-host ($TriggerMetadata | convertto-json -depth 10) 
if ((Test-BasicAuthCred -authorization ($request.autorization) -eq $false){
    write-host "failed basic auth"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = $null
    })
    break
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
